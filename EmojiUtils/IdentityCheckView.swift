//
//  IdentityCheckView.swift
//  EmojiUtils
//
//  Created by nichokas on 22/12/24.
//

import SwiftUI

struct IdentityCheckView: View {
    var body: some View {
        // If the user is logged in (keys exist), show UserView; otherwise, LoginView.
        if AuthManager.userIsLoggedIn() {
            UserView()
        } else {
            LoginView()
        }
    }
}
