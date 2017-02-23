require_relative  'db_connect'
@conn = Db.new
@client = @conn.connect
@force_reply = Telegram::Bot::Types::ForceReply.new(force_reply: true, selective: true)
@query_agent_exist_statement = @client.prepare("SELECT agent_id,authority FROM users WHERE telegram_id = ?")#{message.chat.id}
@query_ingressid_exist_statement = @client.prepare("SELECT agent_id FROM users WHERE agent_id = ?")
@query_agent_admin_statement = @client.prepare("SELECT agent_id FROM users WHERE telegram_id = ? and authority in (1,2)")
@query_waiting_agent_statement = @client.prepare("SELECT agent_id,telegram_username FROM users WHERE authority = '6' ORDER BY 'created_on' LIMIT ?,7")
@query_agent_auth_statement_by_agent_id = @client.prepare("SELECT * FROM users AS us LEFT JOIN authority_name AS an ON us.authority=an.id WHERE us.agent_id = ?")
@query_agent_auth_statement_by_telegram_id = @client.prepare("SELECT * FROM users AS us LEFT JOIN authority_name AS an ON us.authority=an.id WHERE us.telegram_id = ?")


def bind message,bot
	agent_exist = @query_agent_exist_statement.execute(message.chat.id)
	# if agent_exist.size == 0
	if agent_exist.size != 0
		bot.api.send_message chat_id: message.chat.id, text: '你已经注册魔懒懒系统'
		return false
	end
	bot.api.send_message chat_id: message.chat.id, text: "你尚未注册魔懒懒系统 \n下面进入验证过程："
	bot.api.send_message chat_id: message.chat.id, text: '请认真输入你的游戏id，输错了就打pp', reply_markup:@force_reply
end


def resiger message,bot
	agent_exist = @query_ingressid_exist_statement.execute(message.text)
	if agent_exist.size != 0
		bot.api.send_message chat_id: message.chat.id, text: '少年不要用别人id来伪装自己哟'
		return false
	end

	begin
		agent_id = message.text.strip.encode(:xml => :text)
		bot.logger.info(agent_id)
		statement = @client.prepare("INSERT INTO users (agent_id,telegram_id,telegram_username,created_on,updated_on,authority) VALUES (?,\"#{message.chat.id}\",\"#{message.from.username}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",6)")
		insert_user = statement.execute(agent_id)
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


def overview message,bot
	agent_exist = @query_agent_exist_statement.execute(message.chat.id)
	if agent_exist.size == 0
		bot.api.send_message chat_id: message.chat.id, text: '你尚未注册魔懒懒系统，输入 /start 开始注册'
		return false
	end

	overview_kb= [
			[
				Telegram::Bot::Types::InlineKeyboardButton.new(text: '审核特工', callback_data: 'overview_review_agent'),
				Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看自己信息', callback_data: 'overview_get_me'),
				Telegram::Bot::Types::InlineKeyboardButton.new(text: '修改特工权限', callback_data: 'overview_modify_agent_auth'),
			],
	    [
		    Telegram::Bot::Types::InlineKeyboardButton.new(text: '新建活动', callback_data: 'overview_create_activity'),
		    Telegram::Bot::Types::InlineKeyboardButton.new(text: '活动的活动', callback_data: 'overview_available_activity'),
		    Telegram::Bot::Types::InlineKeyboardButton.new(text: '存档的活动', callback_data: 'overview_archived_activity'),
			]
	]
	overview_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: overview_kb)

	overview_welcome = "欢迎来到魔懒咸个不停小分队大厅\n"
	overview_welcome << "请按照选择您要进行的操作\n"
	bot.api.send_message chat_id: message.chat.id, text: overview_welcome, reply_markup: overview_makeup
end


def review_waiting message,bot
	agent_auth = @query_agent_admin_statement.execute(message.message.chat.id)
	if agent_auth.size == 0
		bot.api.edit_message_text chat_id: message.message.chat.id, message_id:message.message.message_id, text:'少年郎你没有审核权限啦'
		return false
	end

	@current_page = 0

	results = @client.query("SELECT COUNT(agent_id) FROM users WHERE authority=6");
	if results.first['count(agent_id)'] < 1
		bot.api.answer_callback_query callback_query_id:message.id , text: '无未被审核特工'
		return false
	end

	waiting_list = @query_waiting_agent_statement.execute(@current_page)
	waiting_list_kb = Array.new

	waiting_list.each do |agent|
		waiting_list_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: agent['agent_id'], callback_data: "review_waiting_#{agent['agent_id']}")
	end

	waiting_list_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: waiting_list_kb)
	bot.api.edit_message_text chat_id: message.message.chat.id, message_id:message.message.message_id, text:'请选择你要审核的特工id', reply_markup: waiting_list_markup
end


