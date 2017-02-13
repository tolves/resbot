
# encoding: utf-8
require 'telegram/bot'
require 'json'
require 'uri'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
token = '344686538:AAGWv2ANcHGZhoZDvubC5xMF2l9bOdJnh9k'

require_relative  'db_connect'
conn = Db.new
client = conn.connect


Telegram::Bot::Client.run(token, logger: Logger.new($stderr)) do |bot|
	bot.logger.info('Bot has been started')
	bot.listen do |message|

		# begin
			#next if message.date < (Time.now - 120).to_i
			#case message.text
			#	when /\/q ./
				# bot.api.send_message(bot.api.methods)
				bot.logger.info(bot.api.get_me)
				# bot.api.send_message(chat_id: message.chat.id, text: message.date)
				# bot.api.send_message(chat_id: message.chat.id, text: "出错辣,豆腐丝快粗来化身水管道工人")
				# bot.api.sendPhoto(chat_id:message.chat.id,photo:bot.api.getUserProfilePhotos(75708608))
				# bot.api.send_photo(chat_id:message.chat.id,photo:(bot.api.get_user_profile_photos(user_id:message.from.id))[0].file_id)
				# bot.logger.info((bot.api.get_user_profile_photos(user_id:message.from.id,limit:1))['result']['photos'][0][0]['file_id'])
				bot.api.get_user_profile_photos(user_id:message.from.id,limit:3)['result']['photos'].each do |photo|
					# bot.logger.info(photo)
					bot.api.send_photo(chat_id: message.chat.id, photo:photo[0]['file_id'])
					# bot.logger.info(photo[0]['file_id'])
				end
					# bot.api.send_photo(chat_id: message.chat.id, photo:items.file_id)
			# }
			#end
		# rescue
		# 	sleep(70)
		# 	retry
		# end
	end
end