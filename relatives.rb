require_relative  'db_connect'
require_relative  'activity'
require_relative  'modify_authority'
require_relative  'resiger'
require_relative  'review'
require_relative  'func'
require_relative  'statement'
require_relative  'duty'
require_relative  'achievement'

@force_reply = Telegram::Bot::Types::ForceReply.new(force_reply: true, selective: true)


#首页，不同权限看到不同按钮
def overview message,bot
	agent_exist = @query_agent_exist_statement.execute(message.from.id)
	if agent_exist.size == 0
		begin
			bot.api.send_message chat_id: message.from.id, text: '你尚未注册魔懒懒系统，输入 /start 开始注册'
			return false
		rescue
			bot.api.send_message chat_id: message.chat.id, text: '你尚未注册魔懒懒系统，请先小窗bot /start 开始，要不然收不到信息的哟'
		end

	end

	agent_auth = @query_agent_auth_statement_by_telegram_id.execute(message.from.id).first

	overview_kb_a = [Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看自己信息', callback_data: 'overview_get_me')]
	case agent_auth['authority'].to_i
		when 1
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '审核特工', callback_data: 'overview_review_agent')
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '修改特工权限', callback_data: 'overview_modify_agent_auth')
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '新建活动', callback_data: 'overview_create_activity')
			# overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看活跃活动', callback_data: 'overview_activities_available')
			# overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '存档的活动', callback_data: 'overview_archived_activity')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我创建的活动', callback_data: 'overview_activities_created')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我加入的活动', callback_data: 'overview_activities_joined')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '活动内特工职责', callback_data: 'overview_agent_duty')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '成就系统', callback_data: 'overview_achievement')
		when 2
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '审核特工', callback_data: 'overview_review_agent')
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '修改特工权限', callback_data: 'overview_modify_agent_auth')
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '新建活动', callback_data: 'overview_create_activity')
			# overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看活跃活动', callback_data: 'overview_activities_available')
			# overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '存档的活动', callback_data: 'overview_archived_activity')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我创建的活动', callback_data: 'overview_activities_created')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我加入的活动', callback_data: 'overview_activities_joined')
		when 3
			# overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看活跃活动', callback_data: 'overview_activities_available')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我创建的活动', callback_data: 'overview_activities_created')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我加入的活动', callback_data: 'overview_activities_joined')
		when 4
			# overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看活跃活动', callback_data: 'overview_activities_available')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我加入的活动', callback_data: 'overview_activities_joined')
		when 5
		when 6
		else

	end
	overview_kb = Array.new
	overview_kb_a.each_slice(3){|kb| overview_kb<<kb}
	overview_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: overview_kb)

	overview_welcome = "欢迎来到魔懒懒懒个不停咸个不停小分队大厅嬉戏玩耍\n你现在权限为：_#{agent_auth['authname']}_\n"
	overview_welcome << "请按照选择您要进行的操作\n"
	begin
		#让修改就修改，不让改就转发送
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: overview_welcome, reply_markup: overview_makeup, parse_mode: 'Markdown'
	rescue
		bot.api.send_message chat_id: message.from.id, text: overview_welcome, reply_markup: overview_makeup, parse_mode: 'Markdown'
	end
end



# 查看自己信息，需要和activity_user表联动，将来还有成就表
def get_me message,bot
	detail ||= ''
	user = @client.query("SELECT * from users WHERE telegram_id=#{message.from.id}")
	if user.size == 0
		bot.api.answer_callback_query callback_query_id:message.id , text: '发生错误'
		return false
	end
	user = user.first
	detail << "*游戏ID*：[#{user['agent_id']}](https://t.me/#{user['telegram_username']}) \n"

	activities = @client.query("SELECT *,ad.duty_name,ad.id as adid,ay.name,security FROM activity_users AS au LEFT JOIN activity_duty AS ad ON au.duty=ad.id LEFT JOIN activity AS ay ON au.activity_id=ay.id WHERE au.telegram_id=#{message.from.id} AND ay.status=0")
	if activities.size!=0
		detail << "\n*参与活动：*\n"
		activities.each do |activity|
			detail << "#{activity['name']} - *#{activity['duty_name']}*\n"
		end
	end

	achievements = @client.query("SELECT *,am.frequency,am.particular,am.title FROM profile AS pf LEFT JOIN achievement AS am ON pf.achievement_id=am.id WHERE pf.telegram_id=#{message.from.id} AND am.f_id=0 AND am.frequency=0")
	ach_title_statement = @client.prepare("SELECT * FROM achievement AS am WHERE am.f_id=? AND am.frequency<? ORDER BY am.frequency DESC LIMIT 1 ")
	if achievements.size!=0
		detail << "\n*成就：*\n"
		achievements.each do |achievement|
			ach_title = ach_title_statement.execute(achievement['achievement_id'],achievement['achievement_frequency'])
			next if ach_title.size == 0
			ach_title = ach_title.first
			detail << "*#{ach_title['title']}*\n"
		end
	end

	kb = Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
	makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
	bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: detail , parse_mode: 'Markdown', disable_web_page_preview:true, reply_markup: makeup
end




