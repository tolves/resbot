
#创建活动，由于需要三次输入，所以分三步，活动名，活动详情，活动密级。并且自动将当前用户设置为 此活动管理员
def create_activity message,bot
	agent_auth = @query_agent_admin_statement.execute(message.from.id)
	if agent_auth.size == 0
    begin
      bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'少年郎你没有创建权限啦'
    rescue
      bot.api.send_message chat_id: message.from.id, text: '少年郎你没有创建权限啦'
    end
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
  begin
    bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: "成功设置活动密级，点击 /go 返回大厅"
  rescue
    bot.api.send_message chat_id: message.from.id, text: '成功设置活动密级，点击 /go 返回大厅'
  end
end

#查看活动,根据标签选择不同的query
def view_activities message,bot
	action = message.data.split('_',3)[2]
	if action=='created'
		activites_statement = @client.prepare("SELECT ay.id,ay.name,ay.status FROM activity AS ay LEFT JOIN activity_users AS au ON ay.id=au.activity_id WHERE au.duty=1 AND au.telegram_id=? ORDER BY ay.updated_on")
		begin
			activites = activites_statement.execute message.from.id
		rescue
			raise_errormessage
			retry
		end
	elsif action == 'joined'
		activites_statement = @client.prepare("SELECT ay.id,ay.name,ay.status FROM activity AS ay LEFT JOIN activity_users AS au ON ay.id=au.activity_id WHERE au.duty!=1 AND au.telegram_id=? AND ay.status!=0 ORDER BY ay.updated_on")
		begin
			activites = activites_statement.execute message.from.id
		rescue
			raise_errormessage
			retry
		end
	end
	if activites.size == 0
		bot.api.answer_callback_query callback_query_id:message.id , text: '没有任何活动'
		return false
	end
	acty_kb_a = Array.new
	activites.each do |activity|

		button_text = activity['name']
		if action=='created'
			status = activity['status'] == 0?'已存档':'活跃'
			button_text = "#{activity['name']} - #{status}"
		end

		acty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: button_text, callback_data: "view_activity_#{activity['id']}_#{action}")
	end
	acty_kb = Array.new
	acty_kb_a.each_slice(2){|kb| acty_kb<<kb}
	acty_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
	acty_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: acty_kb)
  begin
    bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'活动列表：', reply_markup: acty_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text:'活动列表：', reply_markup: acty_makeup
  end
end

#查看活动详情
def view_activity message,bot
	activity_id,action = message.data.split('_',4)[2,3]
	activity_detail = @query_activity_info.execute(activity_id)
	activity_joined_users = @query_activity_joined_users_by_activity_id.execute(activity_id)
	activity_organizer = @query_activity_organizer_users_by_activity_id.execute(activity_id)
	current_user = @query_activity_duty_by_activity_id.execute(activity_id,message.from.id).first
	organizer_text,joined_users_text = '',''
	activity_organizer.each do |user|
		organizer_text << "[#{user['agent_id']}](https://t.me/#{user['telegram_username']}) - #{user['duty_name']}\n"
	end

	activity_joined_users.each do |user|
		show_duty =  " - #{user['duty_name']}\n"
		if current_user['adid'] >= 3 #3为管理普通分界线
			show_duty =  "\n"
		end
		joined_users_text << "[#{user['agent_id']}](https://t.me/#{user['telegram_username']})#{show_duty}"
	end

	activity_detail = activity_detail.first
	detail_text = "活动名称：#{activity_detail['name']}\n"
	detail_text << "活动详情：#{activity_detail['detail']}\n"
	detail_text << "活动组织特工：\n"
	detail_text << organizer_text
	detail_text << "参与活动特工：\n"
	detail_text << joined_users_text

	acty_kb_a =Array.new

	if current_user['adid'] <= 2
		acty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "增加参与特工", callback_data: "activity_addagent_#{activity_id}")
		acty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "修改特工活动权限", callback_data: "activity_modagent_#{activity_id}")
		acty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "删除特工", callback_data: "activity_delagent_#{activity_id}")
		acty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "归档活动", callback_data: "activity_filing_#{activity_id}")
		acty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "活动广播", callback_data: "activity_noticeagent_#{activity_id}")
	end
	# 需要每一级加上action标签。很烦，所以注释掉了
	# acty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "overview_activities_#{action}")


	acty_kb = Array.new
	acty_kb_a.each_slice(2){|kb| acty_kb<<kb}
  acty_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
	ac_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: acty_kb)

  begin
    bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: detail_text , parse_mode: 'Markdown', disable_web_page_preview:true , reply_markup: ac_kb_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text: detail_text , parse_mode: 'Markdown', disable_web_page_preview:true , reply_markup: ac_kb_makeup
  end
end

#向活动添加人
def activity_addagent message,bot
	activity_id = message.data.sub(/activity_addagent_/ , "")
	@addagent = [activity_id,message.from.id]
	bot.api.send_message chat_id: message.from.id, text: '请输入特工游戏id，多人输入以","分割：', reply_markup:@force_reply
end

