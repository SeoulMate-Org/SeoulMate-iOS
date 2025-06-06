import Foundation
import ComposableArchitecture
import ComposableCoreLocation
import Common
import Clients
import Models
import SharedTypes

@Reducer
public struct HomeTabFeature {
  public init() { }
  
  @Dependency(\.locationClient) var locationClient
  @Dependency(\.callengeListClient) var callengeListClient
  @Dependency(\.challengeClient) var challengeClient
  
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable {
    public init() { }
    
    public var onAppearType: OnAppearType = .firstTime
    var userCoordinate: Coordinate?
    
    // Banner
    var bannerState: BannerState?
    var bannerList: [Challenge] = []
    
    // Location
    var locationListType: LocationListType = .none
    var locationList: [Challenge] = []
    
    // Theme
    var loadingThemes: [ChallengeTheme] = [] // ✅ 로딩 중인 테마
    var selectedTheme: ChallengeTheme = .mustSeeSpots
    var themeChallenges: [ChallengeTheme: [Challenge]] = Dictionary(uniqueKeysWithValues: ChallengeTheme.sortedByPriority().map { ($0, []) })
    
    // Missing List
    var missingList: [Challenge] = []
    var challengeList: [Challenge] = []
    
    // Similar List
    var similarAttraction: String = ""
    var similarList: [Challenge] = []
    
    // Rnaking List
    var rankList: [Challenge] = []
  }
  
  public enum LocationListType: Equatable {
    case list
    case loginRequired
    case locationAuthRequired
    case defaultList
    case none
  }
  
  public struct BannerState: Equatable {
    var currentType: BannerType
    var lastUpdated: Date
    
    public enum BannerType: Equatable {
      case seoul
      case cultural
      case none
    }
  }
  
  // MARK: - Action
  
  @CasePathable
  public enum Action: Equatable {
    case initialize
    case refetch
    case networkError
    case showAlert(Alert)
    case tappedChallenge(id: Int)
    case tappedLike(Challenge)
    case updateLikeList(Challenge)
    
    // Banner
    case fetchBannerList
    case fetchSeoulList// 탐방형
    case fetchCulturalList // 참여형
    case updateBannerList(BannerState, [Challenge])
    
    // Location List
    case requestLocation
    case locationResult(LocationResult)
    case updateUserCoordinate(Coordinate?)
    case updateLocationListType(LocationListType)
    
    case fetchLocationList(Coordinate)
    case updateLocationList([Challenge])
    
    // Theme List
    case themeChanged(ChallengeTheme)
    case fetchThemeList(ChallengeTheme)
    case updateThemeList(ChallengeTheme, [Challenge])
    case tappedThemeMore
    case moveToThemeChallenge(ChallengeTheme)
    
    // Missing List
    case fetchMissingList
    case updateMissingList([Challenge])
    case updateChallengeList([Challenge])
    case tappedStart(Int)
    case updateStartList(Int)
    
    // Similar List
    case fetchSimilarList
    case updateSimilarList(String, [Challenge])
    
    // Rnaking List
    case fetchRankList
    case updateRankList([Challenge])
    case tappedRankMore
    case moveToRank
  }
  
  public enum Alert: Equatable {
    case login
    case onLocation
  }
  
  // MARK: - Reducer
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .initialize:
        state.onAppearType = .retained
        let prefetchThemes: [ChallengeTheme] = [.mustSeeSpots, .localTour, .historyCulture]
        return .merge(
          .run { send in
            await send(.requestLocation)
          },
          
            .run { send in
              await send(.fetchBannerList)
            },
          
            .merge(
              prefetchThemes.map { .send(.fetchThemeList($0)) }
            ),
          
            .run { send in
              await send(.fetchMissingList)
            },
          
            .run { send in
              await send(.fetchSimilarList)
            },
          
            .run { send in
              await send(.fetchRankList)
            }
        )
        
