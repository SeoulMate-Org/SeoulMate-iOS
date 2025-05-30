//
//  MenuStyle.swift
//  PopPopSeoulKit
//
//  Created by suni on 4/20/25.
//

import SwiftUI
import SharedAssets

public struct AppMoreMenu: View {
  let items: [AppMoreMenuItem]
  let onDismiss: () -> Void
  var itemHeight: CGFloat 
  
  public init(items: [AppMoreMenuItem], onDismiss: @escaping () -> Void, itemHeight: CGFloat = 34) {
    self.items = items
    self.onDismiss = onDismiss
    self.itemHeight = itemHeight
  }
  
  public var body: some View {
    VStack(alignment: .center, spacing: 0) {
      ForEach(items.indices, id: \.self) { index in
        let item = items[index]
        
        Button(action: {
          item.action()
          onDismiss()
        }) {
          Text(item.title)
            .font(.buttonS)
            .foregroundColor(Colors.appBlack.swiftUIColor)
            .frame(height: itemHeight)
            .padding(.horizontal, 16)                // ✅ 내부 여백
        }
        .frame(minWidth: 80)
        
        if index < items.count - 1 {
          Divider()
            .foregroundStyle(Colors.gray75.swiftUIColor)
            .frame(height: 1)
        }
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Colors.appWhite.swiftUIColor)
        .stroke(Colors.gray75.swiftUIColor, lineWidth: 1.0)
        .modifier(ShadowModifier(
          shadow: AppShadow(
            color: Color(Colors.trueBlack.swiftUIColor).opacity(0.08),
            x: 0,
            y: 1,
            blur: 4,
            spread: 0
          )))
    )
  }
}

#Preview {
  AppMoreMenu(items:
                [AppMoreMenuItem(title: "수정", action: { }),
                 AppMoreMenuItem(title: "삭제", action: { })],
              onDismiss: { }
  )
  .frame(width: 80)
  
}

public struct AppMoreMenuItem: Identifiable {
  public let id = UUID()
  let title: String
  let action: () -> Void
  
  public init(title: String, action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }
}
