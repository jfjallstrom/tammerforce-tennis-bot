//
//  EchoBot.swift
//  EchoBot
//
//  Created by Givi Pataridze on 31.05.2018.
//

import Foundation
import Telegrammer
import Vapor

final class SignupBot: ServiceType {
    
    let bot: Bot
    var updater: Updater?
    var dispatcher: Dispatcher?
    var cleared = Date()
    
    var signups = [User]()
    
    ///Conformance to `ServiceType` protocol, fabric methhod
    static func makeService(for worker: Container) throws -> SignupBot {
        guard let token = Environment.get("TELEGRAM_BOT_TOKEN") else {
            throw CoreError(identifier: "Enviroment variables", reason: "Cannot find telegram bot token")
        }
        
        let settings = Bot.Settings(token: token, debugMode: true)
        return try SignupBot(settings: settings)
    }
    
    init(settings: Bot.Settings) throws {
        self.bot = try Bot(settings: settings)
        let dispatcher = try configureDispatcher()
        self.dispatcher = dispatcher
        self.updater = Updater(bot: bot, dispatcher: dispatcher)
    }
    
    /// Initializing dispatcher, object that receive updates from Updater
    /// and pass them throught handlers pipeline
    func configureDispatcher() throws -> Dispatcher {
        ///Dispatcher - handle all incoming messages
        let dispatcher = Dispatcher(bot: bot)

        let commandHandler = CommandHandler(commands: ["/commands", "/help"], callback: commands)
        dispatcher.add(handler: commandHandler)
        
        let signupHandler = CommandHandler(commands: ["/signup"], callback: signUp)
        dispatcher.add(handler: signupHandler)
        
        let cancelHandler = CommandHandler(commands: ["/cancel"], callback: cancel)
        dispatcher.add(handler: cancelHandler)
        
        let whoHandler = CommandHandler(commands: ["/who"], callback: who)
        dispatcher.add(handler: whoHandler)

        return dispatcher
    }
}

extension SignupBot {
    func signUp(_ update: Update, _context: BotContext?) throws {
        clearIfNeeded()
        guard let message = update.message, let user = message.from else { return }
        var reply = ""
        if signups.count >= 4 {
            reply = "Already full"
        } else if signups.contains(user) {
            reply = "Already signed up"
        } else {
            signups.append(user)
            reply = "Thank!"
        }
        let params = Bot.SendMessageParams(chatId: .chat(message.chat.id), text: reply)
        try bot.sendMessage(params: params)
    }
    
    func cancel(_ update: Update, _context: BotContext?) throws {
        guard let message = update.message, let user = message.from else { return }
        var reply = ""
        if signups.contains(user) {
            signups.removeAll{ $0 == user }
            reply = "Quitter!"
        } else {
            reply = "At least sign up first"
        }
        let params = Bot.SendMessageParams(chatId: .chat(message.chat.id), text: reply)
        try bot.sendMessage(params: params)
    }
    
    func who(_ update: Update, _context: BotContext?) throws {
        clearIfNeeded()
        guard let message = update.message else { return }
        let attendees = signups.map{ $0.firstName }.joined(separator: ", ")
        let params = Bot.SendMessageParams(chatId: .chat(message.chat.id), text: "Currently signed up: \(attendees)")
        try bot.sendMessage(params: params)
    }
    
    func commands(_ update: Update, _context: BotContext?) throws {
        guard let message = update.message else { return }
        let reply =
        """
        Commands:
            /signup Right thing to do!
            /cancel Only for losers :(
            /who    Check who's coming
        """
        let params = Bot.SendMessageParams(chatId: .chat(message.chat.id), text: reply)
        try bot.sendMessage(params: params)
    }
    
    func clearIfNeeded() {
        let cal = Calendar.current
        let components = DateComponents(calendar: cal, weekday: 4)
        guard let nextWednesday = cal.nextDate(after: cleared, matching: components, matchingPolicy: .nextTime) else { return }
        if nextWednesday.timeIntervalSince(cleared) >= 7 * 24 * 60 * 60 {
            signups.removeAll()
            cleared = Date()
        }
    }
}
