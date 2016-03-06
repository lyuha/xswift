
private extension String {
    
    func split(input: String)->[String] {
        return self.componentsSeparatedByString(input)
        // self.characters.split(" ").map{ String($0) }
    }
    // Returns the Rank part of the card
    func head()->String{
        return self.substringToIndex(self.endIndex.predecessor())
    }
    // Return the Suit part of the card
    func tail()->String{
        return self.substringFromIndex(self.endIndex.predecessor())
    }
}

struct Poker{
    
    static func bestHand(hands:[String])->String?{
        
        var pokerHandsParsed:[PokerHand] = []
        
        for each in hands{
            guard let pokerHand = PokerHand(each) else { return nil }
            pokerHandsParsed.append(pokerHand)
        }
        
        guard let topHand = (pokerHandsParsed.sort(>)).first,
            let indexTop = pokerHandsParsed.indexOf(topHand) else {return nil}
        
        return hands[indexTop]
        
    }
}

enum HandRank{
    case highCard(PlayingCard)
    case onePair(Rank,card1:Rank, card2:Rank, card3:Rank )
    case twoPair(high:Rank,low:Rank, highCard:PlayingCard)
    case threeOfAKind(three:Rank)
    case straight(high:Rank)
    case flush(Rank, Suit)
    case fullHouse(three:Rank)
    case fourOfAKind(four:Rank)
    case straightFlush(Rank,Suit)
    
    static func parsePairs(inputHand:PokerHand)->[(rank:Rank,count:Int)]{
        let ranks = inputHand.hand.map({$0.rank})
        let rankSet = Set(ranks)
        var toReturn = [Rank:Int]()
        for each in ranks{
            if rankSet.contains(each) {
                toReturn[each] = (toReturn[each] ?? 0) + 1
            }
        }
        return toReturn.map({key,value in return (rank:key,count:value)}).sort({
            (one, two) in
            return
            one.count == two.count ?
                one.rank > two.rank : one.count > two.count
        })
    }
    
    static func isFlush(inputHand:PokerHand)->(bool:Bool,suit:Suit){
        let suits = inputHand.hand.map({$0.suit})
        let first = suits[0]
        for each in suits{
            if (first != each) { return (false,.None)}
        }
        return (true,first)
    }
    
    static func isStraight(inputHand:PokerHand)->(bool:Bool, highest:Rank){
        let sorted = inputHand.hand.sort({$0.rank < $1.rank})
        let first = sorted[0].rank.rawValue
        for (index, each) in sorted.enumerate() {
            if (each.rank.rawValue != index + first){
                // checks for Ace as the lowest card
                guard let aceIndex = inputHand.hand.indexOf({$0.rank.rawValue == 14})else {return (false, .Ace)}
                var replacedAced = inputHand.hand.map({$0.rank.rawValue})
                replacedAced[aceIndex] = 1 // swaps ace value to lowest
                replacedAced.sortInPlace()
                let firstVal = replacedAced[0]
                for (idx,eachVal) in replacedAced.enumerate(){
                    if (eachVal != firstVal + idx ) { return (false,.Ace) }
                }
            }
        }
        let last = sorted[sorted.count - 1].rank
        return (true,last)
    }
    
    init(_ pokerHand:PokerHand){
        let pairs = HandRank.parsePairs(pokerHand)
        let (flush, flushSuit) = HandRank.isFlush(pokerHand)
        let (straight, straightRank) = HandRank.isStraight(pokerHand)
        
        //straightFlush
        if flush && straight {
            self = .straightFlush(straightRank, flushSuit)
            //fourOfAKind
        } else if pairs[0].count == 4 {
            self = .fourOfAKind(four: (pairs[0]).rank)
            //fullHouse
        } else if pairs[0].count == 3 && pairs.count == 2 {
            self = .fullHouse(three: (pairs[0]).rank)
            //flush
        }else if flush {
            let r = (pairs[0]).rank
            self = .flush(r, flushSuit)
            //straight
        } else if straight {
            self = .straight(high: straightRank)
            //theeOfAKind
        } else if pairs[0].count == 3 && pairs.count == 3 {
            self = .threeOfAKind(three: (pairs[0]).rank)
            //twoPair
        } else if pairs[0].count == 2 && pairs.count == 3 {
            let r = (pairs[2]).rank
            let s = pokerHand.hand[4].suit
            self = .twoPair(high: (pairs[0]).rank, low: (pairs[1]).rank,
                highCard:PlayingCard.init(rank: r, suit: s))
            //onePair
        } else if pairs[0].count == 2 && pairs.count == 4 {
            self = .onePair((pairs[0]).rank, card1: (pairs[1]).rank, card2: (pairs[2]).rank, card3: (pairs[3]).rank)
            //highCard
        } else {
            let r = (pairs[0]).rank
            let s = pokerHand.hand[0].suit
            self = .highCard(PlayingCard(rank:r, suit:s ))
        }
    }
}

extension HandRank : Equatable, Comparable {}

