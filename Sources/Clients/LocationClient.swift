//
//  LocationClient.swift
//  Clients
//
//  Created by suni on 4/30/25.
//

import Foundation
import ComposableCoreLocation
import Models

public struct LocationClient {
  public var requestAuthorization: @Sendable () async -> Void
  public var startMonitoring: @Sendable () async -> AsyncStream<LocationManager.Action>
  public var getAuthorizationStatus: @Sendable () async -> CLAuthorizationStatus
  public var requestLocation: @Sendable () async -> Void
  public var getCurrentLocation: @Sendable () async -> LocationResult
}

extension LocationClient: DependencyKey {
  public static let liveValue: LocationClient = {
    @Dependency(\.userDefaultsClient) var userDefaultsClient
    
    let manager = LocationManager.live

    return LocationClient(
      requestAuthorization: {
        await manager.requestWhenInUseAuthorization()
      },
      startMonitoring: {
        await manager.delegate()
      },
      getAuthorizationStatus: {
        await manager.authorizationStatus()
        
      },
      requestLocation: {
        await manager.requestLocation()
      },
      getCurrentLocation: {
//        guard !userDefaultsClient.isLocationRequestBlocked else {
//          return .fail
//        }
        
        let status = await manager.authorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
          return .fail
        }

        // 권한이 OK이면 위치 요청 후 delegate에서 받아오기
        await manager.requestLocation()

        for await event in await manager.delegate() {
          switch event {
          case let .didUpdateLocations(locations):
            if let location = locations.first {
              return .success(Coordinate(location.coordinate))
            }
            return .fail
            // FIXME: [TEST] Location
//            return .success(Coordinate(latitude: 37.5708187075358, longitude: 127.008091407146))
          case .didFailWithError:
            return .fail
          default:
            break
          }
        }

        return .fail
      }
    )
  }()
}

extension DependencyValues {
  public var locationClient: LocationClient {
    get { self[LocationClient.self] }
    set { self[LocationClient.self] = newValue }
  }
}

public enum LocationResult: Equatable {
  case success(Coordinate)
  case fail
}
