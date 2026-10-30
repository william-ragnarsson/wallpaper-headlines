import SwiftUI

// Whether running live stories (liveblogs, live pages) lead the front page.
struct LiveFirstSection: View {
  let digest: SourcesDigest
  @Binding var liveFirst: Bool

  var body: some View {
    Section {
      Toggle(isOn: $liveFirst) {
        Text("Lead with live stories")
        Text("Running live stories go to the top of the front page, before \(digest.provider?.name ?? "the provider")’s own order.")
      }
      .disabled(!digest.showsFront)
    } footer: {
      if !digest.showsFront {
        Text("For \(digest.frontDesigns.formatted(.list(type: .and))) only.")
      }
    }
  }
}

// The running live stories in the order they lead the front page, and the
// line under the last that does: drag one up to put it first, and drag the
// line (or step it) to lead with more or fewer. One dragged over the line
// sends the nearest on the other side back over it, so as many lead. Only
// the order down to the lowest story moved by hand is kept (liveOrder); a
// story that ends drops out of it.
struct LiveSection: View {
  let digest: SourcesDigest
  @Binding var liveOrder: [String]
  @Binding var liveLeads: Int

  var body: some View {
    Section {
      if let live = digest.live {
        if live.isEmpty {
          Text("None running now.").foregroundStyle(.secondary)
        } else {
          ReorderStack(ids: rows(live.map(\.key), leading: leading), places: { places($0, in: live) }, ruled: { $0 != .line }) { row in
            switch row {
            case .line:
              Cutoff(text: live.count < liveLeads ? "Lead with up to \(liveLeads)" : "Lead with \(liveLeads)", handle: true) {
                Stepper("Live stories that lead", value: $liveLeads, in: 1...max(1, digest.maxLiveLeads))
                  .labelsHidden()
                  .controlSize(.small)
              }
            case .story(let key):
              if let index = live.firstIndex(where: { $0.key == key }) {
                LiveRow(story: live[index], place: leading.flatMap { index < $0 ? Self.place(index) : nil }, leads: leading.map { index < $0 } ?? true)
                  .contextMenu {
                    Button("Move Up") { set(digest.liveMoving(key, by: -1)) }
                      .disabled(index == 0)
                    Button("Move Down") { set(digest.liveMoving(key, by: 1)) }
                      .disabled(index == live.count - 1)
                    Divider()
                    Button("Use Newest First") { set([]) }
                      .disabled(liveOrder.isEmpty)
                  }
              }
            }
          }
          .disabled(leading == nil)
          .opacity(leading == nil ? 0.5 : 1)
        }
      } else if case .current = digest.news {
        Text("None in the news fetched last.").foregroundStyle(.secondary)
      } else {
        Text("The running live stories show here once \(digest.provider?.name ?? "the provider")’s news is fetched.").foregroundStyle(.secondary)
      }
    } header: {
      Text("Live now")
    } footer: {
      if leading != nil {
        Text("Drag a story to move it, and the line to lead with more or fewer. A story dragged over the line sends the nearest one on the other side back across, so as many lead. Your order sticks to a story while it runs: new ones come in below the ones you moved, newest first, and one that ends drops off. The ones under the line stay where \(digest.provider?.name ?? "the provider") has them. A story counts as running while it is marked live and was updated in the last 12 hours.")
      }
    }
  }

  // How many lead the front page; nil when they do not lead it, so their
  // order is for nothing now.
  private var leading: Int? { digest.liveLeading }

  private enum Row: Hashable {
    case story(String)  // by key
    case line
  }

  // The stories in the order `keys`, with the line under the first `leading`.
  private func rows(_ keys: [String], leading: Int?) -> [Row] {
    var rows = keys.map(Row.story)
    if let leading { rows.insert(.line, at: leading) }
    return rows
  }

  // Where a row can be dragged to, while the stories lead: a story to any
  // place, the line staying under as many, so one taken over it sends the
  // nearest on the other side back across; the line under any number of
  // them, to lead with that many.
  private func places(_ row: Row, in live: [SourcesDigest.Story]) -> [Place<Row>] {
    guard let leading else { return [] }
    let keys = live.map(\.key)
    switch row {
    case .story(let key):
      let others = keys.filter { $0 != key }
      return keys.indices.map { index in
        var next = others
        next.insert(key, at: index)
        return Place(ids: rows(next, leading: leading)) {
          if let next = digest.liveMoving(key, to: index) { liveOrder = next }
        }
      }
    case .line:
      return (1...max(1, min(digest.maxLiveLeads, keys.count))).map { leads in
        Place(ids: rows(keys, leading: leads)) { liveLeads = leads }
      }
    }
  }

  private func set(_ next: [String]?) {
    guard let next, next != liveOrder else { return }
    withAnimation(.snappy) { liveOrder = next }
  }

  private static func place(_ index: Int) -> String {
    guard index > 0 else { return "Lead story" }
    let ordinal = NumberFormatter()
    ordinal.numberStyle = .ordinal
    return "\(ordinal.string(from: index + 1 as NSNumber) ?? "\(index + 1)") story"
  }
}

// A running live story: where it leads the front page (nil: it does not),
// and when it was updated. One under the line is dimmed (`leads` false).
private struct LiveRow: View {
  let story: SourcesDigest.Story
  let place: String?
  let leads: Bool

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Handle()
      LiveBadge()
      VStack(alignment: .leading, spacing: 2) {
        Text(story.title).lineLimit(2)
        let detail = [place, story.time.map { "updated \(Relative.text($0))" }].compactMap { $0 }
        if !detail.isEmpty {
          Text(detail.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 2)
    .opacity(leads ? 1 : 0.5)
  }
}

// LIVE, as the front page marks a running story.
struct LiveBadge: View {
  var body: some View {
    Text("LIVE")
      .font(.caption2.weight(.bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 5)
      .padding(.vertical, 1)
      .background(.red, in: RoundedRectangle(cornerRadius: 3))
      .accessibilityLabel("Live")
  }
}

// "12 min. ago": when a story was published or last updated.
enum Relative {
  static func text(_ date: Date) -> String {
    date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
  }
}
