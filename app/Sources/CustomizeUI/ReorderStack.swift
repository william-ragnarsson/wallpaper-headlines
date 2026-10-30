import Combine
import SwiftUI

// Rows that drag up and down. The one dragged lifts and follows the pointer,
// up and down only, and the others slide out of its way as it goes past the
// middle of one; let go, it settles into its place. Where it goes is the
// place it would sit nearest to where it is, worked out from the rows'
// heights alone, so it does not flick back and forth on the way. The order
// changes as the rows make way (that place `go`es), so the drop finds it
// saved. A row with no places (a line) does not drag, but makes way all the
// same. The rows of a Form are cells that one cannot be lifted over, so these
// are one row of it, ruled between as a Form rules its rows.
struct ReorderStack<ID: Hashable, Row: View>: View {
  // The rows in order, as the model has them now.
  let ids: [ID]
  // The orders the row `id` can be dragged to; none for one that does not drag.
  let places: (ID) -> [Place<ID>]
  // Whether a row has rules: one goes between two that have.
  let ruled: (ID) -> Bool
  let row: (ID) -> Row
  @StateObject private var lift = Lift<ID>()

  init(ids: [ID], places: @escaping (ID) -> [Place<ID>], ruled: @escaping (ID) -> Bool = { _ in true },
       @ViewBuilder row: @escaping (ID) -> Row) {
    self.ids = ids
    self.places = places
    self.ruled = ruled
    self.row = row
  }

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(ids.enumerated()), id: \.element) { index, id in
        cell(id)
          .overlay(alignment: .top) {
            if index > 0, ruled(id), ruled(ids[index - 1]) { Divider() }
          }
          .contentShape(Rectangle())
          .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { lift.heights[id] = $0 }
          .opacity(lift.id == id ? 0 : 1)
      }
    }
    .overlay(alignment: .top) {
      if let id = lift.id, ids.contains(id) {
        cell(id)
          .background { Card().padding(.horizontal, -6) }
          .offset(y: lift.top)
          .allowsHitTesting(false)
      }
    }
    // On the stack, not the rows: the one lifted hides, and they all move.
    .gesture(DragGesture(minimumDistance: 3).onChanged(drag).onEnded { _ in drop() })
    .padding(.vertical, -gap)
  }

  private func cell(_ id: ID) -> some View {
    row(id)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, gap)
  }

  // As a drag starts, the row it starts on lifts; then it follows the
  // pointer, kept within the stack, and the order goes to the place nearest.
  private func drag(_ value: DragGesture.Value) {
    // A drag that is cancelled does not end, so a new one is told by where it starts.
    if lift.origin != value.startLocation {
      lift.origin = value.startLocation
      lift.dragging = false
      guard let id = id(at: value.startLocation.y), !places(id).isEmpty else { return }
      lift.dragging = true
      lift.id = id
      lift.start = top(of: id, in: ids)
    }
    guard lift.dragging, let id = lift.id, ids.contains(id) else { return }
    lift.top = min(max(lift.start + value.translation.height, 0), max(0, total - (lift.heights[id] ?? 0)))
    let distance = { (order: [ID]) in abs(top(of: id, in: order) - lift.top) }
    guard let nearest = places(id).min(by: { distance($0.ids) < distance($1.ids) }),
          nearest.ids != ids, distance(nearest.ids) < distance(ids) else { return }
    withAnimation(.snappy) { nearest.go() }
  }

  // Let go, the row settles into its place, then is one of the others again.
  private func drop() {
    let lift = lift
    lift.origin = nil
    guard lift.dragging, let id = lift.id else { return }
    lift.dragging = false
    withAnimation(.snappy) {
      lift.top = top(of: id, in: ids)
    } completion: {
      // Unless another drag has lifted one since.
      guard !lift.dragging, lift.id == id else { return }
      lift.id = nil
    }
  }

  // Where the top of `id` is with the rows in `order`.
  private func top(of id: ID, in order: [ID]) -> CGFloat {
    order.prefix { $0 != id }.reduce(0) { $0 + (lift.heights[$1] ?? 0) }
  }

  private var total: CGFloat {
    ids.reduce(0) { $0 + (lift.heights[$1] ?? 0) }
  }

  private func id(at y: CGFloat) -> ID? {
    var bottom: CGFloat = 0
    return ids.first { id in
      bottom += lift.heights[id] ?? 0
      return y < bottom
    }
  }
}

// What the row lifted lies on: raised off the form, so lighter in the dark,
// with a hairline edge and a shadow.
private struct Card: View {
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
    shape.fill(.background)
      .overlay { shape.fill(.white.opacity(scheme == .dark ? 0.08 : 0)) }
      .overlay { shape.strokeBorder(.primary.opacity(scheme == .dark ? 0.16 : 0.1), lineWidth: 0.5) }
      .shadow(color: .black.opacity(scheme == .dark ? 0.5 : 0.18), radius: 8, y: 3)
  }
}

// An order a row can be dragged to: the rows in it, and what putting the row
// there does (sets the setting it is for).
struct Place<ID: Hashable> {
  let ids: [ID]
  let go: () -> Void
}

// What is lifted, and where: a StateObject, as @State's macro plugin does not
// come with the Command Line Tools. Only `id` and `top` redraw the stack.
final class Lift<ID: Hashable>: ObservableObject {
  @Published var id: ID?  // the row lifted, while it is dragged and as it settles
  @Published var top: CGFloat = 0  // where its top is in the stack
  var start: CGFloat = 0  // where its top was as the drag started
  var origin: CGPoint?  // where the drag started
  var dragging = false
  var heights: [ID: CGFloat] = [:]
}

// The space above and below a row's content, as a Form leaves it.
private let gap: CGFloat = 6
