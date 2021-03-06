//
//  ContentView.swift
//  99_Game
//
//  Created by User07 on 2021/3/22.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject var game:Game
    @StateObject var player:Player
    @State private var gameStart=false
    @State private var result=true
    @State private var showAlert = false
    @State private var PreviousCard=Image(systemName: "photo")
    @State private var isPresented = false
    @State private var GameOver=false
    @State private var activeAlert: ActiveAlert = .first
    @State private var BackgroundMusic=false
    @State private var BargainingChip:Int=100
    @State private var npcCardY=[0, 0, 0, 0, 0]
    @State private var back:[Image]=[Image("back"), Image("back"), Image("back"), Image("back"), Image("back")]
    @State private var showBack=[true, true, true, true, true]
    var timer: Timer?
    let musicPlayer=AVPlayer()
    @State private var PlayerNum=2
    @State private var cardOpacity:Double=1.0
    @State private var showingActionSheet=false
    @State private var assignPlayer=false
    @State private var moneyY=UIScreen.main.bounds.height-200
    func npcAction()->Void{ //換電腦出牌，延遲0.5秒再做
        if !assignPlayer {
            if game.direction {
                game.turn=1
            }else{
                game.turn=game.npcNum
            }
        }else{
            assignPlayer=false
        }
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            if game.turn==0 {
                cardOpacity=1
                timer.invalidate()
                return
            }
            var revolve=false
            let temp = game.npc[game.turn-1].PlayACard()
            //隨機選一張牌，使牌上升（動畫）
            let r=Int.random(in: 0..<5)
            npcCardY[r] = -20
            let time2:TimeInterval = 0.3
            DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + time2) {
                //使該牌消失
                showBack[r]=false
                DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + time2) {
                    //補充一張牌
                    npcCardY[r]=0
                    showBack[r]=true
                    game.cardDeck.AddToDiscard(card: temp)
                    PreviousCard=Image("\(temp.rank)\(temp.suit)")
                    //加減分數
                    switch temp.rank{
                    case "A":
                        if temp.suit=="♠" {
                            result=game.SetScores(scores: 0)
                        }else{
                            result=game.SetScores(scores: game.totalscores+1)
                        }
                    case "2", "3", "6", "7", "8", "9":
                        result=game.SetScores(scores: game.totalscores+(Int(temp.rank) ?? 0))
                    case "4":   //迴轉
                        print("迴轉")
                        game.direction.toggle()
                        revolve=true
                    case "5":   //指定，指定下一個人
                        print("指定")
                    case "10":  //加/減10
                        if game.totalscores-10>=0 {
                            result=game.SetScores(scores: game.totalscores-10)
                        }else{
                            result=game.SetScores(scores: game.totalscores+10)
                        }
                    case "J":   //pass
                        print("pass")
                    case "Q":   //加/減20
                        if game.totalscores-20>=0 {
                            result=game.SetScores(scores: game.totalscores-20)
                        }else{
                            result=game.SetScores(scores: game.totalscores+20)
                        }
                    case "K":   //scores維持在99
                        result=game.SetScores(scores: 99)
                    default:
                        print("??")
                    }
                    //再抽一張牌
                    let temp2 = game.cardDeck.Draw()
                    //加入手牌中
                    if(game.turn==0)
                    {
                        game.npc[0].AddToHandCards(card: temp2)
                        
                    }
                    else{
                        game.npc[game.turn-1].AddToHandCards(card: temp2)
                    }
                    if result==false {
                        isPresented=true
                        timer.invalidate()
                        return
                    }
                    if revolve {
                        if game.direction {
                            game.turn+=1
                        }else{
                            game.turn-=1
                        }
                    }else{
                        if game.direction {  //順時針
                            if game.turn>=game.npcNum {
                                game.turn=0
                            }else{
                                game.turn+=1
                            }
                        }else{  //逆時針
                            if game.turn<=1 {
                                game.turn=0
                            }else{
                                game.turn-=1
                            }
                        }
                    }
                }
            }
        }
    }
    func generateActionSheet(options: Int) -> ActionSheet { //產生動態數量的Button
        var buttons:[ActionSheet.Button]=[]
        for i in 0..<options {
            buttons.append(Alert.Button.default(Text("Player \(i+1)"), action: { game.turn=i+1; assignPlayer=true;  npcAction()}))
        }
        return ActionSheet(title: Text("Select a player"),
                   buttons: buttons )
    }
    var body: some View {
            ZStack{
                Spacer()
                if gameStart==false{
                    VStack{
                        Spacer()
                        Image("99")
                            .resizable()
                            .frame(height:100)
                            .scaledToFit()
                        Spacer()
                        HStack(spacing:20){
                            
                            Button(action:{
                                gameStart=true
                                PreviousCard=Image("back")
                                //設定人數
                                game.npcNum=PlayerNum-1
                                game.PlayAgain()
                            }){
                                Text("開始遊戲").foregroundColor(.white).font(.title)
                            }
                            .padding(.all,10)
                            .background(Capsule().foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/))
                            
                            Link(destination: URL(string: "https://yonglincku.pixnet.net/blog/post/17194087")!, label: {
                                
                                                        
                                Text("規則說明").foregroundColor(.white).font(.title)
                                                    }).padding(.all,10)
                            .background(Capsule().foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/))

                        }
                        Spacer()
                    }
                    .onAppear()
                    
                }else{
                    if GameOver==false{
                        VStack{
                            Spacer()
                                ZStack{
                                    ForEach(game.npc[0].handCards.indices){ (index) in
                                        if showBack[index] {
                                            back[index]
                                                .resizable()
                                                .frame(width:100, height:150)
                                                .scaledToFit()
                                                .offset(x:CGFloat(((index-1)*20)), y:CGFloat(npcCardY[index]))
                                        }else{
                                            back[index]
                                                .resizable()
                                                .frame(width:100, height:150)
                                                .scaledToFit()
                                                .offset(x:0, y:CGFloat(npcCardY[index]))
                                                .hidden()
                                        }
                                    }
                                }
                                .padding(.trailing,40)
                                .animation(.easeOut(duration:0.5))
                            HStack{
                                Spacer().frame(width:80)
                                VStack{
                                    PreviousCard
                                        .resizable()
                                        .frame(width:100, height:150)
                                        .scaledToFit()
                                }
                                VStack{
                                    //turn
                                    Text("回合: 玩家 \(game.turn)")
                                        .foregroundColor(Color("FontColor"))
                                    Text("目前加總: \(game.totalscores)")
                                        .foregroundColor(Color("FontColor"))
                                    Text("籌碼: \(BargainingChip)")
                                        .foregroundColor(Color("FontColor"))
                                }
                            }
                            
                            HStack{
                                ForEach(game.player.handCards.indices){(index) in
                                    Button(action:{
                                        game.turn=0
                                        //加進棄牌區
                                        let temp3=game.player.handCards[index]
                                        game.cardDeck.AddToDiscard(card: temp3)
                                        PreviousCard=Image("\(temp3.rank)\(temp3.suit)")
                                        //從手牌中移除
                                        game.player.RemoveFromHandCards(card: temp3)
                                        //加減分數
                                        switch temp3.rank{
                                        case "A":
                                            if temp3.suit=="♠" {
                                                result=game.SetScores(scores: 0)
                                            }else{
                                                result=game.SetScores(scores: game.totalscores+1)
                                            }
                                            if result==false {  //不能移出SWITCH CASE，不然10/Q會出錯
                                                isPresented=true
                                            }else {
                                                npcAction()
                                            }
                                        case "2", "3", "6", "7", "8", "9":
                                            result=game.SetScores(scores: game.totalscores+(Int(temp3.rank) ?? 0))
                                            if result==false {
                                                isPresented=true
                                            }else {
                                                npcAction()
                                            }
                                        case "4":   //迴轉
                                            print("迴轉")
                                            game.direction.toggle()
                                            npcAction()
                                        case "5":   //指定
                                            print("指定")
                                            showingActionSheet=true
                                        case "10":  //加/減10
                                            if game.totalscores-10>=0{
                                                showAlert = true
                                                activeAlert = .first
                                            }else{
                                                result=game.SetScores(scores: game.totalscores+10)
                                                if result==false {
                                                    isPresented=true
                                                }else {
                                                    npcAction()
                                                }
                                            }
                                        case "J":   //pass
                                            print("pass")
                                            if result==false {
                                                isPresented=true
                                            }else {
                                                npcAction()
                                            }
                                        case "Q":   //加/減20
                                            if game.totalscores-20>=0{
                                                showAlert = true
                                                activeAlert = .second
                                            }else{
                                                result=game.SetScores(scores: game.totalscores+20)
                                                if result==false {
                                                    isPresented=true
                                                }else {
                                                    npcAction()
                                                }
                                            }
                                        case "K":   //scores維持在99
                                            result=game.SetScores(scores: 99)
                                            if result==false {
                                                isPresented=true
                                            }else {
                                                npcAction()
                                            }
                                        default:
                                            print("??")
                                        }
                                        //再抽一張牌
                                        let temp = game.cardDeck.Draw()
                                        //加入手牌中
                                        game.player.AddToHandCards(card: temp)
                                        //手牌變半透明
                                        cardOpacity=0.5
                                    }){
                                        //Player手牌
                                        PokerView(game:game, index:index)
                                            .opacity(cardOpacity)
                                    }
                                    .alert(isPresented: $showAlert, content: {
                                        switch activeAlert {
                                        case .first:
                                            return Alert(
                                                        title: Text("Choose an action"),
                                                        message: Text("Plus 10 or substract 10?"),
                                                        primaryButton: .destructive(Text("Plus")) {
                                                            result=game.SetScores(scores: game.totalscores+10)
                                                            if result==false {
                                                                isPresented=true
                                                            }else {
                                                                npcAction()
                                                            }
                                                        },
                                                        secondaryButton: .destructive(Text("Substract")) {
                                                            result=game.SetScores(scores: game.totalscores-10)
                                                            if result==false {
                                                                isPresented=true
                                                            }else {
                                                                npcAction()
                                                            }
                                                        }
                                                    )
                                        case .second:
                                            return Alert(
                                                        title: Text("Choose an action"),
                                                        message: Text("Plus 20 or substract 20?"),
                                                        primaryButton: .destructive(Text("Plus")) {
                                                            result=game.SetScores(scores: game.totalscores+20)
                                                            if result==false {
                                                                isPresented=true
                                                            }else {
                                                                npcAction()
                                                            }
                                                        },
                                                        secondaryButton: .destructive(Text("Substract")) {
                                                            result=game.SetScores(scores: game.totalscores-20)
                                                            if result==false {
                                                                isPresented=true
                                                            }else {
                                                                npcAction()
                                                            }
                                                        }
                                                )
                                        }
                                    })
                                    .sheet(isPresented: $isPresented){
                                        ResultView(isPresented:$isPresented, turn: game.turn, BargainingChip: $BargainingChip, game:game, GameOver:$GameOver, PreviousCard:$PreviousCard, result:$result, cardOpacity:$cardOpacity)
                                    }
                                    .actionSheet(isPresented: $showingActionSheet, content:{
                                        generateActionSheet(options:game.npcNum)
                                    })
                                }
                            }
                            Spacer()
                        }
                    }else{  //遊戲結束
                        ZStack{
                            VStack(spacing:20){
                                Text("Game Over")
                                    .foregroundColor(Color("FontColor"))
                                    .font(.system(size:30))
                                Button(action:{
                                    game.PlayAgain()
                                    result=true
                                    gameStart=false
                                    BargainingChip=100
                                    GameOver=false
                                    PreviousCard=Image(systemName: "photo")
                                    isPresented=false
                                    cardOpacity=1
                                }){
                                    ButtonView(text:"Reset", size:30)
                                }
                            }
                        }
                        Image("bankrupt")
                            .resizable()
                            .frame(height:200)
                            .scaledToFit()
                            .position(x:UIScreen.main.bounds.width/2+100, y:UIScreen.main.bounds.height-200)
                        Image("money")
                            .resizable()
                            .frame(height:200)
                            .scaledToFit()
                            .position(x:UIScreen.main.bounds.width/2+100, y:moneyY)
                            .onAppear {
                                let baseAnimation = Animation.easeIn(duration: 1)
                                let repeated = baseAnimation.repeatForever(autoreverses:false)
                                withAnimation(repeated) {
                                    moneyY=0
                                }
                            }
                    }
                }
                Spacer()
            }.background(Image("poker").resizable()                          .ignoresSafeArea())
        
        }
        
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let game=Game()
        ContentView(game:game, player:game.player)
            .previewLayout(.fixed(width: 414, height: 896))
    }
}

