//
//  Dismiss.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 17/06/25.
//

import SwiftUI

struct Dismiss: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                // Tutup / dismiss action
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(red: 0.73, green: 0.4, blue: 0.39)) // warna pink
                    .padding()
            }
        }
    }
}
