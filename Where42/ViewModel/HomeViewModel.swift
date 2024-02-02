//
//  HomeViewModel.swift
//  Where42
//
//  Created by 현동호 on 11/8/23.
//

import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var isShowSettingSheet = false
    @Published var isGroupEditSelectAlertPrsented = false
    @Published var isGroupMemberDeleteViewPrsented = false
    @Published var isGroupMemberAddViewPrsented = false
    @Published var isFriendDeleteAlertPresented = false
    @Published var isShow42IntraSheet = false
    @Published var isShowAgreementSheet = false
    @Published var isWork = false
    @Published var isLoading = true
    @Published var inputText = ""
    @Published var intraURL: String? = ""
    @Published var isAPILoaded = false
    @Published var isLogout = false
    @Published var isFriend = false
    @Published var viewPresentCount = 0

    @Published var selectedUser: MemberInfo = .empty
    @Published var selectedUsers: [MemberInfo] = []
    @Published var selectedGroup: GroupInfo = .empty

    @Published var newGroup: GroupInfo = .empty

    @Published var intraId: Int = 99760
    @Published var myInfo: MemberInfo = .empty

    @Published var groups: [GroupInfo] = [.empty, .empty]
    @Published var notInGroups: GroupInfo = .init(id: UUID(), groupName: "not in group", members: [.empty])

    @Published var friends: GroupInfo = .empty

    @AppStorage("isLogin") var isLogin = false

    private let memberAPI = MemberAPI()
    private let groupAPI = GroupAPI()

    // Count

    func countOnlineUsers() {
        countFriendUsers()
        countAllGroupUsers()
    }

    func countAllGroupUsers() {
        for index in groups.indices {
            groups[index].totalNum = groups[index].members.count
            groups[index].onlineNum = 0
            groups[index].members.forEach { user in
                if user.location != "퇴근" {
                    groups[index].onlineNum += 1
                }
            }
        }
    }

    func countGroupUsers(group: inout GroupInfo) {
        group.totalNum = group.members.count
        group.onlineNum = 0
        group.members.forEach { user in
            if user.location != "퇴근" {
                group.onlineNum += 1
            }
        }
    }

    func countFriendUsers() {
        friends.totalNum = friends.members.count
        friends.onlineNum = 0
        friends.members.forEach { user in
            if user.location != "퇴근" {
                friends.onlineNum += 1
            }
        }
    }

    // User

    func getMemberInfo() {
        Task {
            do {
                let (memberInfo, url) = try await memberAPI.getMemberInfo(intraId: self.intraId)
                if url != nil {
                    DispatchQueue.main.async {
                        self.intraURL = url
                        self.isShow42IntraSheet = true
                    }
                } else {
                    DispatchQueue.main.async {
                        if memberInfo != nil {
                            self.myInfo = memberInfo!
                            self.isLogin = true
                        } else {
                            self.isLogin = false
                        }
                    }
                }
            } catch {
                print("Error getUserInfo: \(error)")
            }
        }
    }

    // Group

    func initNewGroup() {
        inputText = ""
        selectedUsers = []
        newGroup = GroupInfo(id: UUID(), groupName: "", totalNum: 0, onlineNum: 0, isOpen: false, members: [])
    }

    func getGroup() {
        Task {
            do {
                let responseGroups = try await groupAPI.getGroup()
                DispatchQueue.main.async {
//                    print(responseGroups[0].members)
                    if let responseGroups = responseGroups {
                        self.groups = responseGroups
                        self.friends = self.groups[responseGroups.firstIndex(
                            where: { $0.groupName == "default" }
                        )!]
                        self.friends.groupName = "친구목록"
                        self.friends.isOpen = true

                        self.countOnlineUsers()
                    } else {
                        self.intraURL = "http://13.209.149.15:8080/v3/member?intraId=99760"
                        self.isShow42IntraSheet = true
                    }
                }
            } catch {
                print("Error getGroup: \(error)")
            }
        }
    }

    func createNewGroup(intraId: Int) async {
        DispatchQueue.main.async {
            self.newGroup.members = self.selectedUsers
            self.countGroupUsers(group: &self.newGroup)
            self.groups.append(self.newGroup)
        }

        let groupId = try? await groupAPI.createGroup(groupName: newGroup.groupName)

        if groupId != nil && selectedUsers.isEmpty == false {
            await addMemberInGroup(groupId: groupId!)
        } else if groupId == nil {
            DispatchQueue.main.async {
                self.intraURL = "http://13.209.149.15:8080/v3/member?intraId=99760"
                self.isShow42IntraSheet = true
            }
        }

        DispatchQueue.main.async {
            self.initNewGroup()
        }
        getGroup()
    }

    func addMemberInGroup(groupId: Int) async {
        DispatchQueue.main.async {
            if let selectedIndex = self.groups.firstIndex(where: { $0.groupId == groupId }) {
                self.groups[selectedIndex].members += self.selectedUsers
                self.countAllGroupUsers()
            }
        }

        do {
            let response = try await groupAPI.addMembers(groupId: groupId, members: selectedUsers)
            if response == false {
                DispatchQueue.main.async {
                    self.intraURL = "http://13.209.149.15:8080/v3/member?intraId=99760"
                    self.isShow42IntraSheet = true
                }
            }
        } catch {
            print("Failed to create new group")
        }
    }

    func confirmGroupName(isNewGroupAlertPrsented: Binding<Bool>, isSelectViewPrsented: Binding<Bool>) -> String? {
        print("confirm")
        if inputText == "" || inputText.trimmingCharacters(in: .whitespaces) == "" {
            return "wrong"
        } else if inputText.count > 40 {
            return "long"
        }

        let duplicateName: Int? = groups.firstIndex(where: { $0.groupName == inputText })

        if duplicateName != nil {
            return "duplicate"
        }

        newGroup.groupName = inputText
        isNewGroupAlertPrsented.wrappedValue = false
        isSelectViewPrsented.wrappedValue = true
        return nil
    }

    func getNotInGroupMember() async {
        do {
            guard let response = try await groupAPI.getNotInGorupMember(groupId: selectedGroup.groupId!) else {
                DispatchQueue.main.async {
                    self.intraURL = "http://13.209.149.15:8080/v3/member?intraId=99760"
                    self.isShow42IntraSheet = true
                }
                return
            }

            DispatchQueue.main.async {
//                print(response)
                self.notInGroups.members = response
            }
        } catch {}
    }

    func deleteUserInGroup() async {
        do {
            let response = try await groupAPI.deleteGroupMember(groupId: selectedGroup.groupId!, members: selectedUsers)
            if response == false {
                DispatchQueue.main.async {
                    self.intraURL = "http://13.209.149.15:8080/v3/member?intraId=99760"
                    self.isShow42IntraSheet = true
                }
                return
            }

            DispatchQueue.main.async {
                if self.selectedGroup.groupName == "친구목록" {
                    withAnimation {
                        self.friends.members = self.selectedGroup.members.filter { member in
                            !self.selectedUsers.contains(where: { $0.intraId == member.intraId })
                        }
                    }
                } else {
                    let selectedIndex = self.groups.firstIndex(where: {
                        $0.groupName == self.selectedGroup.groupName
                    })

                    withAnimation {
                        self.groups[selectedIndex!].members = self.selectedGroup.members.filter { member in
                            !self.selectedUsers.contains(where: { $0.intraId == member.intraId })
                        }
                    }
                }

                self.initNewGroup()
                self.countOnlineUsers()
            }
        } catch {
            print("Failed delete group member")
        }
    }

    func editGroupName() async -> String? {
        if inputText == "" {
            return "wrong"
        } else if inputText.count > 40 {
            return "long"
        }

        for index in groups.indices {
            if groups[index] == selectedGroup {
                DispatchQueue.main.async {
                    self.groups[index].groupName = self.inputText
                }

                if await updateGroupName(groupId: groups[index].groupId!, newGroupName: inputText) {
                    DispatchQueue.main.async {
                        self.inputText = ""
                        self.selectedGroup = .empty
                    }
                }
            }
        }
        return nil
    }

    func updateGroupName(groupId: Int, newGroupName: String) async -> Bool {
        do {
            guard let _ = try await groupAPI.updateGroupName(groupId: groupId, newGroupName: newGroupName) else {
                DispatchQueue.main.async {
                    self.intraURL = "http://13.209.149.15:8080/v3/member?intraId=99760"
                    self.isShow42IntraSheet = true
                }
                return false
            }
            return true
        } catch {
            return false
        }
    }

    func deleteGroup() async -> Bool {
        for index in groups.indices {
            if groups[index] == selectedGroup {
                do {
                    if try await groupAPI.deleteGroup(
                        groupId: groups[index].groupId!
                    ) {
                        withAnimation {
                            DispatchQueue.main.async {
                                self.groups.remove(at: index)
                            }
                        }
                        return true
                    } else {
                        DispatchQueue.main.async {
                            self.intraURL = "http://13.209.149.15:8080/v3/member?intraId=99760"
                            self.isShow42IntraSheet = true
                        }
                        return false
                    }
                } catch {
                    return false
                }
            }
        }
        return false
    }
}
