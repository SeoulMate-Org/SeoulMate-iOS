//
//  ThemeChallengeFeature.swift
//  Features
//
//  Created by suni on 4/29/25.
//

import Foundation
import ComposableArchitecture
import Common
import SharedTypes
import Models
import Clients

@Reducer
public struct ThemeChallengeFeature {
  
  @Dependency(\.callengeListClient) var callengeListClient
  @Dependency(\.challengeClient) var challengeClient
  
  // MARK: State
  
  @ObservableState
  public struct State: Equatable {
    public var fetchType: FetchType = .initial
    
    var isLogin: Bool
    var initTheme: ChallengeTheme = .mustSeeSpots
    var selectedTheme: ChallengeTheme = .mustSeeSpots
    var themeChallenges: [Challenge] = []
    var shouldScrollToTop: Bool = false
    var showAlert: Alert?
    
    public init(with theme: ChallengeTheme) {
      self.initTheme = theme
      self.isLogin = TokenManager.shared.isLogin
    }
  }
  
  public enum Alert: Equatable {
    case login
  }
  
  // MARK: Actions
  
  @CasePathable
  public enum Action: Equatable {
    case onApear
    case showAlert(Alert)
    case loginAlert(LoginAlertAction)
    case moveToMap(Challenge)
    case networkError
    case setShouldScrollToTop(Bool)
    
    case tappedBack
    case tappedChallenge(Int)
    case tappedLike(Int)
    
    case themeChanged(ChallengeTheme)
    case fetchThemeList(ChallengeTheme)
    case updateThemeList([Challenge])
    case update(Int, Challenge)
  }
  // MARK: Reducer
  @Dependency(\.dismiss) var dismiss
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onApear:
        state.isLogin = TokenManager.shared.isLogin
        state.fetchType = .resumed
        return .send(.themeChanged(state.initTheme))
      case let .setShouldScrollToTop(isTop):
        state.shouldScrollToTop = isTop
        return .none
        
      case .tappedBack:
        return .run { _ in
          await self.dismiss()
        }
        
      case let .tappedLike(id):
        if TokenManager.shared.isLogin {
          return .run { [state = state] send in
            guard let index = state.themeChallenges.firstIndex(where: { $0.id == id }) else { return }
            var update = state.themeChallenges[index]
            update.isLiked.toggle()
            update.likes = max(0, update.likes + (update.isLiked ? 1 : -1))
            await send(.update(index, update))
            
            do {
              let response = try await challengeClient.putLike(update.id)
              
              // 필요시 서버 데이터랑 다르면 다시 fetch
              if response.isLiked != update.isLiked {
                let fresh = try await challengeClient.get(response.id)
                await send(.update(index, fresh))
              }
            } catch {
              await send(.networkError)
            }
          }
        } else {
          return .send(.showAlert(.login))
        }
        
      case let .update(index, challenge):
        guard index < state.themeChallenges.count else { return .none }
        state.themeChallenges[index] = challenge
        return .none
        
      case let .themeChanged(theme):
        state.selectedTheme = theme
        state.fetchType = .tabChanged
        return .send(.fetchThemeList(theme))
        
      case let .fetchThemeList(theme):
        return .run { send in
          do {
            let list = try await callengeListClient.fetchThemeList(theme).list
            await send(.updateThemeList(list))
          } catch {
            await send(.networkError)
          }
        }
        
      case let .updateThemeList(list):
        state.themeChallenges = list
        
        if state.fetchType == .tabChanged {
          state.fetchType = .resumed
          return .send(.setShouldScrollToTop(true))
        }
        return .none
        
      case let .showAlert(alert):
        switch alert {
        case .login: state.showAlert = .login
        }
        return .none
        
      case .loginAlert(.cancelTapped):
        state.showAlert = nil
        return .none
        
      case .loginAlert(.loginTapped):
        // Main Tab Navigation
        state.showAlert = nil
        return .none
        
      case .moveToMap:
        // Main Tab Navigation
        return .none
        
      case .networkError:
        // TODO: - Error 처리
        return .none
        
      case .tappedChallenge:
        // Main Tab Navigation
        return .none
      }
    }
  }
}

// MARK: - Helper

public enum FetchType: Equatable {
  case initial        // 최초 패치
  case tabChanged     // 탭 변경
  case resumed        // 디테일 → 뒤로 돌아올 때
}
