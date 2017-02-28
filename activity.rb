
#创建活动，由于需要三次输入，所以分三步，活动名，活动详情，活动密级。并且自动将当前用户设置为 此活动管理员
def create_activity message,bot
	agent_auth = @query_agent_admin_statement.execute(message.from.id)
	if agent_auth.size == 0
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'少年郎你没有创建权限啦'
		return false
	end
	bot.api.send_message chat_id: message.from.id, text: '请输入要创建的活动名称：', reply_markup:@force_reply
end


def create_activity_name message,bot
	activity_name = message.text.strip.encode(:xml => :text)
	@activity = [activity_name]
	bot.api.send_message chat_id: message.from.id, text: '成功新建活动，请继续输入活动详情：', reply_markup:@force_reply
end


def create_activity_detail message,bot
	if @activity.nil?
		bot.api.send_message chat_id: message.from.id, text: '发生了豆腐丝不想看见的事件，点击 /go 返回，找豆腐丝豆腐丝也不修'
		return false
	end
	activity_detail = message.text.strip.encode(:xml => :text)
	@activity << activity_detail

	security_kb = security_level_keyboard
	security_makeup =  Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: security_kb)

	bot.api.send_message chat_id: message.from.id, text: '成功添加活动详情，请选择活动密级：', reply_markup: security_makeup
end


def create_activity_security_level message,bot
	if @activity.nil?
		bot.api.send_message chat_id: message.from.id, text: '发生了豆腐丝不想看见的事件，点击 /go 返回，找豆腐丝豆腐丝也不修'
		return false
	end
	security_level = message.data.split('_',3)[2]
	@activity << security_level

	activity_statement = @client.prepare("INSERT INTO activity (name,detail,security,created_on,updated_on,status) VALUES (?,?,?,\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\",\"1\")")
	activity_user_statement = @client.prepare("INSERT INTO activity_users (activity_id,telegram_id,duty) VALUES (?,?,\"1\")")

	begin
		activity_statement.execute(@activity[0],@activity[1],@activity[2])
		l_id = @client.query("SELECT LAST_INSERT_ID()").first
		activity_user_statement.execute(l_id['LAST_INSERT_ID()'],message.from.id)
		@update_agent_updatedate_by_telegram_id.execute(message.from.id)
		@activity = nil
	rescue
		raise_errormessage message,bot
		retry
	end

	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: "成功设置活动密级，点击 /go 返回大厅"
end

#查看当前所有活跃的活动
def view_availalbe_activities message,bot
	availalbe_activities = @client.query("SELECT * FROM activity AS ay LEFT JOIN security AS secu ON ay.security=secu.id where status=1")
	acty_kb_a = Array.new
	availalbe_activities.each do |activity|
		acty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: activity['name'], callback_data: "valid_activity_#{activity['id']}")
	end
	acty_kb = Array.new
	acty_kb_a.each_slice(2){|kb| acty_kb<<kb}
	acty_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: acty_kb)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'活跃活动列表：', reply_markup: acty_makeup
end

#查看我创建的活动
def view_activities_created_byme message,bot
	activities = @query_activity_created_byme_by_telegram_id.execute message.from.id
	acty_creabyme_kb = Array.new

	activities.each do |activity|
		status = activity['status'] == 0?'已存档':'活跃'
		acty_creabyme_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{activity['name']} - #{status}", callback_data: "valid_activities_created_byme_#{activity['id']}")
	end
	acty_creabyme_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
	acty_creabyme_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: acty_creabyme_kb)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'我创建的活动：', reply_markup: acty_creabyme_makeup
end

