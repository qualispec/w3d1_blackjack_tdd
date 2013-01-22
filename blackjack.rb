module Blackjack
  class Card
    SUITS = { spade: "\u2660",
              heart: "\u2665",
              diamond: "\u2666",
              club: "\u2663"     }

    VALUES = {  ace: "A",
                two: "2",
                three: "3",
                four: "4",
                five: "5",
                six: "6",
                seven: "7",
                eight: "8",
                nine: "9",
                ten: "10",
                jack: "J",
                queen: "Q",
                king: "K" }

    BLACKJACK_VALUES = {  two: 2,
                          three: 3,
                          four: 4,
                          five: 5,
                          six: 6,
                          seven: 7,
                          eight: 8,
                          nine: 9,
                          ten: 10,
                          jack: 10,
                          queen: 10,
                          king: 10    }

    attr_reader :suit, :value

    def self.suits
      SUITS.keys
    end

    def self.values
      VALUES.keys
    end

    def initialize(suit, value)
      @suit = suit          #Vincent - an option is to 1-line these assignment statements.
      @value = value
    end

    def blackjack_value
      raise "Ace has a special value" if @value == :ace

      BLACKJACK_VALUES[@value]
    end
  end

  class Deck
    def self.all_cards
      Card.suits.product(Card.values).map do |suit, value|    #Vincent - option to 1-line this with {} instead of do/end.
        Card.new(suit, value)
      end
    end

    attr_reader :cards

    def initialize(cards = Deck.all_cards)
      @cards = cards
    end

    def take_out(n)
      @cards.pop(n)
    end

    def return(cards)
      @cards.unshift(*cards)
    end

    def shuffle
      @cards.shuffle!
    end
  end

  class Hand
    attr_reader :cards

    def initialize
      @cards = []
    end

    def deal(deck)
      @cards = deck.take_out(2)
    end

    def hit(deck)
      raise "Already busted" if busted?
      @cards += deck.take_out(1)
    end

    def points
      points = 0
      aces = 0      #Vincent - variable name could be more clear as num_aces

      @cards.each do |card|
        card.value == :ace ? aces += 1 : points += card.blackjack_value
      end

      aces.times do
        points += 11
        points -= 10 if points > 21
      end

      points
    end

    def busted?
      points > 21
    end
  end

  class Player
    attr_reader :name, :bankroll, :hand

    def initialize(name, bankroll)
      @name, @bankroll = name, bankroll
      @hand = nil
    end

    def bet(amt)
      amt > @bankroll ? raise("You're too poor") : @bankroll -= amt
    end

    def collect_winnings(amt)
      @bankroll += amt
    end

    def new_hand(deck)
      @hand = Hand.new
      @hand.deal(deck)
    end
  end

  class Dealer < Player
    def initialize
      super('dealer', 0)
    end

    def take_bets(player_bets)
      @bets = player_bets
      player_bets.each do |player, bet|
        bets[player] = player.bet(bet)
      end
      bets
    end
  end
end
