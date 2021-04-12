//
//  _9_GameApp.swift
//  99_Game
//
//  Created by User07 on 2021/3/22.
//

import SwiftUI

@main
struct _9_GameApp: App {
    var body: some Scene {
        let game=Game()
        WindowGroup {
            ContentView(game:game, player:game.player)
        }
    }
}
