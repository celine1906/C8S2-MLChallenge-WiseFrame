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
            ZStack  {
                
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack(alignment: .leading, spacing: 0){
                    
                    Text("Start scanning your face and let us help you find your suitable glasses")
                        .font(Font.custom("SFProDisplay-Bold", size: 32))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color.redMain)
                        .padding(.bottom, 24)
                    
                    
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
                .padding()
            }
           
        }

        
    }
    
}

#Preview {
    WelcomePages()
}
