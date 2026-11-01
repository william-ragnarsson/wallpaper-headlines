import CustomizeUI
import SwiftUI
import WallpaperCore

// Where the news comes from (M5): SourcesForm (CustomizeUI) with what the app
// fetched last, what the preview's page did with the picked sections, and the
// settings in the window, each change saved at once. The preview is drawn
// here too, unseen, so the pane can tell which sections fit.
struct SourcesPane: View {
  let model: Customization
  let settings: WallpaperSettings
  let options: Options

  var body: some View {
    SourcesForm(
      digest: SourcesDigest(options: options, settings: settings, news: model.news, report: model.sectionsReport),
      provider: model.binding(settings, \.provider),
      liveFirst: model.binding(settings, \.liveFirst),
      liveOrder: model.binding(settings, \.liveOrder),
      liveLeads: model.binding(settings, \.liveLeads),
      sections: model.binding(settings, \.sections))
    .task(id: model.previewKey(settings)) {
      // Changes come a few in a row (a stepper, one drag after another):
      // draw after a pause.
      try? await Task.sleep(for: .milliseconds(500))
      guard !Task.isCancelled else { return }
      await model.drawPreview()
    }
  }
}
