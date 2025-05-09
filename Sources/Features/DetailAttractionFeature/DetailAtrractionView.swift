//
//  DetailAtrractionView.swift
//  Features
//
//  Created by suni on 4/30/25.
//

import SwiftUI
import ComposableArchitecture
import Common
import DesignSystem
import SharedAssets

struct DetailAtrractionView: View {
  let store: StoreOf<DetailAttractionFeature>
  @ObservedObject var viewStore: ViewStore<DetailAttractionFeature.State, DetailAttractionFeature.Action>
  
  init(store: StoreOf<DetailAttractionFeature>) {
    self.store = store
    self.viewStore = ViewStore(self.store, observe: { $0 })
  }
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(spacing: 0) {
        // 헤더
        HeaderView(type: .back(title: "", onBack: {
          viewStore.send(.tappedBack)
        }))
        
        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 0) {
            if let attraction = viewStore.attraction {
              DetailAttractionTopSection(
                attraction: attraction,
                onLikeTapped: {
                  viewStore.send(.tappedLike)
                })
              divider()
              
              DetailAttractionInfoSection(
                attraction: attraction,
                onPasteTapped: {
                  viewStore.send(.showToast(.paste))
                }
              )
            }
            
            if let data = viewStore.map,
               let uiImage = UIImage(data: data) {
              DetailAttractionMapSection(
                image: Image(uiImage: uiImage),
                onMapTapped: {
                  viewStore.send(.tappedNaverMap)
                })
              .padding(.top, 24)
            }
          }
          .padding(.bottom, 80)
        }
      }
    }
    .overlay(
      Group {
        if viewStore.showLoginAlert {
          AppLoginAlertView(onLoginTapped: {
            viewStore.send(.loginAlert(.loginTapped))
          }, onCancelTapped: {
            viewStore.send(.loginAlert(.cancelTapped))
          })
        }
        
        if let toast = viewStore.showToast {
          VStack {
            Spacer()
            AppToast(type: .text(message: toast.message))
              .padding(.bottom, 16)
              .transition(.opacity.animation(.easeInOut(duration: 0.2)))
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
      }
    )
    .onAppear {
      viewStore.send(.onApear)
    }
    .navigationBarBackButtonHidden(true)
  }
  
  private func divider() -> some View {
    return Divider()
      .frame(height: 2)
      .foregroundColor(Colors.gray25.swiftUIColor)
      .padding(.vertical, 16)
  }
}

// MARK: Preview

// MARK: - Helper
extension DetailAttractionFeature.Toast {
  var message: String {
    switch self {
    case .paste: L10n.toastText_copied
    }
  }
}
