import Foundation
import JavaScriptCore

final class ScriptRuntime {
    var document: HTMLNode?

    private let context = JSContext()!
    private var handleToPath: [Int: NodePath] = [:]
    private var pathToHandle: [NodePath: Int] = [:]
    private var nextHandle = 0

    init(document: HTMLNode?) {
        self.document = document
        context.exceptionHandler = { _, exception in
            fputs("Script error: \(exception?.toString() ?? "unknown")\n", stderr)
        }
        installNativeFunctions()
        context.evaluateScript(Self.runtimeJS)
    }

    func run(_ source: String) {
        context.evaluateScript(source)
    }

    func dispatchEvent(type: String, at path: NodePath) -> Bool {
        let handle = handle(for: path)
        let dispatch = "new Node(\(handle)).dispatchEvent(new Event(\(jsStringLiteral(type))))"
        return context.evaluateScript(dispatch)?.toBool() ?? true
    }

    private func handle(for path: NodePath) -> Int {
        if let existing = pathToHandle[path] { return existing }
        let handle = nextHandle
        nextHandle += 1
        handleToPath[handle] = path
        pathToHandle[path] = handle
        return handle
    }

    private func installNativeFunctions() {
        let log: @convention(block) (JSValue) -> Void = { value in
            print(value.toString() ?? "")
        }
        context.setObject(log, forKeyedSubscript: "__log" as NSString)

        let querySelectorAll: @convention(block) (JSValue) -> [Int] = { [weak self] selectorValue in
            guard let self,
                  let selectorText = selectorValue.toString(),
                  let document,
                  let selector = CSSParser(selectorText).selector()
            else { return [] }
            return document.elementPaths(matching: selector).map { self.handle(for: $0) }
        }
        context.setObject(querySelectorAll, forKeyedSubscript: "__querySelectorAll" as NSString)

        let getAttribute: @convention(block) (JSValue, JSValue) -> String? = { [weak self] handleValue, nameValue in
            guard let self,
                  let path = handleToPath[Int(handleValue.toInt32())],
                  let name = nameValue.toString(),
                  case let .element(_, attributes, _)? = document?.node(at: path)
            else { return nil }
            return attributes[name]
        }
        context.setObject(getAttribute, forKeyedSubscript: "__getAttribute" as NSString)

        let innerHTMLSet: @convention(block) (JSValue, JSValue) -> Void = { [weak self] handleValue, htmlValue in
            guard let self,
                  let path = handleToPath[Int(handleValue.toInt32())],
                  let html = htmlValue.toString(),
                  let document
            else { return }
            let fragment = HTMLParser("<html><body>" + html + "</body></html>").parse()
            self.document = document.replacingChildren(with: bodyChildren(of: fragment), at: path)
        }
        context.setObject(innerHTMLSet, forKeyedSubscript: "__innerHTMLSet" as NSString)
    }

    private static let runtimeJS = """
    var LISTENERS = {};
    function Node(handle) { this.handle = handle; }
    function Event(type) { this.type = type; this.doDefault = true; }
    Event.prototype.preventDefault = function () { this.doDefault = false; };
    Node.prototype.getAttribute = function (name) { return __getAttribute(this.handle, name); };
    Node.prototype.addEventListener = function (type, listener) {
      LISTENERS[this.handle] = LISTENERS[this.handle] || {};
      if (!LISTENERS[this.handle][type]) {
        LISTENERS[this.handle][type] = [];
      }
      LISTENERS[this.handle][type].push(listener);
    };
    Node.prototype.dispatchEvent = function (event) {
      var listeners = (LISTENERS[this.handle] && LISTENERS[this.handle][event.type]) || [];
      for (var i = 0; i < listeners.length; i++) listeners[i].call(this, event);
      return event.doDefault;
    };
    Object.defineProperty(Node.prototype, 'innerHTML', {
      set: function (html) { __innerHTMLSet(this.handle, html.toString()); }
    });
    var console = { log: function (message) { __log(String(message)); } };
    var document = {
      querySelectorAll: function (selector) {
        return __querySelectorAll(selector).map(function (handle) { return new Node(handle); });
      }
    };
    """
}

private func bodyChildren(of document: HTMLNode) -> [HTMLNode] {
    guard case let .element(_, _, topLevelChildren) = document else { return [] }
    for child in topLevelChildren {
        if case let .element(tag, _, children) = child, tag == "body" { return children }
    }
    return topLevelChildren
}

private func jsStringLiteral(_ value: String) -> String {
    let escaped = value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}
