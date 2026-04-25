//
//  UserView.swift
//  ICS
//
//  Created by Daddy on 20/04/2026.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct UserView: View {
    
    @EnvironmentObject var router: AppRouter
    
    @State private var processedImage: Image?
    @State private var uiImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    
    @AppStorage("savedImageName") private var savedImageName: String?
    
    @State private var showSaveAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Image Picker
            PhotosPicker(selection: $selectedItem) {
                if let processedImage {
                    processedImage
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ContentUnavailableView(
                        "No Picture",
                        systemImage: "photo.badge.plus",
                        description: Text("Tap to import a photo")
                    )
                }
            }
            .buttonStyle(.plain)
            .onChange(of: selectedItem) { _, _ in
                loadImage()
            }
            
            
            // MARK: - Save Button
            if uiImage != nil {
                Button("Save Photo") {
                    saveImageToAppStorage()
                }
                .buttonStyle(.borderedProminent)
            }
            
            
            // MARK: - Extra Buttons
            VStack(spacing: 12) {
                
                Button("Saved Posts") {
                    print("Saved Posts tapped")
                }
                
                Button("Your Posts") {
                    print("Your Posts tapped")
                }
                
                Button("Logout") {
                    logout()
                }
                .foregroundColor(.red)
            }
            .padding(.top, 20)
        }
        .padding()
        .onAppear {
            loadSavedImage() // ✅ load image when view opens
        }
        .alert(alertMessage, isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    // MARK: - Load Picked Image
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self),
                  let inputImage = UIImage(data: imageData) else { return }
            
            uiImage = inputImage
            processedImage = Image(uiImage: inputImage)
        }
    }
    
    // MARK: - Save Image Locally
    func saveImageToAppStorage() {
        guard let uiImage,
              let data = uiImage.pngData() else { return }
        
        let fileName = UUID().uuidString + ".png"
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try data.write(to: url)
                
                DispatchQueue.main.async {
                    savedImageName = fileName // ✅ store file reference
                    alertMessage = "Image saved locally!"
                    showSaveAlert = true
                }
                
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Failed to save image."
                    showSaveAlert = true
                }
            }
        }
    }
    
    // MARK: - Load Saved Image
    func loadSavedImage() {
        guard let savedImageName else { return }
        
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(savedImageName)
        
        if let uiImage = UIImage(contentsOfFile: url.path) {
            self.uiImage = uiImage
            self.processedImage = Image(uiImage: uiImage)
        }
    }
    
    // MARK: - Logout
    func logout() {
        do {
            try Auth.auth().signOut()
            router.resetToRoot(.login)
        } catch {
            print("Logout error:", error)
        }
    }
}

#Preview {
    UserView()
}
