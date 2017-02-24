#修改用户信任等级，这个地方我觉得加一个日志比较好，防止出现随意审核，因为用户列表是隐藏，只有数据库看得到（其实是我不会做按钮分页）
def modify_agent_auth message,bot
	agent_auth = @query_agent_admin_statement.execute(message.from.id)
	if agent_auth.size == 0
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'少年郎你没有修改权限啦'
		return false
	end
	bot.api.send_message chat_id: message.from.id, text: '请输入需要修改权限特工的ingress id：', reply_markup:@force_reply
end

#取得被修改特工当前信息
def check_modified_agent message,bot
	agent_id = message.text.strip.encode(:xml => :text)
	agent_id_detail = @query_agent_auth_statement_by_agent_id.execute(agent_id)
	if agent_id_detail.size == 0
		bot.api.send_message chat_id: message.from.id, text: '未找到该特工，请重新输入'
		bot.api.send_message chat_id: message.from.id, text: '请输入需要修改权限特工的ingress id：', reply_markup:@force_reply
		return false
	end
	agent_id_detail = agent_id_detail.first

	current_user_detail = @query_agent_exist_statement.execute(message.from.id)
	current_user = current_user_detail.first

	if agent_id_detail['telegram_id'] == message.from.id
		bot.api.send_message chat_id: message.from.id, text: '不可以修改自己的权限'
		return false
	end
	if current_user['authority']>=agent_id_detail['authority']
		bot.api.send_message chat_id: message.from.id, text: '不可以修改权限高于自己的特工'
		return false
	end

	detail_text = "特工ingress id： #{agent_id_detail['agent_id']}\n"
	detail_text << "特工telegram id： @#{agent_id_detail['telegram_username']}\n"
	detail_text << "目前权限等级：#{agent_id_detail['name']}\n"
	detail_text << "下面选项为将特工 #{agent_id_detail['agent_id']} 将要设为的权限级别"

	modify_auth_array_kb = Array.new
	all_auth = @client.query("SELECT * FROM authority_name")
	all_auth.each do |auth|
		next if auth['id'] <= current_user['authority']
		modify_auth_array_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: auth['name'], callback_data: "modify_auth_#{auth['id']}_#{agent_id_detail['agent_id']}")
	end

	modify_auth_kb = Array.new
	modify_auth_array_kb.each_slice(3){|kb| modify_auth_kb<<kb}

	modify_auth_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: modify_auth_kb)
	bot.api.send_message chat_id: message.from.id, text: detail_text, reply_markup: modify_auth_markup
end

#开始update
def amend_agent message,bot
	amend_auth_id,agent_id = message.data.split('_',4)[2,3]
	begin
		@client.query("UPDATE users SET authority=#{amend_auth_id} WHERE agent_id=\"#{agent_id}\"")
		@update_agent_updatedate_by_telegram_id.execute(message.from.id)
	rescue
		raise_errormessage message,bot
		retry
	end
	amend_text = "特工：#{agent_id} 权限已经更新"
	amend_kb = Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
	amend_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: amend_kb)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: amend_text , reply_markup:amend_makeup
end