struct ResultView: View {
    @Binding var isPresented:Bool
    let turn: Int
    @Binding var BargainingChip:Int
    var game:Game
    @Binding var GameOver:Bool
    @Binding var PreviousCard:Image
    @Binding var result:Bool
    @Binding var cardOpacity:Double
    var body: some View {
        VStack(spacing:20){
            if turn==0 {
                Text("Lose")
                    .fontWeight(.bold)
                    .font(.system(size:30))
            }else{
                Text("Win")
                    .fontWeight(.bold)
                    .font(.system(size:30))
            }
            Button(action:{
                if turn==0 {
                    BargainingChip-=10
                }else{
                    BargainingChip+=10
                }
                if BargainingChip<=0 {
                    GameOver=true
                }
                result=true
                game.PlayAgain()
                PreviousCard=Image("back")
                isPresented=false
                cardOpacity=1
            }){
                ButtonView(text:"Play Again", size:30)
            }
        }
    }
}

enum ActiveAlert {
    case first, second
}


struct PokerView: View {
    @StateObject var game:Game
    let index:Int
    var body: some View {
        Image("\(game.player.handCards[index].rank)\(game.player.handCards[index].suit)")
            .resizable()
            .frame(height:150)
            .scaledToFit()
    }
}

struct ButtonView: View {
    let text:String
    let size:CGFloat
    var body: some View {
        Text(text)
            .fontWeight(.bold)
            .font(.system(size:size))
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(5)
            .background(Color.blue)
            .cornerRadius(10)
            .foregroundColor(.white)
            .padding(5)
            
    }
}

