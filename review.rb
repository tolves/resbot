#审核用户，目前基本上不存在没有权限还可以审核，但是以防万一吧
def review_waiting message,bot
	agent_auth = @query_agent_admin_statement.execute(message.from.id)
	if agent_auth.size == 0
		begin
			bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'少年郎你没有审核权限啦'
		rescue
			bot.api.send_message chat_id: message.from.id, text:'少年郎你没有审核权限啦'
		end

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

	begin
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text:'请选择你要审核的特工id', reply_markup: waiting_list_markup
	rescue
		bot.api.send_message chat_id: message.from.id, text:'请选择你要审核的特工id', reply_markup: waiting_list_markup
	end
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
	waiting_agent_detail = "被审核特工 ingress id： #{waiting_agent['agent_id']}\n"
	waiting_agent_detail << "被审核特工 telegram id： @#{waiting_agent['telegram_username']}\n"
	waiting_agent_detail << "请谨慎审核该特工是否是可信特工\n"

	begin
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: waiting_agent_detail, reply_markup: approve_markup
	rescue
		bot.api.send_message chat_id: message.from.id, text: waiting_agent_detail, reply_markup: approve_markup
	end
end

#决定审核结果
def judgement_waiting message,bot
	judgement_statement = @client.prepare("UPDATE users SET authority=? WHERE agent_id=?")
	judge_kb = [
			Telegram::Bot::Types::InlineKeyboardButton.new(text: '继续审核', callback_data: "overview_review_agent"),
			Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
	]
	judge_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [judge_kb])
	case message.data
		when /review_agent_approved_./
			agent_id = message.data.sub /review_agent_approved_/,""
			waiting_agent = @query_agent_auth_statement_by_agent_id.execute("#{agent_id}").first
			judgement_statement.execute(4,agent_id) #rookie
      bot.api.send_message chat_id: waiting_agent["telegram_id"], text: '恭喜，你已经被审核通过，现在点击 /go 开始浏览吧'
			judge_text = "#{agent_id} 已经通过审核"
		when /review_agent_refused_./
			agent_id = message.data.sub /review_agent_refused_/,""
			waiting_agent = @query_agent_auth_statement_by_agent_id.execute("#{agent_id}").first
			judgement_statement.execute(5,agent_id)  #untrusted
      bot.api.send_message chat_id: waiting_agent["telegram_id"], text: '很遗憾，你未被审核通过'
			judge_text = "#{agent_id} 未通过审核"
		when 'review_agent_back'
			review_waiting message,bot
			return
		else
			judge_text = "既然什么也不做，那就咸鱼一会儿吧"
	end
	@update_agent_updatedate_by_telegram_id.execute(message.from.id) #更新用户行为时间
	begin
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: judge_text, reply_markup: judge_markup
	rescue
		bot.api.send_message chat_id: message.from.id, text: judge_text, reply_markup: judge_markup
	end

end