#查看活动详情
def view_activity_created_byme message,bot
	activity_id = message.data.sub(/valid_activities_created_byme_/ , "")
	activity_detail = @query_activity_info_created_byme_by_activity_id.execute(activity_id)
	activity_joined_users = @query_activity_joined_users_by_activity_id.execute(activity_id)
	activity_organizer = @query_activity_organizer_users_by_activity_id.execute(activity_id)

	ac_kb,organizer,joined_users,organizer_text,joined_users_text = Array.new,Array.new,Array.new,'',''
	activity_organizer.each do |user|
		organizer << [:username => user['telegram_username'],
		              :agent_id => user['agent_id'],
		              :duty => user['duty_name'],
		              :authority => user['name']]
		organizer_text << "[#{user['agent_id']}](https://t.me/#{user['telegram_username']}) - #{user['duty_name']}\n"
	end

	activity_joined_users.each do |user|
		joined_users << [:username => user['telegram_username'],
		                 :agent_id => user['agent_id'],
		                 :duty => user['duty_name'],
		                 :authority => user['name']]
		joined_users_text << "[#{user['agent_id']}](https://t.me/#{user['telegram_username']}) - #{user['duty_name']}\n"
	end

	activity_detail = activity_detail.first
	detail_text = "活动名称：#{activity_detail['name']}\n"
	detail_text << "活动详情：#{activity_detail['name']}\n"
	detail_text << "活动组织特工：\n"
	detail_text << organizer_text
	detail_text << "参与活动特工：\n"
	detail_text << joined_users_text
	ac_kb = [
		[
				Telegram::Bot::Types::InlineKeyboardButton.new(text: "增加参与特工", callback_data: "activity_addagent_created_byme_#{activity_id}"),
				Telegram::Bot::Types::InlineKeyboardButton.new(text: "修改特工活动权限", callback_data: "activity_modagent_created_byme_#{activity_id}")
		],
    [
				Telegram::Bot::Types::InlineKeyboardButton.new(text: "删除特工", callback_data: "activity_delagent_created_byme_#{activity_id}"),
				Telegram::Bot::Types::InlineKeyboardButton.new(text: "活动广播", callback_data: "activity_noticeagent_created_byme_#{activity_id}")
		],
		[
				Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "overview_available_activity_created_byme"),          Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
		]]
	ac_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: ac_kb)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: detail_text , parse_mode: 'Markdown', disable_web_page_preview:true , reply_markup: ac_kb_makeup
end

#向活动添加人
def activity_addagent_created_byme message,bot
	activity_id = message.data.sub(/activity_addagent_created_byme_/ , "")
	@addagent = [activity_id,message.from.id]
	bot.api.send_message chat_id: message.from.id, text: '请输入特工游戏id，多人输入以","分割：', reply_markup:@force_reply
end

#正式进行添加，会判断是否使用旧的message
def addagent_activity message,bot
	if @addagent.nil?
		bot.api.send_message chat_id: message.from.id, text: '发生错误，输入 /go 返回大厅'
		return false
	end
	if @addagent[0].nil?
		bot.api.send_message chat_id: message.from.id, text: '发生错误，输入 /go 返回大厅'
		return false
	end
	if @addagent[1] != message.from.id
		bot.api.send_message chat_id: message.from.id, text: '发生错误，输入 /go 返回大厅'
		return false
	end

	users_agentid = message.text.strip.split(',')
	users_agentid.each do |agent_id|
		agent_detail = @query_ingressid_exist_statement.execute agent_id
		if agent_detail.size == 0
			bot.api.send_message chat_id: message.from.id, text: "特工 #{agent_id} 尚未注册本系统，请提醒注册"
			next
		end
		agent_detail = agent_detail.first
		begin
			@insert_addagent_activity.execute @addagent[0],agent_detail['telegram_id'],5
			@update_activity.execute @addagent[0]
			bot.api.send_message chat_id: message.from.id, text: "成功添加特工 #{agent_id} 至活动"
		rescue
			bot.api.send_message chat_id: message.from.id, text: "发生错误，联系豆腐丝 @tolves 修bug"
			next
		end
	end
	ac_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "valid_activities_created_byme_#{@addagent[0]}"),
	          Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]]
	ac_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: ac_kb)
	bot.api.send_message chat_id: message.from.id , text: '特工添加完毕', reply_markup: ac_kb_makeup
end

