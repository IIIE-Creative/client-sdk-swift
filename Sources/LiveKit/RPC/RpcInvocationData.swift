/**
 * Data passed to method handler for incoming RPC invocations
 */
public struct RpcInvocationData {
    /**
     * The unique request ID. Will match at both sides of the call, useful for debugging or logging.
     */
    public let requestId: String
    
    /**
     * The unique participant identity of the caller.
     */
    public let callerIdentity: String
    
    /**
     * The payload of the request. User-definable format, typically JSON.
     */
    public let payload: String
    
    /**
     * The maximum time the caller will wait for a response.
     */
    public let responseTimeout: TimeInterval
}
