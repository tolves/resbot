require_relative  'db_connect'
@conn = Db.new
@client = @conn.connect

@force_reply = Telegram::Bot::Types::ForceReply.new(force_reply: true, selective: true)

@query_agent_exist_statement = @client.prepare("SELECT agent_id,authority FROM users WHERE telegram_id = ?")#{message.from.id}
@query_ingressid_exist_statement = @client.prepare("SELECT agent_id FROM users WHERE agent_id = ?")
@query_agent_admin_statement = @client.prepare("SELECT agent_id FROM users WHERE telegram_id = ? AND authority in (1,2)")
@query_waiting_agent_statement = @client.prepare("SELECT agent_id,telegram_username FROM users WHERE authority = '6' ORDER BY 'created_on' LIMIT ?,7")
@query_agent_auth_statement_by_agent_id = @client.prepare("SELECT * FROM users AS us LEFT JOIN authority_name AS an ON us.authority=an.id  WHERE us.agent_id=?")
@query_agent_auth_statement_by_telegram_id = @client.prepare("SELECT * FROM users AS us LEFT JOIN authority_name AS an ON us.authority=an.id WHERE us.telegram_id = ?")
@query_id_by_telegram_id = @client.prepare("SELECT id,agent_id,telegram_id,telegram_username,authority FROM users WHERE telegram_id = ?")
@query_profile_by_telegram_id = @client.prepare("SELECT * FROM profile WHERE telegram_id=?")
@update_agent_updatedate_by_telegram_id = @client.prepare("UPDATE users SET updated_on=\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\" WHERE telegram_id=?")


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
end

#特工输入自己游戏id，考虑加入活跃地区
def resiger message,bot
	agent_exist = @query_ingressid_exist_statement.execute(message.text)
	if agent_exist.size != 0
		bot.api.send_message chat_id: message.from.id, text: '少年不要用别人id来伪装自己哟'
		return false
	end

	statement = @client.prepare("INSERT INTO users (agent_id,telegram_id,telegram_username,created_on,updated_on,authority) VALUES (?,\"#{message.from.id}\",\"#{message.from.username}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",6)")
	begin
		agent_id = message.text.strip.encode(:xml => :text)
		insert_user = statement.execute(agent_id)
	rescue
		raise_errormessage message,bot
		retry
	end

	agent_exist = @query_agent_exist_statement.execute(message.from.id)
	if agent_exist == 0
		bot.api.send_message chat_id: message.chat.id, text: "药丸药丸，快找豆腐丝 @tolves 修bug"
		return false
	end

	bot.api.send_message chat_id: message.from.id, text: "#{message.from.username}，你的信息已录入魔懒懒系统，请耐心等待approved"
end

#首页，不同权限看到不同按钮
def overview message,bot
	agent_exist = @query_agent_exist_statement.execute(message.from.id)
	if agent_exist.size == 0
		bot.api.send_message chat_id: message.from.id, text: '你尚未注册魔懒懒系统，输入 /start 开始注册'
		return false
	end

	agent_auth = @query_agent_auth_statement_by_telegram_id.execute(message.from.id).first

	overview_kb_a = [Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看自己信息', callback_data: 'overview_get_me')]
	case agent_auth['authority'].to_i
		when 3
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看活跃活动', callback_data: 'overview_available_activity')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我创建的活动', callback_data: 'overview_available_activity_created_byme')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我加入的活动', callback_data: 'overview_available_activity_joined_byme')
		when 4
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看活跃活动', callback_data: 'overview_available_activity')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我加入的活动', callback_data: 'overview_available_activity_joined_byme')
		when 5
		when 6
		else
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '审核特工', callback_data: 'overview_review_agent')
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '修改特工权限', callback_data: 'overview_modify_agent_auth')
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '新建活动', callback_data: 'overview_create_activity')
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看活跃活动', callback_data: 'overview_available_activity')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我创建的活动', callback_data: 'overview_available_activity_created_byme')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我加入的活动', callback_data: 'overview_available_activity_joined_byme')
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '存档的活动', callback_data: 'overview_archived_activity')
	end
	overview_kb = Array.new
	overview_kb_a.each_slice(3){|kb| overview_kb<<kb}
	overview_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: overview_kb)

	overview_welcome = "@#{message.from.username} 欢迎来到魔懒懒懒个不停咸个不停小分队大厅\n"
	overview_welcome << "请按照选择您要进行的操作\n"
	bot.api.send_message chat_id: message.from.id, text: overview_welcome, reply_markup: overview_makeup
end

#审核用户，目前基本上不存在没有权限还可以审核，但是以防万一吧
def review_waiting message,bot
	agent_auth = @query_agent_admin_statement.execute(message.from.id)
	if agent_auth.size == 0
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'少年郎你没有审核权限啦'
		return false
	end

	begin
		results = @client.query("SELECT count(agent_id) FROM users WHERE authority=6");
		if results.first['count(agent_id)'] < 1
			bot.api.answer_callback_query callback_query_id:message.id , text: '无未被审核特工'
			return false
		end
	rescue
		raise_errormessage message,bot
		retry
	end

	@current_page = 0
	waiting_list = @query_waiting_agent_statement.execute(@current_page)
	waiting_list_kb = Array.new

	waiting_list.each do |agent|
		waiting_list_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: agent['agent_id'], callback_data: "review_waiting_#{agent['agent_id']}")
	end

	waiting_list_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: waiting_list_kb)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'请选择你要审核的特工id', reply_markup: waiting_list_markup
end

