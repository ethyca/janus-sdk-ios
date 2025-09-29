import Foundation
import JanusSDK

public class HTTPLogger: JanusLogger {
    private let endpoint: URL
    private let authToken: String
    private let source: String
    private let session: URLSession
    private let enableConsoleErrors: Bool
    
    public init(endpoint: String, authToken: String, source: String = "iOSExampleApp", enableConsoleErrors: Bool = false) {
        guard let url = URL(string: endpoint) else {
            fatalError("Invalid endpoint URL: \(endpoint)")
        }
        self.endpoint = url
        self.authToken = authToken
        self.source = source
        self.session = URLSession.shared
        self.enableConsoleErrors = enableConsoleErrors
    }
    
    public func log(_ message: String, level: LogLevel = .info, metadata: [String: String]? = nil, error: Error? = nil) {
        let logData = createLogPayload(message: message, level: level, metadata: metadata, error: error)
        sendLogRequest(logData: logData)
    }
    
    private func createLogPayload(message: String, level: LogLevel, metadata: [String: String]?, error: Error? = nil) -> [String: Any] {
        var logEntry: [String: Any] = [
            "log_level": levelString(level),
            "message": message
        ]
        
        if let metadata = metadata {
            let encodedData = encodeMetadata(metadata)
            logEntry["data"] = encodedData
        }
        
        if let error = error {
            logEntry["error"] = [
                "description": error.localizedDescription,
                "domain": (error as NSError).domain,
                "code": (error as NSError).code
            ]
        }
        
        return [
            "logs": [
                ["log": logEntry]
            ],
            "source": source
        ]
    }
    
    private func levelString(_ level: LogLevel) -> String {
        switch level {
        case .verbose:
            return "VERBOSE"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        }
    }
    
    private func encodeMetadata(_ metadata: [String: String]) -> String {
        do {
            // Try JSON serialization
            let data = try JSONSerialization.data(withJSONObject: metadata, options: [])
            if let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        } catch {
            // JSON serialization failed - log only if enabled
            if enableConsoleErrors {
                print("HTTPLogger: JSON serialization failed for metadata: \(error.localizedDescription)")
            }
        }
        
        // Ultimate fallback to string representation
        return String(describing: metadata)
    }
    
    private func sendLogRequest(logData: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: logData, options: [])
            
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    if self.enableConsoleErrors {
                        print("HTTPLogger: Network error - \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    if self.enableConsoleErrors {
                        print("HTTPLogger: Invalid response")
                    }
                    return
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if self.enableConsoleErrors {
                        print("HTTPLogger: HTTP error - Status code: \(httpResponse.statusCode)")
                        if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                            print("HTTPLogger: Response body - \(responseBody)")
                        }
                    }
                }
            }.resume()
        } catch {
            if enableConsoleErrors {
                print("HTTPLogger: Failed to serialize log data - \(error.localizedDescription)")
                print("HTTPLogger: Log data that failed: \(logData)")
            }
        }
    }
} 