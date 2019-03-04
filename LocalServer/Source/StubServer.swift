/*
 *	StubServer.swift
 *	EKiPhone
 *
 *	Created by Diney Bomfim on 11/27/18.
 *	Copyright 2018. All rights reserved.
 */

import Foundation

// MARK: - Definitions -

fileprivate extension String {
	
	fileprivate func urlParameters() -> [String : String] {
		
		let clean = replacingOccurrences(of: "+", with: " ")
		guard let string = clean.removingPercentEncoding else { return [:] }
		var parameters = [String: String]()
		
		string.components(separatedBy: "&").forEach {
			let pair = $0.components(separatedBy: "=")
			let value = pair.count == 2 ? pair[1] : ""
			parameters[pair[0]] = value
		}
		
		return parameters
	}
}

public enum HTTPMethod : String, CaseIterable {
	case GET
	case POST
	case DELETE
	case HEAD
	case PUT
	case PATCH
	case TRACE
	case CONNECT
	case OPTIONS
}

public typealias RouteHandler = (_: URLRequest, _: [String: String]) -> StubResponse

public protocol LocalServerDelegate {
	func responseForURLRequest(_ urlRequest: URLRequest) -> StubResponse
}

// MARK: - Type -

public class StubServer : LocalServerDelegate {
	
// MARK: - Properties
	
	fileprivate var routes = [HTTPMethod : Router]()
	
	public static var instance: LocalServerDelegate? {
		didSet {
			exchangeOnce()
		}
	}
	
	public var defaultResponse = StubResponse().withStatusCode(404)

// MARK: - Constructors
	
	public init() { }
	
// MARK: - Protected Methods
	
	fileprivate func addRoute(_ method: HTTPMethod, url: String, handler: @escaping RouteHandler) {
		
		let router = routes[method, default: Router()]
		
		router.addRoute(url, handler: handler)
		routes[method] = router
	}
	
// MARK: - Exposed Methods
	
	public func responseForURLRequest(_ urlRequest: URLRequest) -> StubResponse {
		
		if let rawMethod = urlRequest.httpMethod,
			let method = HTTPMethod(rawValue: rawMethod),
			let router = routes[method],
			let response = router.route(urlRequest) {
			return response
		} else {
			return defaultResponse
		}
	}
	
	public func route(_ methods: [HTTPMethod], url: String, handler: @escaping RouteHandler) {
		methods.forEach {
			addRoute($0, url: url, handler: handler)
		}
	}
}

fileprivate class Router {
	
	fileprivate struct Route {
		
		var pattern: String
		var handler: RouteHandler
		
		func matchesRoute(_ url: URL) -> Bool {
			return url.absoluteString.contains(pattern) ||
				url.absoluteString.range(of: pattern, options: .regularExpression) != nil
		}
	}
	
// MARK: - Properties
	
	fileprivate var routes: [Route] = []
	
// MARK: - Protected Methods
	
	fileprivate func route(_ urlRequest: URLRequest) -> StubResponse? {
		
		let url = urlRequest.url!
		let queryParams = url.query?.urlParameters() ?? [String: String]()
		let fragmentParams = url.fragment?.urlParameters() ?? [String: String]()
		
		for route in routes {
			if route.matchesRoute(url) {
				let allParameters = queryParams.merging(fragmentParams) { (current, _) in current }
				return route.handler(urlRequest, allParameters)
			}
		}
		
		return nil
	}
	
	fileprivate func addRoute(_ pattern: String, handler: @escaping RouteHandler) {
		routes.append(Route(pattern: pattern, handler: handler))
	}
}