#正式进行添加，会判断是否使用旧的message
def addagent_into_activity message,bot
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
  acinfo = @query_activity_info.execute(@addagent[0]).first
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
      bot.api.send_message chat_id: agent_detail['telegram_id'], text: "您已被添加至活动：#{acinfo['name']}"
			@update_activity.execute @addagent[0]
      bot.api.send_message chat_id: message.from.id, text: "成功添加特工 #{agent_id} 至活动"
		rescue
			bot.api.send_message chat_id: message.from.id, text: "发生错误，联系豆腐丝 @tolves 修bug"
			next
		end
	end
	ac_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "view_activity_#{@addagent[0]}"),
	          Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]]
	ac_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: ac_kb)
	@addagent = nil
	bot.api.send_message chat_id: message.from.id , text: '特工添加完毕', reply_markup: ac_kb_makeup
end

#获得活动特工列表，然后进行操作，将修改、删除合二为一
def activity_agent_list message,bot,active
	activity_id = message.data.sub(/activity_(mod|del)agent_/ , "")
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

	acm_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "view_activity_#{activity_id}")
	acm_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
	acm_kb = Array.new
	acm_kb_a.each_slice(2){|kb| acm_kb<<kb}
	acm_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: acm_kb)
  begin
    bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'待修改特工列表：', reply_markup: acm_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text:'待修改特工列表：', reply_markup: acm_makeup
  end
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
	duty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "view_activity_#{activity_id}")
	duty_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")

	duty_kb = Array.new
	duty_kb_a.each_slice(3){|kb| duty_kb<<kb}
	acm_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: duty_kb)

  begin
    bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:"[#{target['agent_id']}](https://t.me/#{target['telegram_username']}) 当前职责：#{target['duty_name']}\n要将其修改为：", reply_markup: acm_makeup, parse_mode: 'Markdown', disable_web_page_preview:true
  rescue
    bot.api.send_message chat_id: message.from.id, text:"[#{target['agent_id']}](https://t.me/#{target['telegram_username']}) 当前职责：#{target['duty_name']}\n要将其修改为：", reply_markup: acm_makeup, parse_mode: 'Markdown', disable_web_page_preview:true
  end
end


def modagent_activity_duty message,bot
	activity_id,telegram_id,duty_id = message.data.split('_',5)[2..4]
	ac_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "view_activity_#{activity_id}"),
	          Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]]
	ac_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: ac_kb)
	begin
		@mod_activity_agent_duty_by_acid_and_telid.execute(duty_id,activity_id,telegram_id)
		@update_activity.execute activity_id
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: '特工修改完毕', reply_markup: ac_kb_makeup
  rescue
      bot.api.send_message chat_id: message.from.id,text: '特工修改完毕', reply_markup: ac_kb_makeup
	end
end


def delagent_activity message,bot
	activity_id,telegram_id,duty_id = message.data.split('_',6)[3..5]
	ac_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "view_activity_#{activity_id}"),
	          Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]]
	ac_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: ac_kb)
	begin
		@del_activity_agent_by_acid_and_telid_and_duty.execute(activity_id,telegram_id,duty_id)
		@update_activity.execute activity_id
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: '特工删除完毕', reply_markup: ac_kb_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text: '特工删除完毕', reply_markup: ac_kb_makeup
  end
end


def activity_noticeagent message,bot
	activity_id = message.data.sub(/activity_noticeagent_/ , "")
	@acid = activity_id
	bot.api.send_message chat_id: message.from.id, text: '请输入广播给活动内除组织者外所有成员的信息：', reply_markup:@force_reply
end


def notice_all_in_activity message,bot
	if @acid.nil?
		bot.api.send_message chat_id: message.from.id, text: '发生了奇怪的错误信息，点击 /go 返回大厅'
		return false
	end
	joined_users = @query_activity_joined_users_by_activity_id.execute(@acid)
	users_id = ''
	joined_users.each do |user|
		begin
			bot.api.send_message chat_id: user['telegram_id'], text: "来自 @#{message.from.username} 的活动广播，请勿于bot回复：\n"+message.text
			users_id << "[#{user['agent_id']}](https://t.me/#{user['telegram_username']}) ,"
		rescue
			bot.api.send_message chat_id: message.from.id , text: "[#{user['agent_id']}](https://t.me/#{user['telegram_username']}) 发送失败" ,parse_mode: 'Markdown', disable_web_page_preview:true
		end
	end
	ac_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回上一级", callback_data: "view_activity_#{@acid}"),
	          Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]]
	ac_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: ac_kb)
	bot.api.send_message chat_id: message.from.id , text: "向 #{users_id} \n发送广播:\n #{message.text} \n成功" ,parse_mode: 'Markdown', disable_web_page_preview:true, reply_markup: ac_kb_makeup
end


def activity_filing message,bot
	activity_id = message.data.sub(/activity_filing_/ , "")
	filing_acti = @client.prepare("UPDATE activity SET status=\"0\" WHERE id=?")
	begin
    filing_acti.execute activity_id
    @update_activity.execute activity_id
	rescue
		bot.api.send_message chat_id: message.from.id, text: '发生错误'
	end
	bot.api.answer_callback_query callback_query_id:message.id , text: '活动已成功归档'
end