func ==(lhs: HandRank, rhs: HandRank) -> Bool {
    switch (lhs, rhs) {
        //straightFlush(Rank,Suit)
    case (HandRank.straightFlush(let lRank, let lSuit),HandRank.straightFlush(let rRank , let rSuit)):
        return lRank == rRank && lSuit == rSuit
        //fourOfAKind(four:Rank)
    case (HandRank.fourOfAKind(four: let lFour),
        HandRank.fourOfAKind(four: let rFour)):
        return lFour == rFour
        //fullHouse(three:Rank)
    case (HandRank.fullHouse(three: let lThree),
        HandRank.fullHouse(three: let rThree)):
        return lThree == rThree
        //flush(Suit)
    case (HandRank.flush(let lRank, let lSuit)
        ,HandRank.flush(let rRank, let rSuit)):
        return lSuit == rSuit && lRank == rRank
        //straight(high:Rank)
    case (HandRank.straight(high: let lRank),
        HandRank.straight(high: let rRank)):
        return lRank == rRank
        //threeOfAKind(three:Rank)
    case (HandRank.threeOfAKind(three: let lRank),
        HandRank.threeOfAKind(three: let rRank)):
        return lRank == rRank
        //twoPair(high:Rank,low:Rank, highCard:PlayingCard)
    case (HandRank.twoPair(high: let lHigh, low: let lLow, highCard: let lCard),HandRank.twoPair(high: let rHigh, low: let rLow, highCard: let rCard)):
        return lHigh == rHigh && lLow == rLow && lCard == rCard
        //onePair(Rank)
    case (HandRank.onePair(let lPairRank, card1: let lCard1, card2: let lCard2, card3: let lCard3),
        HandRank.onePair(let rPairRank, card1: let rCard1, card2: let rCard2, card3: let rCard3)):
        return lPairRank == rPairRank && lCard1 == rCard1 && lCard2 == rCard2 && lCard3 == rCard3
        //highCard(PlayingCard)
    case (HandRank.highCard(let lCard), HandRank.highCard(let rCard)):
        return lCard == rCard
    default:
        return false
    }
}

func <(lhs: HandRank, rhs: HandRank) -> Bool {
    switch (lhs, rhs) {
    case (_, _) where lhs == rhs:
        return false
        
        //straightFlush(Rank,Suit)
    case (HandRank.straightFlush(let lRank, let lSuit),HandRank.straightFlush(let rRank , let rSuit)):
        return lRank == rRank ? lSuit < rSuit : lRank < rRank
    case (HandRank.straightFlush(_, _),_ ):
        return false
        
        //fourOfAKind(four:Rank)
    case (HandRank.fourOfAKind(four: let lFour),
        HandRank.fourOfAKind(four: let rFour)):
        return lFour < rFour
    case (HandRank.fourOfAKind(four: _), .straightFlush(_, _ ) ):
        return true
        
        //fullHouse(three:Rank)
    case (HandRank.fullHouse(three: let lRank),
        HandRank.fullHouse(three: let rRank)):
        return lRank < rRank
    case (HandRank.fullHouse(three: _),.straightFlush(_, _)),
    (HandRank.fullHouse(three: _),.fourOfAKind(four: _)):
        return true
        
        //flush(Suit)
    case (HandRank.flush(let lRank,let lSuit),HandRank.flush(let rRank, let rSuit)):
        return lRank == rRank ? lSuit < rSuit : lRank < rRank
    case (HandRank.flush(_), .fullHouse(three: _)),
    (HandRank.flush(_), .fourOfAKind(four: _)),
    (HandRank.flush(_), .straightFlush(_, _)):
        return true
        
        //straight(high:Rank)
    case (HandRank.straight(high: let lRank),
        HandRank.straight(high: let rRank)):
        return lRank < rRank
    case (HandRank.straight(high: _), .flush(_)),
    (HandRank.straight(high: _), .fullHouse(three: _)),
    (HandRank.straight(high: _), .fourOfAKind(four: _)),
    (HandRank.straight(high: _), .straightFlush(_, _)):
        return true
        
        //threeOfAKind(three:Rank)
    case (HandRank.threeOfAKind(three: let lRank),
        HandRank.threeOfAKind(three: let rRank)):
        return lRank < rRank
    case (HandRank.threeOfAKind(three: _), .straight(high: _)),
    (HandRank.threeOfAKind(three: _), .flush(_)),
    (HandRank.threeOfAKind(three: _), .fullHouse(three: _)),
    (HandRank.threeOfAKind(three: _), .fourOfAKind(four: _)),
    (HandRank.threeOfAKind(three: _), .straightFlush(_, _)):
        return true
        
        //twoPair(high:Rank,low:Rank, highCard:PlayingCard)
    case (HandRank.twoPair(high: let lHigh, low: let lLow, highCard: let lCard),HandRank.twoPair(high: let rHigh, low: let rLow, highCard: let rCard)):
        if lHigh == rHigh && lLow == rLow {
            return lCard < rCard
        } else {
            return lHigh < rHigh
        }
    case (HandRank.twoPair(high: _, low: _, highCard: _), .threeOfAKind(three: _)),
    (HandRank.twoPair(high: _, low: _, highCard: _), .straight(high: _)),
    (HandRank.twoPair(high: _, low: _, highCard: _), .flush(_)),
    (HandRank.twoPair(high: _, low: _, highCard: _), .fullHouse(three: _)),
    (HandRank.twoPair(high: _, low: _, highCard: _), .fourOfAKind(four: _)),
    (HandRank.twoPair(high: _, low: _, highCard: _), .straightFlush(_, _)):
        return true
        
        //onePair(Rank)
    case (HandRank.onePair(let lPairRank, card1: let lCard1, card2: let lCard2, card3: let lCard3),
        HandRank.onePair(let rPairRank, card1: let rCard1, card2: let rCard2, card3: let rCard3)):
        return lPairRank == rPairRank ? (lCard1 == rCard1 ? (lCard2 == rCard2 ? lCard3 < rCard3 :lCard2 < rCard2):lCard1 < rCard1):lPairRank < rPairRank
    case (HandRank.onePair(_), .twoPair(high: _, low: _, highCard: _)),
    (HandRank.onePair(_), .threeOfAKind(three: _)),
    (HandRank.onePair(_), .straight(high: _)),
    (HandRank.onePair(_), .flush(_)),
    (HandRank.onePair(_), .fullHouse(three: _)),
    (HandRank.onePair(_), .fourOfAKind(four: _)),
    (HandRank.onePair(_), .straightFlush(_, _)):
        return true
        
        //highCard(PlayingCard)
    case (HandRank.highCard(let lCard), HandRank.highCard(let rCard)):
        return lCard < rCard
    case (HandRank.highCard(_), .onePair(_)),
    (HandRank.highCard(_), .twoPair(high: _, low: _, highCard: _)),
    (HandRank.highCard(_), .threeOfAKind(three: _)),
    (HandRank.highCard(_), .straight(high: _)),
    (HandRank.highCard(_), .flush(_)),
    (HandRank.highCard(_), .fullHouse(three: _)),
    (HandRank.highCard(_), .fourOfAKind(four: _)),
    (HandRank.highCard(_), .straightFlush(_, _)):
        return true
        
    default:
        return false
    }
    
    
}

