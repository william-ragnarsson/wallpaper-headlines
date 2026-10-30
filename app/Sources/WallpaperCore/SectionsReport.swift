// What a page that shows sections did with the picked ones, as drawn, for
// Customize: `shown`, those on the picture, in page order; `empty`, those
// with nothing left to show (no stories, or all of them taken higher up the
// page); `room`, how many places for sections the design had: as many as it
// shows when one with stories was left out, else the most it planned for (nil
// for no cap). A picked section in neither list was left out for room.
// The Renderer reads it off the page (Snapshot.sections).
public struct SectionsReport: Sendable, Equatable {
  public let shown: [String]
  public let empty: [String]
  public let room: Int?

  public init(shown: [String], empty: [String], room: Int?) {
    self.shown = shown
    self.empty = empty
    self.room = room
  }
}
