
# encoding: utf-8
require 'telegram/bot'
require 'json'
require 'uri'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
token = '344686538:AAGWv2ANcHGZhoZDvubC5xMF2l9bOdJnh9k'

require_relative  'db_connect'
require_relative  'functions'

Telegram::Bot::Client.run(token, logger: Logger.new($stderr)) do |bot|
	bot.logger.info('Bot has been started')
	bot.listen do |message|
		case message.class.to_s
			when 'Telegram::Bot::Types::Message'
				next if message.date < (Time.now - 120).to_i
				case message.text
					when '/start'
						next if bind message,bot
					when '/start@saltres_bot'
						next if bind message,bot
					when '/go'
						next if overview message,bot
					when '/go@saltres_bot'
						next if overview message,bot
					else
						if !message.reply_to_message.nil?
							case message.reply_to_message.text
								when '请认真输入你的游戏id，输错了就打pp'
									next if resiger message,bot
								when '请输入需要修改权限特工的ingress id：'
									next if check_modified_agent message,bot
								else
									bot.logger.info(message.reply_to_message)
							end
						end
				end
			when 'Telegram::Bot::Types::CallbackQuery'
				next if message.message.date < (Time.now - 120).to_i
				case message.data
					when 'overview_back'
						overview message,bot if message.class == Telegram::Bot::Types::Message
						overview message.message,bot if message.class == Telegram::Bot::Types::CallbackQuery
					when 'overview_review_agent'
						review_waiting message,bot
					when 'overview_get_me'
						get_me message,bot
					when 'overview_modify_agent_auth'
						modify_agent_auth message,bot
					when /review_waiting_./
						get_waiting_detail message,bot
					when /review_agent_./
						judgement_waiting message,bot
				end
			else

		end
	end
end