      case .refetch:
        state.onAppearType = .retained
        return .merge(
          .run { send in
            await send(.fetchMissingList)
          },
          .run { send in
            await send(.fetchSimilarList)
          }
        )
        
      case let .tappedLike(challenge):
        if TokenManager.shared.isLogin {
          return .run { send in
            
            // 1. 좋아요 UI 즉시 업데이트
            var update = challenge
            update.isLiked.toggle()
            update.likedCount = max(0, update.likes + (update.isLiked ? 1 : -1))
            
            await send(.updateLikeList(update))
            
            do {
              let response = try await challengeClient.putLike(update.id)
              // 필요시 서버 데이터랑 다르면 다시 fetch
              if response.isLiked != update.isLiked {
                let fresh = try await challengeClient.get(response.id)
                await send(.updateLikeList(fresh))
              }
            } catch {
              await send(.networkError)
            }
          }
        } else {
          return .send(.showAlert(.login))
        }
        
      case let .updateLikeList(update):
        replace(&state.bannerList, with: update)
        replace(&state.rankList, with: update)
        replace(&state.themeChallenges, with: update)
        return .none
        
      case .requestLocation:
        return .run { send in
          
          // 1. 권한 요청
          await locationClient.requestAuthorization()
          
          // 2. 권한 상태 확인
          let status = await locationClient.getAuthorizationStatus()
          guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            await send(.locationResult(.fail))
            return
          }
          
          // 3. delegate 연결 (중복 방지를 위해 최초 한 번만)
          _ = await locationClient.startMonitoring()
          
