require 'cinch'
require 'feedzirra'

module Mendibot
  module Plugins
    class RSSRelay
      include Cinch::Plugin

      def self.feed_interval(feed)
        feed[:interval] || Mendibot::Config::RSS_SETTINGS[:interval]
      end

      Mendibot::Config::RSS_SETTINGS[:feeds].each do |feed|
        method_name = "#{feed[:name]}_pull"

        define_method method_name do
          data = Feedzirra::Feed.fetch_and_parse(feed[:url])
          process_items(feed, data.entries)
        end

        timer feed_interval(feed), method: method_name
      end

      def process_items(feed, items)
        interval = RSSRelay.feed_interval(feed)

        items.each do |item|
          next unless post_time = item.published

          if post_time >= Time.now - interval
            author = item.author || 'a mysterious stranger'

            feed[:channels].each do |chan|
              Channel(chan).send <<-MESSAGE
  via #{feed[:name]} comes the epic saga "#{item.title}", by #{author}! #{item.url}
  MESSAGE
            end
          end
        end

      rescue Exception => e
        bot.logger.debug e.message
      end

    end
  end
end
