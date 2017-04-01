require 'twitter_ebooks'

# Information about a particular Twitter user we know
class UserInfo
  attr_reader :username

  # @return [Integer] how many times we can pester this user unprompted
  attr_accessor :pesters_left

  # @param username [String]
  def initialize(username)
    @username = username
    @pesters_left = 5
  end
end

class CloneBot < Ebooks::Bot
  attr_accessor :original, :model, :model_path

  def configure
    # Configuration for all CloneBots
    self.consumer_key = ""
    self.consumer_secret = ""
    self.blacklist = []
    self.delay_range = 1..6
    @userinfo = {}
  end

  def top100; @top100 ||= model.keywords.take(100); end
  def top20;  @top20  ||= model.keywords.take(20); end

  def on_startup
    update_model!

    scheduler.every '7m' do
      tweet(model.make_statement)
    end

    scheduler.every '1h' do
      update_model!
    end
  end

  def on_message(dm)
    delay do
      reply(dm, model.make_response(dm.text))
    end
  end

  def on_mention(tweet)
    # Become more inclined to pester a user when they talk to us
    userinfo(tweet.user.screen_name).pesters_left += 1

    delay do
      reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
      delay do
        if tweet.user.tweets_count > 10
          follow(tweet.user.screen_name)
        end
      end
    end
  end

  def on_timeline(tweet)
    return if tweet.retweeted_status?
    return unless can_pester?(tweet.user.screen_name)

    tokens = Ebooks::NLP.tokenize(tweet.text)

    interesting = tokens.find { |t| top100.include?(t.downcase) }
    very_interesting = tokens.find_all { |t| top20.include?(t.downcase) }.length > 2

    delay do
      if very_interesting
        favorite(tweet) if rand < 0.5
        retweet(tweet) if rand < 0.1
        if rand < 0.01
          userinfo(tweet.user.screen_name).pesters_left -= 1
          reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
        end
        if rand < 0.5
          if tweet.user.tweets_count > 10
            follow(tweet.user.screen_name)
          end
        end
      elsif interesting
        favorite(tweet) if rand < 0.05
        if rand < 0.001
          userinfo(tweet.user.screen_name).pesters_left -= 1
          reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
        end
        if rand < 0.05
          if tweet.user.tweets_count > 10
            follow(tweet.user.screen_name)
          end
        end
      end
    end
  end

  # Find information we've collected about a user
  # @param username [String]
  # @return [Ebooks::UserInfo]
  def userinfo(username)
    @userinfo[username] ||= UserInfo.new(username)
  end

  # Check if we're allowed to send unprompted tweets to a user
  # @param username [String]
  # @return [Boolean]
  def can_pester?(username)
    userinfo(username).pesters_left > 0
  end

  # Only follow our original user or people who are following our original user
  # @param user [Twitter::User]
  def can_follow?(username)
    @original.nil? || username.casecmp(@original) == 0 || twitter.friendship?(username, @original)
  end

  def favorite(tweet)
    # if can_follow?(tweet.user.screen_name)
      super(tweet)
      delay do
        if tweet.user.tweets_count > 10
          follow(tweet.user.screen_name)
        end
      end
    # else
      # log "Unfollowing @#{tweet.user.screen_name}"
      # twitter.unfollow(tweet.user.screen_name)
    # end
  end

  def on_follow(user)
    # if can_follow?(user.screen_name)
    if user.tweets_count > 10
      follow(user.screen_name)
      update_model!
    end
    # else
      # log "Not following @#{user.screen_name}"
    # end
  end

  private
  def update_model!
    @twitter = self.twitter
    @friends = self.twitter.friends
    @corpusList = Array.new
    @friends.each do |friend|
      @corpusList.push( "corpus/#{friend.screen_name}.json" )
      Ebooks::Archive.new( "#{friend.screen_name}", "corpus/#{friend.screen_name}.json", @twitter ).sync
			sleep 10
    end
    @model = Ebooks::Model.consume_all( @corpusList )
  end
end

CloneBot.new("echoebook") do |bot|
  bot.access_token = ""
  bot.access_token_secret = ""

  bot.original = "echoebook"
end