def get_waiting_detail message,bot
	agent_id = message.data.sub(/review_waiting_/ , "")
	waiting_agent = @query_agent_auth_statement_by_agent_id.execute(agent_id)
	return false if waiting_agent.size < 1

	approve_keyboard = [[
		Telegram::Bot::Types::InlineKeyboardButton.new(text: '通过', callback_data: "review_agent_approved_#{agent_id}"),
		Telegram::Bot::Types::InlineKeyboardButton.new(text: '反对', callback_data: "review_agent_refused_#{agent_id}"),
		Telegram::Bot::Types::InlineKeyboardButton.new(text: '不认识，搁置', callback_data: "review_agent_hold_on_#{agent_id}"),
		Telegram::Bot::Types::InlineKeyboardButton.new(text: '点错返回', callback_data: "review_agent_back")
	]]
	approve_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: approve_keyboard)
	waiting_agent = waiting_agent.first
	waiting_agent_detail = "被审核用户 ingress id： #{waiting_agent['agent_id']}\n"
	waiting_agent_detail << "被审核用户 telegram id： @#{waiting_agent['telegram_username']}\n"
	waiting_agent_detail << "请谨慎审核该特工是否是可信特工\n"
	bot.api.edit_message_text chat_id: message.message.chat.id, message_id:message.message.message_id, text: waiting_agent_detail, reply_markup: approve_markup
end


def judgement_waiting message,bot
	judgement_statement = @client.prepare("UPDATE users SET authority=? WHERE agent_id=?")
	current_auth_statement = @client.prepare("SELECT agent_id,telegram_username,authority FROM users WHERE agent_id=?")
	judge_kb = [[
		Telegram::Bot::Types::InlineKeyboardButton.new(text: '继续审核', callback_data: "overview_review_agent"),
		Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回大厅', callback_data: "overview_back")
	]]
	judge_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: judge_kb)
	case message.data
		when /review_agent_approved_./
			agent_id = message.data.sub /review_agent_approved_/,""
			rookie_user = judgement_statement.execute(4,agent_id)
			judge_text = "#{agent_id} 已经通过审核"
		when /review_agent_refused_./
			agent_id = message.data.sub /review_agent_refused_/,""
			refused_user = judgement_statement.execute(5,agent_id)
			judge_text = "#{agent_id} 未通过审核"
		when 'review_agent_back'
			review_waiting message,bot
			return
		else
			judge_text = "既然什么也不做，那就咸鱼一会儿吧"
	end
	bot.api.edit_message_text chat_id: message.message.chat.id, message_id:message.message.message_id, text: judge_text, reply_markup: judge_markup
end


def get_me message,bot
	result = @client.query("SELECT * FROM users AS us LEFT JOIN profile AS pf ON us.id=pf.user_id WHERE us.telegram_id = #{message.message.chat.id}")
	result.each do |agent|
		# agent.each do |key,value|
		# bot.logger.info(agent.map { |k,v| "#{k} = #{v}" }.join(", "))
		agent.each do |k,v|
			bot.logger.info("#{k} = #{v}")
		end
			# text += agent
		# end
	end
	# bot.logger.info(text)
end


def modify_agent_auth message,bot
	agent_auth = @query_agent_admin_statement.execute(message.message.chat.id)
	if agent_auth.size == 0
		bot.api.edit_message_text chat_id: message.message.chat.id, message_id:message.message.message_id, text:'少年郎你没有修改权限啦'
		return false
	end
	bot.api.send_message chat_id: message.message.chat.id, text: '请输入需要修改权限特工的ingress id：', reply_markup:@force_reply
end


def check_modified_agent message,bot
	agent_id = message.text.strip.encode(:xml => :text)
	agent_id_detail = @query_agent_auth_statement_by_agent_id.execute(agent_id)
	agent_id_detail = agent_id_detail.first

	current_user_detail = @query_agent_exist_statement.execute(message.chat.id)
	current_user = current_user_detail.first

	all_auth = @client.query("SELECT * FROM authority_name")
	detail_text = "特工ingress id： #{agent_id_detail['agent_id']}\n"
	detail_text << "特工telegram id： @#{agent_id_detail['telegram_username']}\n"
	detail_text << "目前权限等级：#{agent_id_detail['name']}\n"
	detail_text << "下面选项为将特工 #{agent_id_detail['agent_id']} 将要设为的权限级别"
	modify_auth_array_kb = Array.new
	all_auth.each do |auth|
		next if auth['id'] <= current_user['authority']
		modify_auth_array_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: auth['name'], callback_data: "modify_auth_#{auth['id']}_#{agent_id_detail['agent_id']}")
	end

	modify_auth_kb = [modify_auth_array_kb[0..2],modify_auth_array_kb[2..modify_auth_array_kb.length]]
	modify_auth_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: modify_auth_kb)
	bot.api.send_message chat_id: message.chat.id, text: detail_text, reply_markup: modify_auth_markup
end