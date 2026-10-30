import Foundation
import NewsStore
import WallpaperCore

// What the Sources pane shows, worked out in one place from what there is to
// pick from (Options, with the headlines of the stored news), the settings,
// the stored news and what the preview's page did with the picked sections:
// the provider's sections on the wallpaper in their order, which of them fit,
// and the others, each with its latest stories, and the running live stories
// in the order they lead the front page. The views only lay it out, and
// change the orders through the helpers at the end.
public struct SourcesDigest: Sendable {
  public struct Section: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let group: String
    public let items: Int?  // in the news fetched last
    public let stories: [Story]  // its first few, in its feed's order
    // Whether it is on the wallpaper (picked ones only); nil when there is
    // no picture to tell by.
    public var showing: Showing?
  }

  public enum Showing: Sendable {
    case shown
    case empty  // nothing left to show: no stories, or all of them higher up the page
    case noRoom  // after the last place the design has
  }

  public struct Story: Identifiable, Sendable {
    public let id: String  // its url
    public let key: String  // what liveOrder keeps a live story by
    public let title: String
    public let time: Date?
  }

  // The stored news, for the picked provider.
  public enum News: Sendable {
    case current(StoreMeta)
    case otherProvider(String)  // another's, by name: the picture shows it until the picked one's is fetched
    case none  // nothing fetched yet
  }

  public let providers: [Options.Provider]
  public let provider: Options.Provider?
  public let design: Options.Design?
  public let liveFirst: Bool
  public let liveOrder: [String]
  public let liveLeads: Int
  public let maxLiveLeads: Int
  // The ids on the wallpaper in order, as the settings have them.
  public let order: [String]
  public let picked: [Section]
  public let others: [Section]
  // The first picked section with no room on the wallpaper, which the line
  // goes above; nil when all fit or there is no picture to tell by.
  public let firstLeftOut: String?
  // How many places for sections the design had in the preview; nil for no
  // cap, or no picture to tell by.
  public let room: Int?
  // In the order they lead the front page: those in liveOrder, then the
  // others newest first. nil when the stored news is not the picked
  // provider's, so there is nothing to tell.
  public let live: [Story]?
  public let news: News
  // The names of the designs that show the front page (and so follow
  // liveFirst), and of those that show the sections.
  public let frontDesigns: [String]
  public let sectionDesigns: [String]

  // `report`: what the preview's page did with the picked sections, for the
  // settings or ones a moment before; nil when there is none.
  public init(options: Options, settings: WallpaperSettings, news meta: StoreMeta?, report: SectionsReport? = nil) {
    let provider = options.providers.first { $0.id == settings.provider }
    // The stored news only when it is the picked provider's: after a switch
    // it is the one before's until the new one's fetch is stored.
    let current = meta.flatMap { $0.provider == settings.provider ? $0 : nil }
    let headlines = options.headlines.flatMap { current != nil && $0.provider == settings.provider ? $0 : nil }
    let section = { (s: Options.Section) in
      Section(id: s.id, name: s.name, group: s.group, items: current?.counts.items[s.id],
        stories: (headlines?.sections[s.id] ?? []).compactMap(Self.story))
    }
    let sections = provider?.sections ?? []
    self.providers = options.providers
    self.provider = provider
    design = options.presets.first { $0.id == settings.preset }
    liveFirst = settings.liveFirst
    liveOrder = settings.liveOrder
    liveLeads = settings.liveLeads
    maxLiveLeads = options.maxLiveLeads
    order = settings.sections
    var picked = settings.sections.compactMap { id in sections.first { $0.id == id } }.map(section)
    // The page passes over the ones with nothing left to show and fills its
    // places with the others in order. As the order changes, the picture
    // follows a moment later; the line moves at once.
    let report = design?.sections == true ? report : nil
    if let report {
      var left = report.room ?? .max
      for i in picked.indices {
        if report.empty.contains(picked[i].id) {
          picked[i].showing = .empty
        } else if left > 0 {
          picked[i].showing = .shown
          left -= 1
        } else {
          picked[i].showing = .noRoom
        }
      }
    }
    self.picked = picked
    firstLeftOut = picked.first { $0.showing == .noRoom }?.id
    room = report?.room
    others = sections.filter { !settings.sections.contains($0.id) }.map(section)
    live = headlines.map { headlines in
      let place = { (s: Story) in settings.liveOrder.firstIndex(of: s.key) ?? settings.liveOrder.count }
      return headlines.live.compactMap(Self.story).enumerated()
        .sorted { (place($0.element), $0.offset) < (place($1.element), $1.offset) }
        .map(\.element)
    }
    if let current {
      news = .current(current)
    } else if let meta {
      news = .otherProvider(options.providers.first { $0.id == meta.provider }?.name ?? meta.provider)
    } else {
      news = .none
    }
    frontDesigns = options.presets.filter { $0.data == "front" }.map(\.name)
    sectionDesigns = options.presets.filter { $0.sections == true }.map(\.name)
  }

  public var showsFront: Bool { design?.data == "front" }
  public var showsSections: Bool { design?.sections == true }

  // How many of the running live stories lead the front page: the line in
  // their list goes under that many. nil when they do not lead it, or there
  // is no list.
  public var liveLeading: Int? {
    guard liveFirst, showsFront, let live else { return nil }
    return min(liveLeads, live.count)
  }

  private static func story(_ s: Options.Story) -> Story? {
    guard let title = s.title, !title.isEmpty else { return nil }
    return Story(id: s.url, key: s.key ?? s.url, title: title, time: s.time.map { Date(timeIntervalSince1970: $0 / 1000) })
  }

  // MARK: Order

  // The order with the picked section `id` at `index` among the picked ones;
  // nil when it is there already. Ids in the order that are none of the
  // provider's sections stay where they are.
  public func moving(_ id: String, to index: Int) -> [String]? {
    var ids = picked.map(\.id)
    guard let from = ids.firstIndex(of: id), from != index, ids.indices.contains(index) else { return nil }
    ids.insert(ids.remove(at: from), at: index)
    let shown = Set(ids)
    var reordered = ids.makeIterator()
    return order.map { shown.contains($0) ? reordered.next() ?? $0 : $0 }
  }

  // Where the line goes among the picked sections in the order `ids`: above
  // the first that has no room once the design's places are filled, as the
  // page passes over the ones with nothing left to show. nil when all fit,
  // or there is no picture to tell by. With the order as it is, it is above
  // firstLeftOut; the views work out where it would go as one is dragged.
  public func lineIndex(in ids: [String]) -> Int? {
    guard var left = room else { return nil }
    let empty = Set(picked.filter { $0.showing == .empty }.map(\.id))
    for (index, id) in ids.enumerated() where !empty.contains(id) {
      if left == 0 { return index }
      left -= 1
    }
    return nil
  }

  // The order with `id` at the end; nil when it is on already, or none of
  // the provider's sections.
  public func adding(_ id: String) -> [String]? {
    guard !order.contains(id), provider?.sections.contains(where: { $0.id == id }) == true else { return nil }
    return order + [id]
  }

  // The order with `id` `offset` places up (-1) or down (1); nil at the ends.
  public func moving(_ id: String, by offset: Int) -> [String]? {
    guard let index = order.firstIndex(of: id), order.indices.contains(index + offset) else { return nil }
    var next = order
    next.swapAt(index, index + offset)
    return next
  }

  public func removing(_ id: String) -> [String]? {
    order.contains(id) ? order.filter { $0 != id } : nil
  }

  // liveOrder with the live story `key` at `index`; nil when nothing changes.
  public func liveMoving(_ key: String, to index: Int) -> [String]? {
    guard var keys = live?.map(\.key), let from = keys.firstIndex(of: key), keys.indices.contains(index) else { return nil }
    keys.insert(keys.remove(at: from), at: index)
    return sticking(keys, moved: key)
  }

  // The live story `key` `offset` places up (-1) or down (1); nil at the ends.
  public func liveMoving(_ key: String, by offset: Int) -> [String]? {
    guard var keys = live?.map(\.key), let index = keys.firstIndex(of: key), keys.indices.contains(index + offset) else { return nil }
    keys.swapAt(index, index + offset)
    return sticking(keys, moved: key)
  }

  // liveOrder for the live stories in the order `keys`, the one `moved` by
  // hand; nil when it is liveOrder. What sticks is the order down to the
  // lowest one moved by hand, this one or one before: below it the others
  // keep coming newest first, and a new one comes in there. Keys of stories
  // no longer running drop out.
  private func sticking(_ keys: [String], moved key: String) -> [String]? {
    let moved = Set(liveOrder).union([key])
    guard let last = keys.lastIndex(where: moved.contains) else { return nil }
    let next = Array(keys[...last])
    return next == liveOrder ? nil : next
  }
}
