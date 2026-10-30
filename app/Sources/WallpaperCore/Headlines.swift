import Foundation

extension Options {
  // What the stored news holds for the Sources pane: getHeadlines in
  // sources/frontpage.mjs, for the provider in the settings. nil in Options
  // when the stored news is another provider's, or there is none.
  public struct Headlines: Codable, Sendable {
    public let provider: String
    // The running live stories, newest first; liveFirst leads the front page
    // with those in liveOrder first (SourcesDigest orders them so).
    public let live: [Story]
    // By section id: its first few stories, in its feed's order.
    public let sections: [String: [Story]]
  }

  // A Story of the front page payload (sources/README.md), with only what
  // Customize shows of it.
  public struct Story: Codable, Identifiable, Sendable {
    public let url: String
    // What liveOrder keeps it by: a VRT NWS liveblog's stream id (its URL
    // follows its headline), else the URL. Live stories only.
    public let key: String?
    public let title: String?
    public let time: Double?  // ms since 1970: a liveblog's latest post, else when it was published
    public let live: Bool?

    public var id: String { url }
  }
}