#取得待审核特工当前信息
def get_waiting_detail message,bot
	agent_id = message.data.sub(/review_waiting_/ , "")
	waiting_agent = @query_agent_auth_statement_by_agent_id.execute("#{agent_id}")
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
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: waiting_agent_detail, reply_markup: approve_markup
end

#决定审核结果
def judgement_waiting message,bot
	judgement_statement = @client.prepare("UPDATE users SET authority=? WHERE agent_id=?")
	judge_kb = [
		Telegram::Bot::Types::InlineKeyboardButton.new(text: '继续审核', callback_data: "overview_review_agent")
	]
	judge_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: judge_kb)
	case message.data
		when /review_agent_approved_./
			agent_id = message.data.sub /review_agent_approved_/,""
			judgement_statement.execute(4,agent_id) #rookie
			judge_text = "#{agent_id} 已经通过审核"
		when /review_agent_refused_./
			agent_id = message.data.sub /review_agent_refused_/,""
			judgement_statement.execute(5,agent_id)  #untrusted
			judge_text = "#{agent_id} 未通过审核"
		when 'review_agent_back'
			review_waiting message,bot
			return
		else
			judge_text = "既然什么也不做，那就咸鱼一会儿吧"
	end
	@update_agent_updatedate_by_telegram_id.execute(message.from.id) #更新用户行为时间
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: judge_text, reply_markup: judge_markup
end

# 查看自己信息，需要和activity_user表联动，将来还有成就表
def get_me message,bot
	result = @client.query("SELECT * FROM users AS us LEFT JOIN profile AS pf ON us.telegram_id=pf.telegram_id WHERE us.telegram_id = #{message.from.id}")
	text ||= ''
	result.each do |agent|
		agent.each do |k,v|
			text << ("#{k} = #{v}\n")
		end
	end
	bot.api.send_message chat_id: message.from.id, text: text
end

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
	amend_text = "特工：#{agent_id} 权限已经更新\n点击 /go 返回大厅"
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: amend_text
end

#创建活动，由于需要三次输入，所以分三步，活动名，活动详情，活动密级。并且自动将当前用户设置为 此活动管理员
def create_activity message,bot
	agent_auth = @query_agent_admin_statement.execute(message.from.id)
	bot.logger.info(message.from.id)
	if agent_auth.size == 0
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'少年郎你没有创建权限啦'
		return false
	end
	bot.api.send_message chat_id: message.from.id, text: '请输入要创建的活动名称：', reply_markup:@force_reply
end


def create_activity_name message,bot
	activity_name = message.text.strip.encode(:xml => :text)
	activity_name_statement = @client.prepare("INSERT INTO activity (name,created_on,status) VALUES (?,\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",\"1\")")
	activity_user_statement = @client.prepare("INSERT INTO activity_users (activity_id,telegram_id,duty) VALUES (?,?,\"1\")")

	begin
		create_base_activity = activity_name_statement.execute(activity_name)
		# $last_id 为刚新建活动的id，需要对其进行update
		$last_id = l_id = @client.query("SELECT LAST_INSERT_ID()").first
		insert_activity_with_user = activity_user_statement.execute(l_id['LAST_INSERT_ID()'],message.from.id)
	rescue
		raise_errormessage message,bot
		retry
	end
	bot.api.send_message chat_id: message.from.id, text: '成功新建活动，请继续输入活动详情：', reply_markup:@force_reply
end


def create_activity_detail message,bot
	#防止用旧的语句进行回复，如果不是从 活动名称开始，就没有$last_id存在，那么无法进行提交，下面同理
	if $last_id.nil?
		bot.api.send_message chat_id: message.from.id, text: '发生了奇怪事件，点击 /go 返回，找豆腐丝豆腐丝也不修'
		return false
	end
	l_id = $last_id['LAST_INSERT_ID()']

	# bot.logger.info(l_id)
	activity_detail = message.text.strip.encode(:xml => :text)
	activity_detail_statement = @client.prepare("UPDATE activity SET detail=? WHERE id=?")

	begin
		create_activity_detail = activity_detail_statement.execute(activity_detail,l_id)
	rescue
		raise_errormessage message,bot
		retry
	end

	security_kb = security_level_keyboard
	security_makeup =  Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: security_kb)

	bot.api.send_message chat_id: message.from.id, text: '成功添加活动详情，请选择活动密级：', reply_markup: security_makeup
end


def create_activity_security_level message,bot
	if $last_id.nil?
		bot.api.send_message chat_id: message.from.id, text: '发生了奇怪事件，点击 /go 返回，找豆腐丝豆腐丝也不修'
		return false
	end
	l_id = $last_id['LAST_INSERT_ID()']
	security_level = message.data.split('_',3)[2]

	activity_security_statement = @client.prepare("UPDATE activity SET security=? WHERE id=?")

	begin
		create_activity_security = activity_security_statement.execute(security_level,l_id)
	rescue
		raise_errormessage message,bot
		retry
	end
	@update_agent_updatedate_by_telegram_id.execute(message.from.id)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: "成功设置活动密级，点击 /go 返回大厅"
end

#查看当前所有活跃的活动
def view_availalbe_activity message,bot
	availalbe_activities = @client.query("SELECT * FROM activity AS ay LEFT JOIN security AS secu ON ay.security=secu.id where status=1")
	acty_kb_a = Array.new
	availalbe_activities.each do |activity|
		bot.logger.info(activity)
		acty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: activity['name'], callback_data: "valid_activity_#{activity['id']}")
	end
	acty_kb = Array.new
	acty_kb_a.each_slice(2){|kb| acty_kb<<kb}
	acty_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: acty_kb)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'活跃活动列表：', reply_markup: acty_makeup
end

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