#获得活动特工列表，然后进行操作，将修改、删除合二为一
def activity_agent_list message,bot,active
	activity_id = message.data.sub(/activity_(mod|del)agent_created_byme_/ , "")
	activity_joined_users = @query_activity_joined_users_by_activity_id.execute(activity_id)

	duty = @query_activity_duty_by_activity_id.execute(activity_id,message.from.id).first

	acm_kb_a = Array.new

	if duty['duty'] == 1
		activity_organizer = @query_activity_organizer_users_by_activity_id.execute(activity_id)
		activity_organizer.each do |user|
			next if user['telegram_id'] == message.from.id
			acm_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{user['agent_id']}-#{user['duty_name']}", callback_data: "agent_activity_#{active}_#{activity_id}_#{user['telegram_id']}_#{user['duty']}")
		end
	end

	activity_joined_users.each do |user|
		acm_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{user['agent_id']}-#{user['duty_name']}", callback_data: "agent_activity_#{active}_#{activity_id}_#{user['telegram_id']}_#{user['duty']}")
	end

	acm_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "选择全部", callback_data: "agent_activity_#{active}_all") if active == 'notice'

	acm_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "valid_activities_created_byme_#{activity_id}")
	acm_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
	acm_kb = Array.new
	acm_kb_a.each_slice(2){|kb| acm_kb<<kb}
	acm_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: acm_kb)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'待修改特工列表：', reply_markup: acm_makeup
end


def modagent_activity message,bot
	activity_id,telegram_id = message.data.split('_',6)[3,4]
	duty_kb_a =Array.new
	all_duties = @client.query("SELECT * FROM activity_duty")
	current_duty = @query_activity_duty_by_activity_id.execute(activity_id,message.from.id).first
	target = @query_activity_duty_by_activity_id.execute(activity_id,telegram_id).first
	all_duties.each do |duty|
		next if current_duty['adid']>=duty['id']
		next if target['adid'] == duty['id']
		duty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: duty['duty_name'], callback_data: "duty_level_#{activity_id}_#{telegram_id}_#{duty['id']}")
	end
	duty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "valid_activities_created_byme_#{activity_id}")
	duty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")

	duty_kb = Array.new
	duty_kb_a.each_slice(3){|kb| duty_kb<<kb}
	acm_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: duty_kb)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:"[#{target['agent_id']}](https://t.me/#{target['telegram_username']}) 当前职责：#{target['duty_name']}\n要将其修改为：", reply_markup: acm_makeup, parse_mode: 'Markdown', disable_web_page_preview:true
end


def modagent_activity_duty message,bot
	activity_id,telegram_id,duty_id = message.data.split('_',5)[2..4]
	ac_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "valid_activities_created_byme_#{activity_id}"),
	          Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]]
	ac_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: ac_kb)
	begin
		@mod_activity_agent_duty_by_acid_and_telid.execute(duty_id,activity_id,telegram_id)
		@update_activity.execute activity_id
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: '特工修改完毕', reply_markup: ac_kb_makeup
	rescue
	end
end


def delagent_activity message,bot
	activity_id,telegram_id,duty_id = message.data.split('_',6)[3..5]
	ac_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "valid_activities_created_byme_#{activity_id}"),
	          Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]]
	ac_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: ac_kb)
	begin
		@del_activity_agent_by_acid_and_telid_and_duty.execute(activity_id,telegram_id,duty_id)
		@update_activity.execute activity_id
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: '特工删除完毕', reply_markup: ac_kb_makeup
	rescue
	end
end


def noticeagent_activity message,bot
	activity_id = message.data.sub(/activity_noticeagent_created_byme_/ , "")
	@acid = activity_id
	bot.api.send_message chat_id: message.from.id, text: '请输入广播给活动内除组织者外所有成员的信息：', reply_markup:@force_reply
end


def notice_allagent_inacty message,bot
	if @acid.nil?
		bot.api.send_message chat_id: message.from.id, text: '发生了奇怪的错误信息，点击 /go 返回大厅'
		return false
	end
	joined_users = @query_activity_joined_users_by_activity_id.execute(@acid)
	users_id = ''
	joined_users.each do |user|
		begin
			bot.api.send_message chat_id: user['telegram_id'], text: message.text
			users_id << "[#{user['agent_id']}](https://t.me/#{user['telegram_username']}) ,"
		rescue
			bot.api.send_message chat_id: message.from.id , text: "[#{user['agent_id']}](https://t.me/#{user['telegram_username']}) 发送失败" ,parse_mode: 'Markdown', disable_web_page_preview:true
		end
	end
	bot.api.send_message chat_id: message.from.id , text: "向 #{users_id} 发送广播信息:\n #{message.text} \n成功" ,parse_mode: 'Markdown', disable_web_page_preview:true
end