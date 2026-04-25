//
//  ProfileView.swift
//  ICS
//
//  Created by Daddy on 20/04/2026.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("🏠 Home Screen")
                .font(.largeTitle)
                .bold()
            
            Button {
                try? Auth.auth().signOut()
                router.resetToRoot(.login)
            } label: {
                Text("Logout")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ProfileView()
}
