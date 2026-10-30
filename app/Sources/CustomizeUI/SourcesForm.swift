import SwiftUI
import WallpaperCore

// Customize → Sources (M5): what news the wallpaper has. The provider it
// comes from; its sections on the wallpaper in the order of the row below the
// lead stories, and where the design runs out of room for them; whether the
// running live stories lead the front page, and which of them first; and the
// sections there are to add. All of it is the digest's, from the stored news
// and the preview's picture; nothing here goes to the network. Each binding
// saves the setting it is for: a drag saves the order as the rows make way,
// so the drop finds it saved. A row drags within its list only.
public struct SourcesForm: View {
  let digest: SourcesDigest
  @Binding var provider: String
  @Binding var liveFirst: Bool
  @Binding var liveOrder: [String]
  @Binding var liveLeads: Int
  @Binding var sections: [String]

  public init(digest: SourcesDigest, provider: Binding<String>, liveFirst: Binding<Bool>, liveOrder: Binding<[String]>,
              liveLeads: Binding<Int>, sections: Binding<[String]>) {
    self.digest = digest
    _provider = provider
    _liveFirst = liveFirst
    _liveOrder = liveOrder
    _liveLeads = liveLeads
    _sections = sections
  }

  public var body: some View {
    Form {
      ProviderSection(digest: digest, provider: $provider)
      if digest.provider != nil {
        PickedSections(digest: digest, sections: $sections)
      }
      LiveFirstSection(digest: digest, liveFirst: $liveFirst)
      LiveSection(digest: digest, liveOrder: $liveOrder, liveLeads: $liveLeads)
      if digest.provider != nil {
        OtherSections(digest: digest, sections: $sections)
      }
    }
    .formStyle(.grouped)
  }
}
