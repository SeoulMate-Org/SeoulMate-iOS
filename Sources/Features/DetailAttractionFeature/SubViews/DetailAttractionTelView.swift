//
//  DetailAttractionTelView.swift
//  Features
//
//  Created by suni on 4/30/25.
//

import SwiftUI
import Common
import SharedAssets
import SharedTypes
import Models
import DesignSystem

struct DetailAttractionTelView: View {
  let text: String
  let onPasteTapped: () -> Void
  
  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      
      Assets.Icons.callLine.swiftUIImage
        .resizable()
        .frame(width: 18, height: 18)
        .foregroundStyle(Colors.gray400.swiftUIColor)
        .padding(.top, 8)
      
      Text(text)
        .multilineTextAlignment(.leading)
        .font(.bodyS)
        .foregroundStyle(Colors.gray900.swiftUIColor)
        .frame(alignment: .leading)
        .padding(.vertical, 8)
      
      Button(action: {
        onPasteTapped()
        UIPasteboard.general.string = text
      }) {
        Text(L10n.textButton_copy)
          .foregroundStyle(Colors.blue500.swiftUIColor)
          .font(.buttonS)
      }
      .frame(width: 54, height: 32)
      
      Spacer()
    }
  }
}
