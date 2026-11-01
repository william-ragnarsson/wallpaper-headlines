import SwiftUI

// Categories: the provider's sections that are not on the wallpaper, to add:
// + puts one at the end of the row, to drag to its place from there.
struct OtherSections: View {
  let digest: SourcesDigest
  @Binding var sections: [String]

  var body: some View {
    Section {
      if digest.others.isEmpty {
        Text("All of \(digest.provider?.name ?? "the provider")’s sections are on the wallpaper.")
          .foregroundStyle(.secondary)
      }
      ForEach(digest.others) { section in
        SectionRow(section: section, handle: false) {
          Button("Add \(section.name)", systemImage: "plus.circle") { add(section.id) }
            .help("Add \(section.name) at the end of the wallpaper’s row")
        }
        .contextMenu {
          Button("Add to Wallpaper") { add(section.id) }
        }
      }
    } header: {
      Text("Categories")
    } footer: {
      Text("+ adds one at the end of the wallpaper’s row; drag it up to its place from there.")
    }
  }

  private func add(_ id: String) {
    guard let next = digest.adding(id) else { return }
    withAnimation(.snappy) { sections = next }
  }
}
