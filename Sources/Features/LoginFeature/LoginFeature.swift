//  LoginFeature.swift
//  PopPopSeoulKit
//
//  Created by suni on 4/21/25.
//

import Foundation
import ComposableArchitecture
import Clients
import AuthenticationServices
import FacebookLogin
import GoogleSignIn
import FirebaseCore
import Models
import SharedTypes
import Common

@Reducer
public struct LoginFeature {
  init() {
    
  }
  
  @Dependency(\.authClient) var authClient
  @Dependency(\.userDefaultsClient) var userDefaultsClient
  
  // MARK: State
  
  @ObservableState
  public struct State: Equatable {
    let isInit: Bool
    
    public init(isInit: Bool) {
      self.isInit = isInit
    }
  }
  
  // MARK: Actions
  
  @CasePathable
  public enum Action: Equatable {
    case googleSignInCompleted(String)
    case facebookSignInCompleted(String)
    case appleSignInCompleted(String)
    case loginError
    case authLogin(AuthProvider)
    case authFbLogin(AuthProvider)
    case successLogin(isNewUser: Bool)
    case backTapped
    case aroundTapped
  }
  
  // MARK: Reducer
  
  @Dependency(\.dismiss) var dismiss
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .googleSignInCompleted(token):
        return .send(.authLogin(.google(idToken: token)))
        
      case let .facebookSignInCompleted(email):
        return .send(.authFbLogin(.facebook(email: email)))
        
      case let .appleSignInCompleted(token):
        return .send(.authLogin(.apple(identityToken: token)))
        
      case .loginError:
        logger.error("로그인 실패")
        return .none
        
      case let .authLogin(provider):
        return .run { send in
          do {
            let auth = try await authClient.login(provider)
            await send(.successLogin(isNewUser: auth.isNewUser))
          } catch {
            await send(.loginError)
          }
        }
        
      case let .authFbLogin(provider):
        return .run { send in
          do {
            let auth = try await authClient.fbLogin(provider)
            await send(.successLogin(isNewUser: auth.isNewUser))
          } catch {
            await send(.loginError)
          }
        }
        
      case .backTapped:
        return .run { _ in
          await self.dismiss()
        }
        
      case .aroundTapped:
        return .none
        
      case .successLogin:
        return .none
      }
    }
  }
  
}

// MARK: - Helper
