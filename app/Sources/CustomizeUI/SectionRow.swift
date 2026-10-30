import SwiftUI

// One of the provider's sections: its place on the wallpaper (when it is
// picked), its name and group, and its latest few headlines; with `handle`, a
// sign it can be dragged, and a button (`accessory`) to take it off or add
// it. A picked one that is not on the wallpaper is dimmed, and one with
// nothing left to show says so.
struct SectionRow<Accessory: View>: View {
  let section: SourcesDigest.Section
  var place: Int?
  var handle = true
  @ViewBuilder let accessory: Accessory

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      if handle { Handle() }
      if let place {
        Text("\(place)")
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .frame(minWidth: 14, alignment: .trailing)
          .opacity(dim)
      }
      VStack(alignment: .leading, spacing: 3) {
        HStack(alignment: .firstTextBaseline) {
          Text(section.name).fontWeight(.medium)
          Text(section.group).font(.caption).foregroundStyle(.secondary)
        }
        .opacity(dim)
        if section.showing == .empty {
          Group {
            if section.stories.isEmpty {
              Label("Not on the wallpaper: nothing in it right now", systemImage: "tray")
            } else {
              Label("Not on the wallpaper: its newest stories are already higher up", systemImage: "arrow.up")
            }
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
        ForEach(section.stories) { story in
          HStack(alignment: .firstTextBaseline) {
            Text(story.title).lineLimit(1).truncationMode(.tail)
            Spacer(minLength: 8)
            if let time = story.time {
              Text(Relative.text(time)).foregroundStyle(.tertiary)
            }
          }
          .font(.callout)
          .foregroundStyle(.secondary)
          .opacity(dim)
        }
      }
      Spacer(minLength: 0)
      accessory
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }
    .padding(.vertical, 2)
    .contentShape(Rectangle())
  }

  private var dim: Double {
    switch section.showing {
    case .empty?, .noRoom?: 0.45
    case .shown?, nil: 1
    }
  }
}

// The sign that a row can be dragged.
struct Handle: View {
  var body: some View {
    Image(systemName: "line.3.horizontal")
      .foregroundStyle(.tertiary)
      .help("Drag to move")
  }
}

// The line under the last row that makes it, with what it means, and a
// control to move it (`accessory`); with `handle`, it can be dragged.
struct Cutoff<Accessory: View>: View {
  let text: String
  var systemImage: String?
  var handle = false
  @ViewBuilder let accessory: Accessory

  var body: some View {
    HStack(spacing: 8) {
      if handle { Handle() }
      if let systemImage { Image(systemName: systemImage) }
      Text(text)
      Rectangle().frame(height: 1).opacity(0.35)
      accessory
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}

extension Cutoff where Accessory == EmptyView {
  init(text: String, systemImage: String? = nil) {
    self.init(text: text, systemImage: systemImage) { EmptyView() }
  }
}