          // 4. 위치 요청
          let result = await locationClient.getCurrentLocation()
          await send(.locationResult(result))
          
        }
        
      case let .locationResult(.success(coordinate)):
        return .run { send in
          await send(.updateUserCoordinate(coordinate))
        }
        
      case .locationResult(.fail):
        return .run { send in
          await send(.updateLocationListType(.locationAuthRequired))
          await send(.updateUserCoordinate(nil))
        }
        
      case let .updateUserCoordinate(coordinate):
        state.userCoordinate = coordinate
        
        if TokenManager.shared.isLogin {
          if let coordinate {
            AppSettingManager.shared.setCoordinate(coordinate)
            return .run { send in
              await send(.fetchLocationList(coordinate))
            }
          } else {
            return .send(.updateLocationListType(.locationAuthRequired))
          }
        } else {
          return .send(.updateLocationListType(.loginRequired))
        }
        
      case let .updateLocationListType(type):
        state.locationListType = type
        
        if state.locationListType != .defaultList ||
            state.locationListType != .list {
          state.locationList = []
        }
        return .none
        
      case let .fetchLocationList(coordinate):
        return .run { send in
          do {
            let result = try await callengeListClient.fetchLocationList(coordinate)
            await send(.updateLocationListType(result.jongGak ? .defaultList : .list))
            await send(.updateLocationList(result.challenges))
          } catch {
            await send(.networkError)
          }
        }
        
      case let .updateLocationList(list):
        state.locationList = list
        return .none
        
        // MARK: - Theme Reducer
      case let .themeChanged(theme):
        state.selectedTheme = theme
        if state.themeChallenges[theme]?.isEmpty == true && !state.loadingThemes.contains(theme) {
          return .send(.fetchThemeList(theme))
        }
        return .none
        
      case let .fetchThemeList(theme):
        state.loadingThemes.append(theme)
        return .run { send in
          do {
            let result = try await callengeListClient.fetchThemeList(theme)
            await send(.updateThemeList(result.0, result.1))
          } catch {
            await send(.networkError)
          }
        }
        
      case let .updateThemeList(theme, list):
        state.loadingThemes.removeAll(where: { $0.id == theme.id })
        state.themeChallenges[theme] = list
        return .none
        
      case .tappedThemeMore:
        return .send(.moveToThemeChallenge(state.selectedTheme))
        
        // MARK: - Missing Reducer
      case .fetchMissingList:
        return .run { send in
          do {
            let (type, list) = try await callengeListClient.fetchMissingList()
            if type == .missed {
              await send(.updateMissingList(list))
            } else if type == .challenge {
              await send(.updateChallengeList(list))
            }
          } catch {
            await send(.networkError)
          }
        }
        
      case let .updateMissingList(list):
        state.challengeList = []
        state.missingList = list
        return .none
        
      case let .updateChallengeList(list):
        state.missingList = []
        state.challengeList = list
        return .none
        
      case let .tappedStart(id):
        if TokenManager.shared.isLogin {
          return .run { send in
            do {
              let response = try await challengeClient.putStatus(id, .progress)
              if response.challengeStatus == .progress {
                await send(.updateStartList(id))
              } else {
                await send(.networkError)
              }
            } catch {
              await send(.networkError)
            }
          }
        } else {
          return .send(.showAlert(.login))
        }
        
      case let .updateStartList(id):
        state.missingList.removeAll(where: { $0.id == id })
        state.challengeList.removeAll(where: { $0.id == id })
        return .none
        
        // MARK: - Similar Reducer
      case .fetchSimilarList:
        return .run { send in
          do {
            let result = try await callengeListClient.fetchSimilarList()
            if let attraction = result.attraction {
              await send(.updateSimilarList(attraction, result.list))
            } else {
              await send(.updateSimilarList("", []))
            }
          } catch {
            await send(.networkError)
          }
        }
        
      case let .updateSimilarList(attraction, list):
        state.similarAttraction = attraction
        state.similarList = list
        return .none
        
        // MARK: - Rank Reducer
      case .fetchRankList:
        return .run { send in
          do {
            let list = try await callengeListClient.fetchRankList()
            await send(.updateRankList(list))
          } catch {
            await send(.networkError)
          }
        }
        
      case let .updateRankList(list):
        state.rankList = list
        return .none
        
      case .tappedRankMore:
        return .send(.moveToRank)
        
      case .networkError:
        // TODO: - Error 처리
        return .none
        
      case .showAlert:
        // Main Tab Navigation
        return .none
        
      case .tappedChallenge:
        // Main Tab Navigation
        return .none
        
      case .fetchBannerList:
        if let bannerState = state.bannerState {
          let now = Date()
          let diff = now.timeIntervalSince(bannerState.lastUpdated)
          if diff >= 300 {
            if bannerState.currentType == .seoul {
              return .send(.fetchCulturalList)
            } else {
              return .send(.fetchSeoulList)
            }
          }
        }
        return .send(.fetchSeoulList)
        
      case .fetchSeoulList:
        return .run { send in
          do {
            let list = try await callengeListClient.fetchSeoulList()
            let bannerState = BannerState(currentType: .seoul, lastUpdated: Date())
            await send(.updateBannerList(bannerState, list))
          } catch {
            await send(.networkError)
          }
        }
        
      case .fetchCulturalList:
        return .run { send in
          do {
            let list = try await callengeListClient.fetchCulturalList()
            let bannerState = BannerState(currentType: .cultural, lastUpdated: Date())
            await send(.updateBannerList(bannerState, list))
          } catch {
            await send(.networkError)
          }
        }
        
      case let .updateBannerList(bannerState, list):
        state.bannerState = bannerState
        state.bannerList = list
        return .none
        
      case .moveToThemeChallenge:
        // Main Tab Navigation
        return .none
        
      case .moveToRank:
        // Main Tab Navigation
        return .none
      }
    }
  }
}

// MARK: - Helper

extension HomeTabFeature {
  func replace(_ list: inout [Challenge], with updated: Challenge) {
    if let index = list.firstIndex(where: { $0.id == updated.id }) {
      list[index] = updated
    }
  }
  
  func replace(_ dict: inout [ChallengeTheme: [Challenge]], with updated: Challenge) {
    for (theme, challenges) in dict {
      if let index = challenges.firstIndex(where: { $0.id == updated.id }) {
        var updatedList = challenges
        updatedList[index] = updated
        dict[theme] = updatedList
      }
    }
  }
}
