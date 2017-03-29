#首次绑定，信任为5,6时只能查看自己信息
def bind message,bot
	agent_exist = @query_agent_exist_statement.execute(message.from.id)
	# if agent_exist.size == 0
	if agent_exist.size != 0
		bot.api.send_message chat_id: message.from.id, text: '你已经注册魔懒懒系统'
		return false
	end
	begin
		bot.api.send_message chat_id: message.from.id, text: "你尚未注册魔懒懒系统 \n下面进入验证过程："
		bot.api.send_message chat_id: message.from.id, text: '请认真输入你的游戏id，输错了就打pp，必须回复本条方可正确录入', reply_markup:@force_reply
	rescue
		bot.api.send_message chat_id: message.chat.id, text: '你尚未注册魔懒懒系统，请先小窗bot /start 开始，要不然收不到信息的哟'
		return false
	end
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
		bot.api.send_message chat_id: message.chat.id, text: '药丸药丸，快找豆腐丝 @tolves 修bug'
		return false
	end

	bot.api.send_message chat_id: message.from.id, text: "#{message.from.username}，你的信息已录入魔懒懒系统\n请联系你认为是*dalao*的*dadiao*来帮你做验证吧~\n*魔懒欢迎你的加入~,点击 /go 返回大厅*\n点击下面链接可以进入新人群噢~\n[戳我戳我](https://t.me/joinchat/AAAAAD6cFZdk3BqhIi-2bg)\n欢迎加入The Grid：[The Grid 中文版指南](https://goo.gl/xgOLmp) \n 1.首先，你需要报名注册，并进行第一次状态更新。请到 http://the-grid.org/r ，点选「Sign up ！(注册)」\n 2.填写所有的资讯。请在「- Where do you play? -」选单里，选取「China」，在「- Select your region -」选取你所在的省份或直辖市。点击「Create Account（建立账户）」，点击后（没有提示）会退回初始页面，请在telegram组群@管理（ @StellaUnBeso @heretop  ）并附上自己的agent name确认。\n 3.你的帐号需要经过管理员认证后才能开始玩。管理员要花一点时间认证所有的人，请耐心等候。一旦你的帐号认证通过，你会收到一封确认邮件。" ,parse_mode:"Markdown"
end