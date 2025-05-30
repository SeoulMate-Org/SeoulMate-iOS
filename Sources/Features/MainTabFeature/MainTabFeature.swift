//
//  MainTabFeature.swift
//  SeoulMateKit
//
//  Created by suni on 4/2/25.
//

import Foundation
import ComposableArchitecture
import Clients
import Common

@Reducer
public struct MainTabFeature {
  public init() {}
  
  // MARK: State
  
  @ObservableState
  public struct State: Equatable {
    public var selectedTab: Tab = .home
    
    public enum Tab {
      case home, myChallenge, profile
    }
    
    var home: HomeTabFeature.State = .init()
    var myChallenge: MyChallengeTabFeature.State = .init()
    var profile: ProfileTabFeature.State = .init()
    
    var showAlert: Alert?
    
    var path = StackState<Path.State>()
  }
  
  // MARK: Actions
  
  @CasePathable
  public enum Action: Equatable {
    case selectedTabChanged(State.Tab)
    
    case home(HomeTabFeature.Action)
    case myChallenge(MyChallengeTabFeature.Action)
    case profile(ProfileTabFeature.Action)
    
    case alertAction(Alert, Bool)
    case successLogin(isNewUser: Bool)
    
    case path(StackActionOf<Path>)
    
    case appReLaunch
  }
  
  public enum Alert: Equatable {
    case login
    case logout
    case onLocation
    case offLocation
  }
  
  // MARK: Reducer
  
