#首次绑定，信任为5,6时只能查看自己信息
def bind message,bot
	agent_exist = @query_agent_exist_statement.execute(message.from.id)
	# if agent_exist.size == 0
	if agent_exist.size != 0
		bot.api.send_message chat_id: message.from.id, text: '你已经注册魔懒懒系统'
		return false
	end
	bot.api.send_message chat_id: message.from.id, text: "你尚未注册魔懒懒系统 \n下面进入验证过程："
	bot.api.send_message chat_id: message.from.id, text: '请认真输入你的游戏id，输错了就打pp', reply_markup:@force_reply
	@mark = 'mark'
end

#特工输入自己游戏id，考虑加入活跃地区
def resiger message,bot
	agent_exist = @query_ingressid_exist_statement.execute(message.text)
	if agent_exist.size != 0
		bot.api.send_message chat_id: message.from.id, text: '少年不要用别人id来伪装自己哟'
		return false
	end
	if @mark.nil?
		bot.api.send_message chat_id: message.from.id, text: '不要做坏事哟'
		return false
	end

	statement = @client.prepare("INSERT INTO users (agent_id,telegram_id,telegram_username,created_on,updated_on,authority) VALUES (?,\"#{message.from.id}\",\"#{message.from.username}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",6)")
	agent_id = message.text.strip.encode(:xml => :text)
	begin
		statement.execute(agent_id)
		@mark = nil
	rescue
		raise_errormessage message,bot
		retry
	end

	agent_exist = @query_agent_exist_statement.execute(message.from.id)
	if agent_exist == 0
		bot.api.send_message chat_id: message.chat.id, text: "药丸药丸，快找豆腐丝 @tolves 修bug"
		return false
	end

	bot.api.send_message chat_id: message.from.id, text: "#{message.from.username}，你的信息已录入魔懒懒系统\n请联系你认为是*dalao*的*dadiao*来帮你做验证吧~\n*魔懒欢迎你的加入~,点击 /go 返回大厅*\n点击下面链接可以进入新人群噢~\n[戳我戳我](https://t.me/joinchat/AAAAAD6cFZdk3BqhIi-2bg)" ,parse_mode:"Markdown"
end