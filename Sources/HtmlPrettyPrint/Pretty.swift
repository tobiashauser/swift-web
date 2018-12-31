import Html

public struct Config {
  public let indentation: String
  public let newline: String

  public init(indentation: String, newline: String) {
    self.indentation = indentation
    self.newline = newline
  }

  public static let pretty = Config(indentation: "  ", newline: "\n")
}

public func prettyPrint(_ nodes: [Node], config: Config = .pretty) -> String {
  return nodes
    .map { prettyPrint($0, config: config) }
    .joined()
}

public func prettyPrint(_ node: Node, config: Config = .pretty) -> String {
  func prettyPrintHelp(_ node: Node, config: Config, indentation: String) -> String {
    func renderValues(_ values: String, separator: Character?, indentBy: Int) -> String {
      guard let separator = separator else { return values }
      return values
        .split(separator: separator)
        .joined(separator: (separator == " " ? "" : String(separator)) + config.newline + String(repeating: " ", count: indentBy + 1))
    }

    func separator(forKey key: String) -> Character? {
      switch key {
      case "class":
        return " "
      case "style":
        return ";"
      default:
        return nil
      }
    }

    switch node {
    case let .comment(string):
      return indentation + "<!-- " + string + " -->" + config.newline
    case let .doctype(string):
      return indentation + "<!DOCTYPE " + string + ">" + config.newline
    case let .element(tag, attrs, .fragment(children)):
      let renderedAttrs = attrs
        .compactMap { k, v -> String? in
          let indentBy = indentation.count + tag.count + k.count + 3
          return v.map {
            $0.isEmpty ? " \(k)" : " \(k)=\"\(renderValues($0, separator: separator(forKey: k), indentBy: indentBy))\""
          }
        }
        .joined(separator: config.newline + indentation + String(repeating: " ", count: tag.count + 1))
      guard !children.isEmpty || !voidElements.contains(tag) else {
        return indentation + "<" + tag + renderedAttrs + ">" + config.newline
      }
      return indentation + "<" + tag + renderedAttrs + ">" + config.newline
        + children.map { prettyPrintHelp($0, config: config, indentation: indentation + config.indentation) }.joined()
        + indentation + "</" + tag + ">" + config.newline
    case let .element(tag, attrs, children):
      return prettyPrintHelp(.element(tag, attrs, .fragment([children])), config: config, indentation: indentation)
    case let .fragment(children):
      return children.map { prettyPrintHelp($0, config: config, indentation: indentation + config.indentation) }.joined()
    case let .raw(string):
      return indentation + string + config.newline
    case let .text(string):
      return indentation + string + config.newline
    }
  }

  return prettyPrintHelp(node, config: config, indentation: "")
}
