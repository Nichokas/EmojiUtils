import Foundation

struct UserInfo: Codable {
    var name: String?
    var email: String?
    var phone_number: String?
    var gpg_fingerprint: String?
}

struct IdentityProofResponse: Codable {
    var emoji_sequence: String
}

struct VerifyIdentityResponse: Codable {
    let created_at: String?
    let created_at_utc: UTCTime?
    let public_key: String
    let verified: Bool
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case created_at
        case created_at_utc
        case public_key
        case verified
        case message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.verified = try container.decode(Bool.self, forKey: .verified)
        self.message = try? container.decode(String.self, forKey: .message)
        
        if self.verified {
            self.created_at = try container.decode(String.self, forKey: .created_at)
            self.created_at_utc = try container.decode(UTCTime.self, forKey: .created_at_utc)
            self.public_key = try container.decode(String.self, forKey: .public_key)
        } else {
            self.created_at = nil
            self.created_at_utc = nil
            self.public_key = ""
        }
    }
}
struct UTCTime: Codable {
    let hour: Int
    let minute: Int
    let second: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hour = try container.decode(Int.self, forKey: .hour)
        self.minute = try container.decode(Int.self, forKey: .minute)
        self.second = try container.decode(Int.self, forKey: .second)
    }
}

let base_url = "https://nichokas.hackclub.app"

func login(pub_key: String, priv_key: String, completion: @escaping (Bool) -> Void) {
    struct ResponseData: Codable {
        var matches: Bool
        var message: String
    }
    
    struct Keys: Codable {
        let public_key: String
        let private_key: String
    }
    
    let keys = Keys(public_key: pub_key, private_key: priv_key)
    
    guard let url = URL(string: "\(base_url)/check") else {
        print("Invalid URL")
        completion(false)
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        let jsonData = try JSONEncoder().encode(keys)
        request.httpBody = jsonData
    } catch {
        print("Error encoding keys: \(error)")
        completion(false)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Request error: \(error)")
            completion(false)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("Invalid response")
            completion(false)
            return
        }
        
        guard let data = data else {
            print("No data received")
            completion(false)
            return
        }
        
        do {
            let responseData = try JSONDecoder().decode(ResponseData.self, from: data)
            completion(responseData.matches)
        } catch {
            print("Error decoding response: \(error)")
            completion(false)
        }
    }
    
    task.resume()
}
func getUserInfo(publicKey: String, completion: @escaping (UserInfo?) -> Void) {
    guard let encodedKey = publicKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "\(base_url)/user_info/\(encodedKey)") else {
        completion(nil)
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
              let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            completion(nil)
            return
        }
        
        do {
            let userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
            completion(userInfo)
        } catch {
            print("Error decoding user info: \(error)")
            completion(nil)
        }
    }
    task.resume()
}

func updateUserInfo(privateKey: String, email: String?, phoneNumber: String?, name: String?, pgp: String?, completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: "\(base_url)/update_user_info") else {
        completion(false)
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let updateData = [
        "private_key": privateKey,
        "email": email,
        "phone_number": phoneNumber,
        "name": name,
        "gpg_fingerprint": pgp
    ].compactMapValues { $0 }
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: updateData)
    } catch {
        completion(false)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            completion(false)
            return
        }
        completion(true)
    }
    task.resume()
}

func createIdentityProof(privateKey: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "\(base_url)/create_identity_proof") else {
        completion(nil)
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let proofData = ["private_key": privateKey]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: proofData)
    } catch {
        completion(nil)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
              let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            completion(nil)
            return
        }
        
        do {
            let response = try JSONDecoder().decode(IdentityProofResponse.self, from: data)
            completion(response.emoji_sequence)
        } catch {
            completion(nil)
        }
    }
    task.resume()
}

func verifyIdentity(emojiSequence: String, completion: @escaping (Result<VerifyIdentityResponse, Error>) -> Void) {
    guard let url = URL(string: "\(base_url)/verify_identity") else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let verifyData = ["emoji_sequence": emojiSequence]
    
    do {
        request.httpBody = try JSONSerialization.data(with: verifyData)
        print("Sending to server:", verifyData)
    } catch {
        completion(.failure(error))
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
            return
        }
        
        print("HTTP status code:", httpResponse.statusCode)
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let data = data, let errorStr = String(data: data, encoding: .utf8) {
                print("Server error:", errorStr)
            }
            completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
            return
        }
        
        do {
            if let strData = String(data: data, encoding: .utf8) {
                print("Server response:", strData)
            }
            
            let response = try JSONDecoder().decode(VerifyIdentityResponse.self, from: data)
            completion(.success(response))
        } catch {
            print("Error decoding:", error)
            print("Received data:", String(data: data, encoding: .utf8) ?? "No data")
            completion(.failure(error))
        }
    }
    task.resume()
}
