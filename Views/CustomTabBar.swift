//
//  CustomTabBar.swift
//  ICS
//
//  Created by Daddy on 20/04/2026.
//

import SwiftUI

struct CustomTabBar: View {
    
    @StateObject private var vm = CustomTabBarViewModel()
    
    var body: some View {
        ZStack{
            
            if vm.index == 0 {
                ChatsView()
            } else if vm.index == 1 {
                SleepReportView()
            } else if vm.index == 2 {
                HomeView()
            } else if vm.index == 3 {
                ToolsView()
            } else if vm.index == 4 {
                AnalyzeSleepView()
            }
        }
        .navigationBarBackButtonHidden(true)
        CustomTaps(index: $vm.index)
    }
}

struct CustomTaps: View {
    
    @Binding var index: Int
    
    var body: some View {
        Spacer()
        
        HStack {
            
            Button {
                self.index = 0
            } label: {
                VStack {
                    Image(systemName: "ellipsis.message.fill")
                        .font(.system(size: 30))
                    Text("Chats")
                        .font(.caption)
                }
                
            }
            .foregroundStyle(Color.blue.opacity(self.index == 0 ? 1 : 0.1))
            Spacer(minLength: 0)

            Button {
                self.index = 1
            } label: {
                VStack {
                    VStack {
                        Image(systemName: "pencil.and.list.clipboard")
                            .font(.system(size: 30))
                        Text("Sleep Reports")
                            .font(.caption)
                    }
                    
                }
            }
            .foregroundStyle(Color.blue.opacity(self.index == 1 ? 1 : 0.3))
            Spacer(minLength: 0)
            
            Button {
                self.index = 2
            } label: {
                VStack {
                    Image(systemName: "house.fill")
                        .font(.system(size: 30))
                    Text("Home")
                        .font(.caption)

                }
                            }
            .foregroundStyle(Color.white.opacity(self.index == 2 ? 1 : 0.3))
            
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                )

            Spacer(minLength: 0)
            
            Button {
                self.index = 3
            } label: {
                VStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 30))
                    Text("Tools")
                        .font(.caption)
                }
                
            }
            .foregroundStyle(Color.blue.opacity(self.index == 3 ? 1 : 0.3))
            Spacer(minLength: 0)
            
            Button {
                self.index = 4
            } label: {
                VStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 30))
                    Text("Analyze sleep")
                        .font(.caption)
                }
            }
            .foregroundStyle(Color.blue.opacity(self.index == 4 ? 1 : 0.3))
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.white)
    }
}

#Preview {
    CustomTabBar()
}
