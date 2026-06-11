//
//  DrChatView.swift
//  ICS
//
//  Created by Daddy on 21/04/2026.
//

import SwiftUI

struct DrChatView: View {
    var body: some View {
        ZStack(alignment: .top) {
            
            Color(
                red: 220/255,
                green: 224/255,
                blue: 253/255
            )
            .ignoresSafeArea()
            
            VStack {
                Image("image 6-003")
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                Spacer()
            }
        }
    }
}

#Preview {
    DrChatView()
}