  public var body: some Reducer<State, Action> {
    Scope(state: \.myChallenge, action: \.myChallenge) {
      MyChallengeTabFeature()
    }
    
    Scope(state: \.home, action: \.home) {
      HomeTabFeature()
    }
    
    Scope(state: \.profile, action: \.profile) {
      ProfileTabFeature()
    }
    
    Reduce { state, action in
      switch action {
      case .selectedTabChanged(let tab):
        switch tab {
        case .home:
          state.home.onAppearType = .tabReappeared
          state.selectedTab = tab
        case .myChallenge:
          if !TokenManager.shared.isLogin {
            state.showAlert = .login
          } else {
            state.selectedTab = tab
          }
        case .profile:
          state.profile.onAppearType = .tabReappeared
          state.selectedTab = tab
        }
        return .none
        
      case let .alertAction(alert, isDone):
        switch alert {
        case .login:
          state.showAlert = nil
          if isDone {
            state.path.append(.login(LoginFeature.State(isInit: false)))
            return .none
          } else {
            return .none
          }
        case .logout:
          state.showAlert = nil
          if isDone {
            return .send(.profile(.tappedLogout))
          } else {
            return .none
          }
        case .onLocation, .offLocation:
          state.showAlert = nil
          if isDone {
            Utility.moveAppSetting()
            return .none
          } else {
            return .none
          }
        }
        
        // MARK: - My Challenge Reducer
      case .myChallenge(.tappedItem(let id)):
        state.path.append(.detailChallenge(DetailChallengeFeature.State(with: id)))
        return .none
        
      case .myChallenge(.moveToHome):
        return .send(.selectedTabChanged(.home))
        
        // MARK: - Home Reducer
      case let .home(.showAlert(alert)):
        switch alert {
        case .login: state.showAlert = .login
        case .onLocation: state.showAlert = .onLocation
        }
        return .none
        
      case .home(.tappedChallenge(let id)):
        state.path.append(.detailChallenge(DetailChallengeFeature.State(with: id)))
        return .none
        
      case .home(.moveToThemeChallenge(let theme)):
        state.path.append(.themeChallenge(ThemeChallengeFeature.State(with: theme)))
        return .none
        
      case .home(.moveToRank):
        state.path.append(.rankChallenge(RankChallengeFeature.State()))
        return .none
        
        // MARK: - Profile Reducer
      case .profile(.move(let action)):
        switch action {
        case let .nicknameSetting(nickname):
          state.path.append(.nicknameSetting(NicknameSettingFeature.State(nickname: nickname)))
          return .none
          
        case .badge:
          state.path.append(.myBadge(MyBadgeFeature.State()))
          return .none
          
        case .likeAttraction:
          state.path.append(.likeAttraction(LikeAttractionFeature.State()))
          return .none
          
        case .comment:
          state.path.append(.myComment(MyCommentFeature.State()))
          return .none
          
        case let .language(language):
          state.path.append(.languageSetting(LanguageSettingFeature.State(language: language)))
          return .none
          
        case .notification:
          return .none
          
        case .onboarding:
          state.path.append(.onboarding(OnboardingFeature.State(isInit: false)))
          return .none
          
        case let .withdraw(user):
          state.path.append(.withdraw(WithdrawFeature.State(user: user)))
          return .none
        }
        
      case .profile(.showAlert(let alert)):
        switch alert {
        case .login:
          state.showAlert = .login
          return .none
          
        case .logout:
          state.showAlert = .logout
          return .none
          
        case .onLocation:
          state.showAlert = .onLocation
          return .none
          
        case .offLocation:
          state.showAlert = .offLocation
          return .none
        }
        
        // MARK: - Path Reducer
      case let .path(action):
        switch action {
          // move to detail comments
        case let .element(id: _, action: .detailChallenge(.moveToAllComment(id, comment, isFocus))):
          state.path.append(.detailComments(DetailCommentsFeature.State(with: id, comment: comment, isFocus: isFocus)))
          return .none
          
          // move to detail attraction
        case .element(id: _, action: .detailChallenge(.tappedAttraction(let id))),
            .element(id: _, action: .attractionMap(.tappedDetail(let id))),
            .element(id: _, action: .likeAttraction(.tappedDetail(let id))):
          state.path.append(.detailAttraction(DetailAttractionFeature.State(with: id)))
          return .none
          
        case .element(id: _, action: .detailChallenge(.moveToMap(let challenge))):
          state.path.append(.attractionMap(AttractionMapFeature.State(with: challenge)))
          return .none
          
          // move to login
        case .element(id: _, action: .detailChallenge(.loginAlert(.loginTapped))),
            .element(id: _, action: .themeChallenge(.loginAlert(.loginTapped))),
            .element(id: _, action: .detailAttraction(.loginAlert(.loginTapped))),
            .element(id: _, action: .attractionMap(.loginAlert(.loginTapped))):
          state.path.append(.login(LoginFeature.State(isInit: false)))
          return .none
          
        case let .element(id: _, action: .login(.successLogin(isNewUser))):
          return .send(.successLogin(isNewUser: isNewUser))
          
          // move to detail challenge
        case .element(id: _, action: .themeChallenge(.tappedChallenge(let id))):
          state.path.append(.detailChallenge(DetailChallengeFeature.State(with: id)))
          return .none
          
          // move to complete challenge
        case .element(id: _, action: .detailChallenge(.showCompleteChallenge(let theme))):
          state.path.append(.completeChallenge(CompleteChallengeFeature.State(with: theme)))
          return .none
          
          // move to home
        case .element(id: _, action: .myComment(.moveToHome)):
          state.path.removeAll()
          state.home.onAppearType = .tabReappeared
          state.selectedTab = .home
          return .none
          
          // move to my > badge
        case .element(id: _, action: .completeChallenge(.moveToBadge)):
          state.path.removeAll()
          state.profile.onAppearType = .tabReappeared
          state.selectedTab = .profile
          state.path.append(.myBadge(MyBadgeFeature.State()))
          return .none
          
          // app re launch
        case .element(id: _, action: .languageSetting(.appReLaunch)):
          return .send(.appReLaunch)
          
        default:
          return .none
        }
        
      default:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

// MARK: - Helper
extension MainTabFeature {
  
  @Reducer(state: .equatable, action: .equatable)
  public enum Path {
    case detailChallenge(DetailChallengeFeature)
    case detailComments(DetailCommentsFeature)
    case login(LoginFeature)
    case themeChallenge(ThemeChallengeFeature)
    case rankChallenge(RankChallengeFeature)
    case detailAttraction(DetailAttractionFeature)
    case attractionMap(AttractionMapFeature)
    case completeChallenge(CompleteChallengeFeature)
    case myBadge(MyBadgeFeature)
    case likeAttraction(LikeAttractionFeature)
    case myComment(MyCommentFeature)
    case languageSetting(LanguageSettingFeature)
    case nicknameSetting(NicknameSettingFeature)
    case withdraw(WithdrawFeature)
    case onboarding(OnboardingFeature)
  }
  
}

public enum LoginAlertAction: Equatable {
  case cancelTapped
  case loginTapped
}

public enum OnAppearType: Equatable {
  case firstTime
  case tabReappeared
  case retained
}
