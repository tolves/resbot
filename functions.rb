require_relative  'db_connect'
@conn = Db.new
@client = @conn.connect
@force_reply = Telegram::Bot::Types::ForceReply.new(force_reply: true, selective: true)
@query_agent_exist_statement = @client.prepare("select agent_id from users where telegram_id = ?")#{message.chat.id}
@query_agent_auth_statement = @client.prepare("select agent_id from users where telegram_id = ? and authority in (1,2)")
@query_agent_auth_statement_by_agent_id = @client.prepare("select agent_id,telegram_username,authority from users where agent_id = ?")


def bind message,bot
	agent_exist = @query_agent_exist_statement.execute(message.chat.id)
	if agent_exist.size != 0
		bot.api.send_message chat_id: message.chat.id, text: '你已经注册魔懒懒系统'
		return false
	end
	bot.api.send_message chat_id: message.chat.id, text: "你尚未注册魔懒懒系统 \n下面进入验证过程："
	bot.api.send_message chat_id: message.chat.id, text: '请认真输入你的游戏id，输错了就打pp', reply_markup:@force_reply
end

def resiger message,bot
	agent_exist = @query_agent_exist_statement.execute(message.chat.id)
	if agent_exist.size != 0
		bot.api.send_message chat_id: message.chat.id, text: '少年不要用别人id来伪装自己哟'
		return false
	end

	begin
		statement = @client.prepare("insert into users (agent_id,telegram_id,telegram_username,created_on,updated_on,authority) values (?,\"#{message.chat.id}\",\"#{message.from.username}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",6)")
		insert_user = statement.execute(message.text)
	rescue
		bot.api.send_message(chat_id: message.chat.id, text: "出错辣,快小窗敲豆腐丝 @tolves")
		sleep(70)
		retry
	end

	agent_exist = @query_agent_exist_statement.execute(message.chat.id)
	if agent_exist == 0
		bot.api.send_message chat_id: message.chat.id, text: "药丸药丸，快找豆腐丝 @tolves 修bug"
		return false
	end

	bot.api.send_message chat_id: message.chat.id, text: "#{message.from.username}，你的信息已录入魔懒懒系统，请耐心等待approved"
end

def approve_for_waiting message,bot
	agent_auth = @query_agent_auth_statement.execute(message.chat.id)
	if agent_auth.size == 0
		bot.api.send_message chat_id: message.chat.id, text: '少年郎你没有审核权限啦'
		return false
	end
	agent_id = message.text.sub(/\/approve / , "").downcase.to_s
	waiting_agent = @query_agent_auth_statement_by_agent_id.execute(agent_id)
	unless waiting_agent.size == 0

		$approve_keyboard = [
				Telegram::Bot::Types::InlineKeyboardButton.new(text: '通过', callback_data: 'waiting_approved'),
				Telegram::Bot::Types::InlineKeyboardButton.new(text: '反对', callback_data: 'waiting_refused'),
				Telegram::Bot::Types::InlineKeyboardButton.new(text: '不认识，搁置', callback_data: 'waiting_hold_on')
		]
		approve_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [$approve_keyboard])

		waiting_agent_detail = "被审核用户 ingress id：#{waiting_agent.first['agent_id']}\n"
		waiting_agent_detail << "被审核用户 telegram id：#{waiting_agent.first['telegram_username']}\n"
		waiting_agent_detail << "请谨慎审核该特工是否是可信特工\n"
		bot.api.send_message chat_id: message.chat.id, text: waiting_agent_detail, reply_markup: approve_markup
	else
		bot.api.send_message chat_id: message.chat.id, text: '少年郎你要审核的特工不存在啊，你确定你没有输错id吗？'
	end
end

def judgement_waiting message,bot
	kb_hide = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
	$approve_keyboard = [
			Telegram::Bot::Types::InlineKeyboardButton.new(text: '通过', callback_data: 'waiting_approved'),
			Telegram::Bot::Types::InlineKeyboardButton.new(text: '反对', callback_data: 'waiting_refused'),
			Telegram::Bot::Types::InlineKeyboardButton.new(text: '不认识，搁置', callback_data: 'waiting_hold_on')
	]
	approve_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [$approve_keyboard])

	bot.logger.info(message.inline_message_id)
	# bot.api.edit_message_reply_markup chat_id: message.message.chat.id, reply_markup:kb_hide, text:'remove kb'
	bot.api.edit_message_text chat_id: message.message.chat.id, message_id:message.message.message_id, text:'changed wordl'
	# reply_markup:kb_hide, text:'remove kb'

end


# keyboard = [
# 		Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Button 1', callback_data: 'first_btn'),
# 		Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Button 2', callback_data: 'second_btn')
# ]
# markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
# bot.api.send_message chat_id: message.chat.id, text: 'Foo', reply_markup: markup