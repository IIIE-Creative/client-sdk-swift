/**
 * Specialized error handling for RPC methods.
 *
 * Instances of this type, when thrown in a method handler, will have their `message`
 * serialized and sent across the wire. The caller will receive an equivalent error on the other side.
 *
 * Built-in types are included but developers may use any string, with a max length of 256 bytes.
 */
public class RpcError: Error {
    public let code: Int
    public let message: String
    public let data: String?

    /**
     * Creates an error object with the given code and message, plus an optional data payload.
     *
     * If thrown in an RPC method handler, the error will be sent back to the caller.
     *
     * Error codes 1001-1999 are reserved for built-in errors (see RpcError.ErrorCode for their meanings).
     */
    public init(code: Int, message: String, data: String? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    static func fromProto(_ proto: Livekit_RpcError) -> RpcError {
        return RpcError(code: Int(proto.code), message: proto.message, data: proto.data)
    }

    func toProto() -> Livekit_RpcError {
        var proto = Livekit_RpcError()
        proto.code = UInt32(code)
        proto.message = message
        if let data = data {
            proto.data = data
        }
        return proto
    }

    public struct ErrorCode {
        public static let APPLICATION_ERROR = 1500
        public static let CONNECTION_TIMEOUT = 1501
        public static let RESPONSE_TIMEOUT = 1502
        public static let RECIPIENT_DISCONNECTED = 1503
        public static let RESPONSE_PAYLOAD_TOO_LARGE = 1504
        public static let SEND_FAILED = 1505

        public static let UNSUPPORTED_METHOD = 1400
        public static let RECIPIENT_NOT_FOUND = 1401
        public static let REQUEST_PAYLOAD_TOO_LARGE = 1402
        public static let UNSUPPORTED_SERVER = 1403
    }

    /**
     * @internal
     */
    internal static let errorMessages: [Int: String] = [
        ErrorCode.APPLICATION_ERROR: "Application error in method handler",
        ErrorCode.CONNECTION_TIMEOUT: "Connection timeout",
        ErrorCode.RESPONSE_TIMEOUT: "Response timeout",
        ErrorCode.RECIPIENT_DISCONNECTED: "Recipient disconnected",
        ErrorCode.RESPONSE_PAYLOAD_TOO_LARGE: "Response payload too large",
        ErrorCode.SEND_FAILED: "Failed to send",

        ErrorCode.UNSUPPORTED_METHOD: "Method not supported at destination",
        ErrorCode.RECIPIENT_NOT_FOUND: "Recipient not found",
        ErrorCode.REQUEST_PAYLOAD_TOO_LARGE: "Request payload too large",
        ErrorCode.UNSUPPORTED_SERVER: "RPC not supported by server"
    ]

    /**
     * Creates an error object from the code, with an auto-populated message.
     *
     * @internal
     */
    internal static func builtIn(code: Int, data: String? = nil) -> RpcError {
        return RpcError(code: code, message: errorMessages[code] ?? "Unknown error", data: data)
    }
}
