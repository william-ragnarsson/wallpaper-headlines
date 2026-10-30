import SwiftUI

// What shows on the wallpaper: the picked sections in the order of the row
// below the lead stories, and the line where the design runs out of room for
// them on this screen, by the preview's picture. Drag one to move it, the
// rows making way as it goes; one dragged over the line sends the nearest on
// the other side back over it, as the design has room for as many as
// before. − takes one off; Categories below has the ones to add.
struct PickedSections: View {
  let digest: SourcesDigest
  @Binding var sections: [String]

  var body: some View {
    Section {
      if digest.picked.isEmpty {
        Text(digest.showsSections ? "None: the row below the lead stories fills with other news." : "None.")
          .foregroundStyle(.secondary)
      } else {
        ReorderStack(ids: rows(digest.picked.map(\.id)), places: places, ruled: { $0 != .line }) { row in
          switch row {
          case .line:
            Cutoff(text: "No room on \(digest.design?.name ?? "this design") for the ones below", systemImage: "eye.slash")
          case .section(let id):
            if let index = digest.picked.firstIndex(where: { $0.id == id }) {
              let section = digest.picked[index]
              SectionRow(section: section, place: index + 1) {
                Button("Remove \(section.name)", systemImage: "minus.circle") { set(digest.removing(id)) }
                  .help("Take \(section.name) off the wallpaper")
              }
              .contextMenu {
                Button("Move Up") { set(digest.moving(id, by: -1)) }
                  .disabled(index == 0)
                Button("Move Down") { set(digest.moving(id, by: 1)) }
                  .disabled(index == digest.picked.count - 1)
                Divider()
                Button("Remove from Wallpaper") { set(digest.removing(id)) }
              }
            }
          }
        }
      }
    } header: {
      Text("What shows on the wallpaper")
    } footer: {
      Text(footer)
    }
  }

  private enum Row: Hashable {
    case section(String)  // by id
    case line
  }

  // The sections in the order `ids`, with the line above the first left out.
  private func rows(_ ids: [String]) -> [Row] {
    var rows = ids.map(Row.section)
    if let line = digest.lineIndex(in: ids) { rows.insert(.line, at: line) }
    return rows
  }

  // Where a section can be dragged to: any place, the line staying under as
  // many as the design has room for, so one taken over it sends the nearest
  // on the other side back across.
  private func places(_ row: Row) -> [Place<Row>] {
    guard case .section(let id) = row else { return [] }
    let ids = digest.picked.map(\.id)
    let others = ids.filter { $0 != id }
    return ids.indices.map { index in
      var next = others
      next.insert(id, at: index)
      return Place(ids: rows(next)) {
        if let next = digest.moving(id, to: index) { sections = next }
      }
    }
  }

  private var footer: String {
    let design = digest.design?.name ?? "This design"
    guard digest.showsSections else {
      return "\(design) does not show sections. \(digest.sectionDesigns.formatted(.list(type: .and))) do."
    }
    var text = "Left to right in the row below the lead stories. Drag to reorder; − takes one off."
    if let room = digest.room {
      text += " \(design) has room for \(room) on this screen"
      text += digest.firstLeftOut == nil ? "." : ": the line marks where it runs out."
    }
    return text
  }

  private func set(_ next: [String]?) {
    guard let next else { return }
    withAnimation(.snappy) { sections = next }
  }
}
