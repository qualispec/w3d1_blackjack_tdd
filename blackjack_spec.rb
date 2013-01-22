require 'rspec'
require_relative './blackjack.rb'

include Blackjack

describe Card do
  subject(:card) { Card.new(:heart, :king) }
  its(:suit) { should == :heart }
  its(:value) { should == :king }

  describe '#blackjack_value' do

    it 'returns the cards blackjack value' do
      card.blackjack_value.should == 10
    end

    context 'when the card is an ace' do
      subject(:card) { Card.new(:spade, :ace) }

      it 'raises an exception' do
        expect { card.blackjack_value }.to raise_error(/special value/)
      end
    end
  end
end

describe Deck do
  subject(:deck) { Deck.new }
  let(:card1) { double('card1', suit: :club, value: :five) }
  let(:card2) { double('card1', suit: :club, value: :six) }

  describe '#initialize' do                     #Vincent - could also check that the 52 cards are unique.
    it 'defaults to a full deck' do
      deck.cards.should have(52).items
    end
                    
    context 'when an array of cards is given' do
      subject(:deck) { Deck.new([card1, card2]) }
      its(:cards) { should =~ [card1, card2] }
    end
  end

  describe '#take_out' do
    subject(:deck) { Deck.new([card1, card2]) }
    it 'returns n cards from the top of the deck' do
      deck.take_out(2).should =~ [card1, card2]
    end

    it 'removes n cards from the top of the deck' do    #Vincent - could test this on a deck with more than 2 cards
      deck.take_out(2)                                  # to really know that the cards are coming off the right direction of the deck.
      deck.cards.should be_empty
    end
  end

  describe '#return' do
    subject(:deck) { Deck.new([card1]) }
    let(:card3) { double('card3', suit: :club, value: :seven) }
    it 'returns cards to the bottom of the deck' do
      deck.return([card2, card3])                     #Vincent - you could write the spec to allow for more flexibility
      deck.cards.should == [card2, card3, card1]      # if the cards returned were [card 3, card 2, card1]
    end
  end

  describe '#shuffle' do
    it 'shuffles the deck' do
      expect { deck.shuffle }.to change { deck.cards }
    end
  end
end

describe Hand do
  subject(:hand) { Hand.new }
  its(:cards) { should be_empty }

  let(:card1) { double('card1', blackjack_value: 10, value: :ten) }
  let(:card2) { double('card2', blackjack_value: 6, value: :six) }
  let(:card3) { double('card3', blackjack_value: 10, value: :jack) }
  let(:deck) { double('deck', cards: [card3, card1, card2]) }

  describe '#deal' do
    before(:each) do
      deck.should_receive(:take_out).and_return([card1, card2])
    end

    it 'returns two cards from the given deck' do
      hand.deal(deck).should == [card1, card2]
    end

    it 'inserts the cards into the hand' do
      hand.deal(deck)
      hand.cards.should == [card1, card2]
    end
  end

  describe '#hit' do

    it 'takes another card from the given deck' do
      deck.stub(:take_out) { [card1] }
      expect { hand.hit(deck) }.to change { hand.cards.count }.to(1)
    end

    context 'when busted' do                    #Vincent - this is a little bit confusing because your deck only
      before(:each) do                          # has 3 cards. Could confuse whether the error is because of trying 
        deck.stub(:take_out) { [card1, card2] } # to hit while busted, or while trying to hit with deck empty?
        hand.deal(deck)
        deck.stub(:take_out) { [card3] }
        hand.hit(deck)
      end

      it 'raises an error' do
        expect { hand.hit(deck) }.to raise_error
      end

      it 'does not add a card to the hand' do
        expect { hand.hit(deck) }.to raise_error
        hand.cards.should have(3).items
      end
    end
  end

  describe '#points' do
    let(:cards) { [Card.new(:club, :three), Card.new(:club, :four)] }

    before(:each) do
      @deck = Deck.new(cards)
    end

    it 'returns the total blackjack points for the hand' do
      hand.deal(@deck)
      hand.points.should == 7
    end

    context 'with aces' do
      let(:cards) { [Card.new(:club, :ten),
                     Card.new(:club, :ace),
                     Card.new(:heart, :three)] }
      before(:each) do
        hand.deal(@deck)
      end

      it 'handles ace values independently' do
        expect { hand.points }.to_not raise_error
      end

      it 'defaults the ace value to 11' do
        hand.points.should == 14
      end

      it 'uses 1 as ace value if necessary' do
        hand.hit(@deck)
        hand.points.should == 14
      end

      it 'handles multiple aces' do
        cards = [Card.new(:club, :ace),           
                 Card.new(:club, :two),
                 Card.new(:club, :ace),         #Vincent - should not have duplicate card!
                 Card.new(:heart, :three)]
        deck = Deck.new(cards)
        hand.deal(deck)
        hand.hit(deck)
        hand.hit(deck)

        hand.points.should == 17
      end
    end
  end

  describe '#busted?' do
    let(:cards) { [Card.new(:club, :ten),
                   Card.new(:club, :ten),
                   Card.new(:heart, :three)] }
    let(:deck) { Deck.new(cards) }
    it 'returns true when over 21' do
      hand.deal(deck)
      hand.hit(deck)
      hand.should be_busted
    end

    it 'returns false when 21 or below' do
      hand.deal(deck)
      hand.should_not be_busted
    end
  end
end

describe Player do
  subject(:player) { Player.new('Kriti', 100) }
  its(:name) { should == 'Kriti' }
  its(:bankroll) { should == 100 }
  its(:hand) { should be_nil }

  describe '#bet' do
    it 'subtracts from the players bankroll' do
      expect { player.bet(100) }.to change { player.bankroll }.to(0)
    end

    it 'raises an error when player tries to bet more than he has' do
      expect { player.bet(200) }.to raise_error(/poor/)
    end
  end

  describe '#collect_winnings' do

    it 'adds winnings to player bankroll' do
      expect { player.collect_winnings(100) }.to change { player.bankroll }.to(200)
    end
  end

  describe '#new_hand' do
    let(:cards) { [Card.new(:club, :ten),
                   Card.new(:heart, :three)] }
    let(:deck) { double('deck', take_out: cards) }

    it 'deals the player a new hand' do
      player.new_hand(deck)
      player.hand.cards.should =~ cards
    end
  end
end

describe Dealer do
  subject(:dealer) { Dealer.new }
  its(:name) { should == 'dealer' }
  its(:bankroll) { should == 0 }

  it 'is a kind of player' do
    dealer.should be_a_kind_of(Player)
  end

  describe '#take_bets' do
    let(:player1) { double('player1', bet: 50) }
    let(:player2) { double('player2', bet: 25) }
    let(:players) { [player1, player2] }

    it 'collects bets from players' do
      dealer.take_bets(players)
      dealer.bets.should have(2).items
    end
  end
end

# describe HumanPlayer
# describe Game
