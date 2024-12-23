// rust-api.swift

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
        print("URL inválida")
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
        print("Error al codificar las claves: \(error)")
        completion(false)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error en la solicitud: \(error)")
            completion(false)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("Respuesta no válida")
            completion(false)
            return
        }
        
        guard let data = data else {
            print("Datos no recibidos")
            completion(false)
            return
        }
        
        do {
            let responseData = try JSONDecoder().decode(ResponseData.self, from: data)
            completion(responseData.matches)
        } catch {
            print("Error al decodificar la respuesta: \(error)")
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

func verifyIdentity(publicKey: String, emojiSequence: String, completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: "\(base_url)/verify_identity") else {
        completion(false)
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let verifyData = [
        "public_key": publicKey,
        "emoji_sequence": emojiSequence
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: verifyData)
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
