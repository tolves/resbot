require_relative  'db_connect'
@conn = Db.new
@client = @conn.connect
@force_reply = Telegram::Bot::Types::ForceReply.new(force_reply: true, selective: true)
@query_agent_exist_statement = @client.prepare("select agent_id from users where telegram_id = ?")#{message.chat.id}
@query_agent_auth_statement = @client.prepare("select agent_id from users where telegram_id = ? and authority in (1,2)")


def bind message,bot
	agent_exist = @query_agent_exist_statement.execute(message.chat.id)
	if agent_exist.size == 0
		bot.api.send_message chat_id: message.chat.id, text: "你尚未注册魔懒懒系统 \n下面进入验证过程："
		bot.api.send_message chat_id: message.chat.id, text: '请认真输入你的游戏id，输错了就打pp', reply_markup:@force_reply
	else
		bot.api.send_message chat_id: message.chat.id, text: '你已经注册魔懒懒系统'
	end
end

def resiger message,bot
	agent_exist = @query_agent_exist_statement.execute(message.chat.id)
	if(agent_exist.size == 0)
		statement = @client.prepare("insert into users (agent_id,telegram_id,telegram_username,created_on,updated_on,authority) values (?,\"#{message.chat.id}\",\"#{message.from.username}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",6)")
		insert_user = statement.execute(message.text)
		agent_exist = @query_agent_exist_statement.execute(message.chat.id)

		if agent_exist != 0
			bot.api.send_message chat_id: message.chat.id, text: "#{message.from.username}，你的信息已录入魔懒懒系统，请耐心等待approved"
		else
			bot.api.send_message chat_id: message.chat.id, text: "药丸药丸，快找豆腐丝修bug"
		end

	else
		bot.api.send_message chat_id: message.chat.id, text: '少年不要用别人id来伪装自己哟'
		bot.api.send_message chat_id: message.chat.id, text: '请认真输入你的游戏id，输错了就打pp', reply_markup:@force_reply
	end
end

def approve_waiting message,bot
	agent_auth = @query_agent_auth_statement.execute(message.chat.id)
	if agent_auth.size == 0
		bot.api.send_message chat_id: message.chat.id, text: '少年郎你没有审核权限啦'
		return false
	end
	bot.api.send_message chat_id: message.chat.id, text: '少年郎你很强噢'
end




# keyboard = [
# 		Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Button 1', callback_data: 'first_btn'),
# 		Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Button 2', callback_data: 'second_btn')
# ]
# markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
# bot.api.send_message chat_id: message.chat.id, text: 'Foo', reply_markup: markup