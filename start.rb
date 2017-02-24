
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
								when '请输入要创建的活动名称：'
									next if create_activity_name message,bot
								when '成功新建活动，请继续输入活动详情：'
									next if create_activity_detail message,bot
								else
									bot.logger.info(message.reply_to_message)
							end
						end
				end
			when 'Telegram::Bot::Types::CallbackQuery'
				next if message.message.date < (Time.now - 120).to_i
				case message.data
					when 'overview_review_agent'
						review_waiting message,bot
					when 'overview_get_me'
						get_me message,bot
					when 'overview_modify_agent_auth'
						modify_agent_auth message,bot
					when 'overview_create_activity'
						create_activity message,bot
					when 'overview_available_activity'
						view_availalbe_activity message,bot
					when /review_waiting_./
						get_waiting_detail message,bot
					when /review_agent_./
						judgement_waiting message,bot
					when /modify_auth_./
						amend_agent message,bot
					when /security_level_./
						create_activity_security_level message,bot
				end
			else

		end
	end
end