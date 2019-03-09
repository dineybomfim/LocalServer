/*
 *	UserService.swift
 *	LocalServer
 *
 *	Created by Diney Bomfim on 3/9/19.
 *	Copyright 2019 Emirates Group. All rights reserved.
 */

import Foundation
import LocalServer

// MARK: - Definitions -

enum UserType : String {
	case male
	case female
	
	var file: String {
		return rawValue
	}
}

// MARK: - Type -

final class UserService {
	
// MARK: - Exposed Methods
	
	static func single(_ type: UserType) {
		UITestResponse(filename: "user_\(type.file)", ofType: "json", bundle: .uiTest)
			.send(to: "randomuser.me/api/")
		
		UITestResponse(filename: "10", ofType: "jpg", bundle: .uiTest)
			.withHeaders(["Content-type" : "image"])
			.send(to: "10.jpg")
		
		UITestResponse(filename: "14", ofType: "jpg", bundle: .uiTest)
			.withHeaders(["Content-type" : "image"])
			.send(to: "14.jpg")
	}
	
	static func statefulSequence(_ types: [UserType]) {
		types.enumerated().forEach {
			var response = UITestResponse(filename: "user_\($1.file)", ofType: "json", bundle: .uiTest)
			
			switch $0 + 1 {
			case 1:
				response = response.willSetStateTo("\($0 + 1)")
			case 2..<types.count:
				response = response.whenStateIs("\($0)").willSetStateTo("\($0 + 1)")
			default:
				response = response.whenStateIs("\($0)")
			}
			
			response.send(to: "randomuser.me/api/")
		}
	}

// MARK: - Overridden Methods

}