import Foundation

/// Short discipline / gym lines, rotated once per day by day-of-year.
enum Quotes {
    static let all: [String] = [
        "Discipline is choosing what you want most over what you want now.",
        "Abs are built in the kitchen, revealed in the gym.",
        "The pain you feel today is the strength you feel tomorrow.",
        "You don't have to be extreme, just consistent.",
        "Sweat is just fat crying.",
        "Don't count the days, make the days count.",
        "Your body can stand almost anything — it's your mind you have to convince.",
        "Small steps every day add up to big results.",
        "Closing both rings is a promise you keep to yourself.",
        "Motivation gets you started, habit keeps you going.",
        "Be stronger than your strongest excuse.",
        "One workout at a time, one day at a time.",
        "The only bad workout is the one that didn't happen.",
        "Push yourself, because no one else is going to do it for you.",
        "Results happen over time, not overnight.",
        "Train insane or remain the same.",
        "A one-hour workout is 4% of your day. No excuses.",
        "Fall in love with taking care of your body.",
        "What seems hard now will one day be your warm-up.",
        "Success starts with self-discipline.",
        "Wake up. Work out. Look hot. Kick ass.",
        "Strive for progress, not perfection.",
        "Your future self is watching you right now through memories.",
        "Earn your body. Earn the day.",
        "The hardest lift of all is lifting yourself off the couch.",
        "Consistency beats intensity.",
        "Make your rings close before they close on you.",
        "Today's effort is tomorrow's six-pack.",
        "Comfort is the enemy of progress.",
        "You won't always be motivated, so learn to be disciplined.",
    ]

    static var today: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return all[(day - 1) % all.count]
    }
}
