//
//  HomeView.swift
//  Where42
//
//  Created by 현동호 on 10/28/23.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    var body: some View {
        ZStack {
            VStack {
                Button("access 초기화") {
                    homeViewModel.resetAccesstoken()
                }
                Button("access 만료") {
                    homeViewModel.expireAccesstoken()
                }
                Button("refresh 초기화") {
                    homeViewModel.resetRefreshtoken()
                }
                Button("refresh 만료") {
                    homeViewModel.expireRefreshtoken()
                }
//                Button("search") {
//                    Task {
//                        await homeViewModel.searchMemeber()
//                    }
//                }

                HomeInfoView(
                    memberInfo: $homeViewModel.myInfo,
                    isWork: $homeViewModel.isWorkCheked,
                    isNewGroupAlertPrsent: $mainViewModel.isNewGroupAlertPrsented
                )
                        
                Divider()
                    
                ScrollView {
                    HomeGroupView(groups: $homeViewModel.myGroups)
                            
                    Spacer()
                }
                .refreshable {
                    Task {
                        if await homeViewModel.reissue() {
                            await homeViewModel.getMemberInfo()
                            await homeViewModel.getGroup()
                        }
                    }
                }
            }
            .redacted(reason: homeViewModel.isLoading ? .placeholder : [])
            .disabled(homeViewModel.isLoading)
                
            .task {
                if mainViewModel.isLogin {
                    if await homeViewModel.reissue() {
                        if !homeViewModel.isAPILoaded {
                            await homeViewModel.getMemberInfo()
                            await homeViewModel.getGroup()
                            if mainViewModel.isLogin == true {
                                homeViewModel.isAPILoaded = true
                            }
                            homeViewModel.countAllMembers()
                            homeViewModel.isLoading = false
                        }
                    }
                }
            }
            
            if homeViewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(.circular)
            }
        }
        .sheet(isPresented: $homeViewModel.isGroupMemberDeleteViewPrsented) {
            GroupMemberDeleteView(
                group: $homeViewModel.selectedGroup,
                isGroupEditModalPresented: $homeViewModel.isGroupEditSelectAlertPrsented
            )
        }
        .sheet(isPresented: $homeViewModel.isGroupMemberAddViewPrsented) {
            GroupMemberAddView(
                group: $homeViewModel.notInGroup,
                isGroupEditModalPresented: $homeViewModel.isGroupEditSelectAlertPrsented
            )
        }
        .fullScreenCover(isPresented: $mainViewModel.isSelectViewPrsented) {
            SelectingView()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(MainViewModel.shared)
        .environmentObject(HomeViewModel())
}
