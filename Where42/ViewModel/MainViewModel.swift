//
//  MainViewModel.swift
//  Where42
//
//  Created by 현동호 on 11/9/23.
//

import SwiftUI

extension UIDevice {
    static var idiom: UIUserInterfaceIdiom {
        UIDevice.current.userInterfaceIdiom
    }
}

class MainViewModel: ObservableObject {
    static let shared = MainViewModel()

//    private init() {}

    @AppStorage("isLogin") var isLogin = false
    @AppStorage("isLogout") var isLogout = true

    @Published var tabSelection: String = "Home"

    @Published var isSelectViewPrsented = false
    @Published var isPersonalViewPrsented = false
    @Published var isNewGroupAlertPrsented = false
    @Published var isEditGroupNameAlertPrsented = false
    @Published var isDeleteGroupAlertPrsented = false

    let intraURL: String = "http://13.209.149.15:8080/v3/member?intraId=99760"
    @Published var is42IntraSheetPresented = false

    @Published var toast: Toast? = nil

    func setToast(type: String?) {
        DispatchQueue.main.async {
            switch type {
            case "wrongGroupName":
                self.toast = Toast(title: "잘못된 그룹 이름 형식입니다")
            case "longGroupName":
                self.toast = Toast(title: "그룹 이름이 너무 깁니다")
            case "duplicateGroupName":
                self.toast = Toast(title: "이미 존재하는 그룹 이름입니다")
            case "wrongComment":
                self.toast = Toast(title: "잘못된 코멘트 형식입니다")
            case "longComment":
                self.toast = Toast(title: "코멘트가 너무 깁니다")
            case "reissue":
                self.toast = Toast(title: "잠시 후 다시 시도해 주세요")
            default:
                return
            }
        }
    }
}
