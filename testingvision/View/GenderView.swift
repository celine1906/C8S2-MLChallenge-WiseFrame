//
//  GenderView.swift
//  testingvision
//
//  Created by Muhammad Azmi on 16/06/25.
//

import SwiftUI

struct GenderView: View {
    @State private var isShowingResult = false

    var body: some View {
        VStack(spacing: 0) {
            // Close button aligned to top trailing
            Dismiss()

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("What’s your gender?")
                    .font(.custom("Inika", size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.65, green: 0.16, blue: 0.16))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 300, alignment: .leading)                    

                Text("Your choice helps us find your suitable glasses")
                    .font(.custom("Inder", size: 20))
                    .foregroundColor(Color(red: 0.65, green: 0.16, blue: 0.16))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 24) {
                    Button(action: {
                        print("Female selected")
                        isShowingResult.toggle()
                    }) {
                        Text("Female")
                            .font(.custom("Inder", size: 24))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color(red: 0.85, green: 0.58, blue: 0.58))
                            .cornerRadius(24)
                            .shadow(color: .gray.opacity(0.4), radius: 8, x: 0, y: 5)
                    }

                    Button(action: {
                        print("Male selected")
                        isShowingResult.toggle()
                    }) {
                        Text("Male")
                            .font(.custom("Inder", size: 24))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color(red: 0.85, green: 0.58, blue: 0.58))
                            .cornerRadius(24)
                            .shadow(color: .gray.opacity(0.4), radius: 8, x: 0, y: 5)
                    }
                }
                .padding(.bottom, 80)
            }
            .frame(maxWidth: 350, minHeight: 100)
            .padding(.bottom, 40)
            
            

            
            Spacer()

            Text("*Your input shapes your recommendations.")
                .font(.custom("Inder", size: 14))
                .foregroundColor(Color(red: 0.65, green: 0.16, blue: 0.16))
                .padding(.bottom, 30)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $isShowingResult) {
            CameraView()
        }
    }
}

#Preview {
    GenderView()
}