struct PokerHand{
    let hand:[PlayingCard]
    
    func handRank()->HandRank{
        return HandRank(self)
    }
    
    init?(_ stringHand:String){
        
        var handParsed:[PlayingCard] = []
        
        for each in stringHand.split(" "){
            guard let card = PlayingCard(each) else {return nil}
            handParsed.append(card)
        }
        
        if handParsed.count == 5 {self.hand = handParsed } else {return nil}
    }
}


extension PokerHand : Equatable, Comparable {}

func ==(lhs: PokerHand, rhs: PokerHand) -> Bool{
    return lhs.hand == rhs.hand
}

func <(lhs: PokerHand, rhs: PokerHand) -> Bool {
    return lhs.handRank() < rhs.handRank()
}


struct PlayingCard {
    let rank: Rank
    let suit: Suit
    
    init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }
    
    init?(_ stringInput:String){
        
        guard let rank = Rank(stringInput.head()),
            let suit = Suit(stringInput.tail()) else { return nil}
        
        self.rank = rank
        self.suit = suit
    }
}

extension PlayingCard : Equatable, Comparable {}

func ==(lhs: PlayingCard, rhs: PlayingCard) -> Bool{
    return lhs.rank == rhs.rank && lhs.suit == rhs.suit
}

func <(lhs: PlayingCard, rhs: PlayingCard) -> Bool {
    return lhs.rank == rhs.rank ? lhs.suit < rhs.suit : lhs.rank < rhs.rank
}


enum Rank : Int {
    case Two = 2
    case Three, Four, Five, Six, Seven, Eight, Nine, Ten
    case Jack, Queen, King, Ace
    
    init?(_ rank:String){
        var rankInt = 0
        switch rank{
        case "A": rankInt = 14
        case "J": rankInt = 11
        case "Q": rankInt = 12
        case "K": rankInt = 13
        default : rankInt = Int(rank) ?? 0
        }
        self.init(rawValue: rankInt)
    }
}

enum Suit: String {
    case Spades, Hearts, Diamonds, Clubs
    case None
    
    init?(_ suit:String){
        
        switch suit {
        case "♡": self = .Hearts
        case "♢": self = .Diamonds
        case "♧": self = .Clubs
        case "♤": self = .Spades
        case _  : return nil
        }
    }
}

extension Rank : Comparable {}

func <(lhs: Rank, rhs: Rank) -> Bool {
    switch (lhs, rhs) {
    case (_, _) where lhs == rhs:
        return false
    default:
        return lhs.rawValue < rhs.rawValue
    }
}

extension Suit: Comparable {}

func <(lhs: Suit, rhs: Suit) -> Bool {
    switch (lhs, rhs) {
    case (_, _) where lhs == rhs:
        return false
    case (.Spades, _),
    (.Hearts, .Diamonds), (.Hearts, .Clubs),
    (.Diamonds, .Clubs):
        return false
    default:
        return true
    }
}