//
//  SplashView.swift
//  Clients
//
//  Created by suni on 4/22/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import SharedAssets
import Common

struct SplashView: View {
  let store: StoreOf<SplashFeature>
  
  init(store: StoreOf<SplashFeature>) {
    self.store = store
  }
  
  var body: some View {

    let targetTop = Utility.safeTop * 0.682
    
    ZStack(alignment: .top) {
      let backWidht = Utility.screenWidth * (570.1 / 440)
      let backHeight = backWidht * (190 / 173)
      
      LinearGradient.blutFadeLeftToRight
      
      Assets.Images.splashTop.swiftUIImage
        .resizable()
        .scaledToFit()
        .frame(width: backWidht, height: backHeight)
        .padding(.top, targetTop)
      
      let bottomHeight = Utility.screenWidth * (52 / 55)
      VStack {
        Spacer()
        Assets.Images.splashBottom.swiftUIImage
          .resizable()
          .scaledToFit()
          .frame(width: Utility.screenWidth, height: bottomHeight)
      }
    }
    .ignoresSafeArea()
    .frame(maxWidth: Utility.screenWidth, maxHeight: Utility.screenHeight)
    .alert(
      store: store.scope(state: \.$alert, action: \.alert)
    )
    .onAppear {
      store.send(.onAppear)
    }
  }
}

#Preview {
  SplashView(
    store: Store<SplashFeature.State, SplashFeature.Action>(
      initialState: .init(),
      reducer: { SplashFeature() }
    )
  )
}

extension LinearGradient {
  static let blutFadeLeftToRight = LinearGradient(
    gradient: Gradient(stops: [
      .init(color: Color.hex(0x0058EE).opacity(1.0), location: 0.0),
      .init(color: Color.hex(0x649Dff).opacity(1.0), location: 1.0)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
}
