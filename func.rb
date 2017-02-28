#报错信息，反正都没用
def raise_errormessage message,bot
	bot.api.send_message(chat_id: message.from.id, text: "哎呀呀呀出错辣，快小窗敲豆腐丝 @tolves，反正敲了也不会修")
	sleep(70)
end

#将密级表的按钮提前做好，将来还有添加密级，添加信任等级等（好累
def security_level_keyboard
	secu_kb_array =Array.new
	all_security = @client.query("SELECT * FROM security")
	all_security.each do |secu|
		secu_kb_array << Telegram::Bot::Types::InlineKeyboardButton.new(text: secu['security_name'], callback_data: "security_level_#{secu['id']}")
	end
	secu_kb = Array.new
	secu_kb_array.each_slice(4){|kb| secu_kb<<kb}
	secu_kb
end

#职责表
def duty_level_keyboard
	duty_kb_array =Array.new
	all_duties = @client.query("SELECT * FROM activity_duty")
	all_duties.each do |duty|
		duty_kb_array << Telegram::Bot::Types::InlineKeyboardButton.new(text: duty['duty_name'], callback_data: "duty_level_#{duty['id']}")
	end
	duty_kb = Array.new
	duty_kb_array.each_slice(4){|kb| duty_kb<<kb}
	duty_kb
end