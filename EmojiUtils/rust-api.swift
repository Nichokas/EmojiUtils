// rust-api.swift

import Foundation

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
