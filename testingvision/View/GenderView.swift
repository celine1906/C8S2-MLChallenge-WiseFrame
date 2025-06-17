//
//  GenderView.swift
//  testingvision
//
//  Created by Muhammad Azmi on 16/06/25.
//

import SwiftUI

struct GenderView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 180) {
            Spacer()
            
            VStack(alignment: .center, spacing: 36) {
                Text("What’s your gender?")
                    .font(Font.custom("Inder", size: 24))
                    .foregroundColor(Color(red: 0.65, green: 0.16, blue: 0.16))
                
                VStack(alignment: .center, spacing: 12) {
                    
                    Button(action: {
                        print("Female selected")
                        //
                    }) {
                        Text("Female")
                            .font(Font.custom("Inder", size: 20))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.86))
                            .frame(width: 203, height: 65)
                            .background(Color(red: 0.77, green: 0.47, blue: 0.47))
                            .cornerRadius(12)
                    }

                    Button(action: {
                        print("Male selected")
                        // 
                    }) {
                        Text("Male")
                            .font(Font.custom("Inder", size: 20))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.86))
                            .frame(width: 203, height: 65)
                            .background(Color(red: 0.77, green: 0.47, blue: 0.47))
                            .cornerRadius(12)
                    }
                }
                .padding(.bottom, 100)
            }
            
            Text("*Your input shapes your recommendations.")
                .font(Font.custom("Inder", size: 14))
                .foregroundColor(Color(red: 0.65, green: 0.16, blue: 0.16))
        }
        .navigationBarHidden(true)        
    }
    
}

#Preview {
    GenderView()
}
