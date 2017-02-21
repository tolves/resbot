
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
						bind message,bot
					when '/approve'
						approve_waiting message,bot
					else
						if !message.reply_to_message.nil?
							case message.reply_to_message.text
								when '请认真输入你的游戏id，输错了就打pp'
										next if resiger message,bot
								else
									bot.logger.info(message.reply_to_message)
							end
						end

				end
			when 'Telegram::Bot::Types::CallbackQuery'
				# bot.logger.info(message.message.date)
				# next if message.message.date < (Time.now - 120).to_i
				# bot.logger.info(message.id)
				# bot.api.answer_callback_query callback_query_id:message.id , text: 'inline'
			else
				# bot.logger.info(message.class)
				# bot.api.send_message chat_id: message.chat.id, text: 'Foo', reply_markup: markup
		end


		# bot.api.send_message chat_id: message.chat.id, text: message.type
		# bot.logger.info(message.callbackquery.inline_message_id)
		# begin
			#next if message.date < (Time.now - 120).to_i
			#case message.text
			#	when /\/q ./
				# bot.api.send_message(bot.api.methods)
				# bot.logger.info(bot.api.get_me)
				# bot.api.inline_query(id:message.chat.id,from:message.from,query:'123',offset:'123123')
				# bot.api.send_message chat_id:message.chat.id, text: 'Foo', reply_markup: markup


				# bot.api.get_user_profile_photos(user_id:message.from.id,limit:3)['result']['photos'].each do |photo|
					# bot.logger.info(photo)
					# bot.api.send_photo(chat_id: message.chat.id, photo:photo[0]['file_id'])
					# bot.logger.info(photo[0]['file_id'])
				# end
					# bot.api.send_photo(chat_id: message.chat.id, photo:items.file_id)
			# }
			#end
		# rescue
		# 	sleep(70)
		# 	retry
		# end
	end
end