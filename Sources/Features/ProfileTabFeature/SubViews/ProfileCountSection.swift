//
//  ProfileCountView.swift
//  Features
//
//  Created by suni on 5/2/25.
//

import SwiftUI
import Common
import DesignSystem
import SharedAssets
import SharedTypes
import Models

struct ProfileCountView: View {
  let user: User?
  let onbadgeTapped: () -> Void
  let onLikeTapped: () -> Void
  let onCommentTapped: () -> Void
  
  var body: some View {
    HStack(alignment: .center, spacing: 4) {
      profileCountItem(title: L10n.mybuttonText_badge, count: user?.badgeCount ?? 0, onTap: onbadgeTapped)
      
      divider
      
      profileCountItem(title: L10n.mybuttonText_JJIMSpots, count: user?.likedCount ?? 0, onTap: onLikeTapped)
      
      divider
      
      profileCountItem(title: L10n.mybuttonText_myComments, count: user?.commentCount ?? 0, onTap: onCommentTapped)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 80)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Colors.appWhite.swiftUIColor)
    )
    .padding(.horizontal, 20)
  }
  
  private func profileCountItem(
    title: String,
    count: Int,
    onTap: @escaping () -> Void
  ) -> some View {
    Button(action: onTap) {
      VStack(alignment: .center, spacing: 6) {
        Text(title)
          .font(.captionSB)
          .foregroundStyle(Colors.gray400.swiftUIColor)
        
        Text(count > 0 ? "\(count)" : "-")
          .font(.bodyM)
          .foregroundStyle(Colors.trueBlack.swiftUIColor)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 41)
    }
    .buttonStyle(.plain)
  }
  
  private var divider: some View {
    Rectangle()
      .frame(width: 1, height: 48)
      .foregroundColor(Colors.gray25.swiftUIColor)
  }
  
}
