//
//  SwiftUIView.swift
//  testingvision
//
//  Created by Muhammad Azmi on 16/06/25.
//

import SwiftUI

struct WelcomePages: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 0){
                Image("WelcomeVector")
                    .resizable()
                    .padding(0)
                    .scaledToFit()
                    .scaleEffect(0.7)
                
                Text("WELCOME")
                    .font(Font.custom("SFProDisplay-Bold", size: 32))
                    .multilineTextAlignment(.center)
                    .frame(width: 219, height: 43, alignment: .top)
                
                Text("Start scanning your face and let us help you find your suitable glasses")
                    .font(Font.custom("SFProDisplay-Medium", size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(red: 0.65, green: 0.16, blue: 0.16))
                    .frame(width: 274, alignment: .top)
                    .padding(.bottom, 32)
                
                NavigationLink(destination: GenderView()) {
                    Text("Find Your Frame")
                        .font(Font.custom("Inder", size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.86))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.77, green: 0.47, blue: 0.47))
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 100)
        }

        
    }
    
}

#Preview {
    WelcomePages()
}
