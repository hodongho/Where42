//
//  ToolBarView.swift
//  Where42
//
//  Created by 현동호 on 11/6/23.
//

import SwiftUI

struct Where42ToolBarContent: ToolbarContent {
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var homeViewModel: HomeViewModel

    @Binding var isShowSheet: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                mainViewModel.tabSelection = "Home"
                mainViewModel.isSelectViewPrsented = false
                homeViewModel.inputText = ""
            } label: {
                Image("Where42 logo 3")
            }
            .disabled(mainViewModel.isDeleteGroupAlertPrsented || mainViewModel.isNewGroupAlertPrsented || mainViewModel.isEditGroupNameAlertPrsented ||
                homeViewModel.isGroupEditSelectAlertPrsented)
        }

        if mainViewModel.tabSelection == "Home" {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowSheet.toggle() } label: { Image("Setting icon M") }
                    .sheet(isPresented: $isShowSheet) {
                        SettingView()
                    }
                    .disabled(mainViewModel.isDeleteGroupAlertPrsented || mainViewModel.isNewGroupAlertPrsented || mainViewModel.isEditGroupNameAlertPrsented ||
                        homeViewModel.isGroupEditSelectAlertPrsented)
//                NavigationLink(destination: SettingView(), label: { Image("Setting icon M") })
            }
        }
    }
}
