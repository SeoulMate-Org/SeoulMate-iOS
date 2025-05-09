//
//  HomeThemeTabView.swift
//  Clients
//
//  Created by suni on 4/24/25.
//

import SwiftUI
import DesignSystem
import Common
import SharedAssets
import SharedTypes

struct HomeThemeTabView: View {
  let tab: ChallengeTheme
  let isSelected: Bool
  let onTapped: () -> Void
    
  var body: some View {
    Button(action: {
      onTapped()
    }) {
      Text(tab.title)
        .font(.captionM)
        .foregroundColor(isSelected ? Colors.blue500.swiftUIColor : Colors.gray900.swiftUIColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
    .frame(minWidth: 67)
    .frame(height: 30)
    .background(
      isSelected
      ? Colors.blue50.swiftUIColor
      : Colors.appWhite.swiftUIColor
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(isSelected ? Colors.blue500.swiftUIColor : Colors.gray200.swiftUIColor, lineWidth: 1)
    )
    .cornerRadius(12)
    .background(.clear)
  }
}
