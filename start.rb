
# encoding: utf-8
require 'telegram/bot'
require 'json'
require 'uri'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
token = '344686538:AAGWv2ANcHGZhoZDvubC5xMF2l9bOdJnh9k'
#incompleteLabels = ['5666779e19ad3a5dc26426a5','57287baf9148b133b928f6da','56d4fd5d152c3f92fd3a75c7','574c64565b9b3323fb39a5bd']

# begin
	Telegram::Bot::Client.run(token, logger: Logger.new($stderr)) do |bot|
		bot.logger.info('Bot has been started')
		bot.listen do |message|
			# begin
				#next if message.date < (Time.now - 120).to_i
				#case message.text
				#	when /\/q ./
				puts message.chat.id
					bot.api.send_message(chat_id: message.chat.id, text: message.date)
					bot.api.send_message(chat_id: message.chat.id, text: "出错辣,豆腐丝快粗来化身水管道工人")
				#end
			# rescue
			# 	sleep(70)
			# 	retry
			# end
		end
	end
# rescue
# 	puts '又出错一次啦,人家先睡70s喔'
# 	sleep(70)
# 	retry
# end