//  ChatsView.swift
//  ICS
//
//  Created by Daddy on 20/04/2026.
//
import SwiftUI

struct ChatsView: View {
    
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        ZStack(alignment: .top) {
            
            Color(
                red: 220/255,
                green: 224/255,
                blue: 253/255
            )
            .ignoresSafeArea()
            
            VStack {
                Image("Screenshot 2026-04-21 at 6.25.22 PM")
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                    .onTapGesture {
                        router.goTo(.chat)
                    }
                
                Spacer()
            }
        }
    }
}

#Preview {
    ChatsView()
}
