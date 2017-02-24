require_relative  'db_connect'
require_relative  'activity'
require_relative  'modify_authority'
require_relative  'resiger'
require_relative  'review'
require_relative  'func'
@conn = Db.new
@client = @conn.connect

@force_reply = Telegram::Bot::Types::ForceReply.new(force_reply: true, selective: true)

@query_agent_exist_statement = @client.prepare("SELECT agent_id,authority FROM users WHERE telegram_id = ?")#{message.from.id}
@query_ingressid_exist_statement = @client.prepare("SELECT agent_id FROM users WHERE agent_id = ?")
@query_agent_admin_statement = @client.prepare("SELECT agent_id FROM users WHERE telegram_id = ? AND authority in (1,2)")
@query_waiting_agent_statement = @client.prepare("SELECT agent_id,telegram_username FROM users WHERE authority = '6' ORDER BY 'created_on' LIMIT ?,7")
@query_agent_auth_statement_by_agent_id = @client.prepare("SELECT * FROM users AS us LEFT JOIN authority_name AS an ON us.authority=an.id  WHERE us.agent_id=?")
@query_agent_auth_statement_by_telegram_id = @client.prepare("SELECT *,an.name AS authname FROM users AS us LEFT JOIN authority_name AS an ON us.authority=an.id WHERE us.telegram_id = ?")
@query_id_by_telegram_id = @client.prepare("SELECT id,agent_id,telegram_id,telegram_username,authority FROM users WHERE telegram_id = ?")
@query_profile_by_telegram_id = @client.prepare("SELECT * FROM profile WHERE telegram_id=?")
@update_agent_updatedate_by_telegram_id = @client.prepare("UPDATE users SET updated_on=\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\" WHERE telegram_id=?")

query_created_byme = "ay.id,ay.name,ay.detail,ay.security,secu.security_name,ay.created_on,ay.updated_on,ay.status,ad.id AS adid,ad.duty_name"
query_created_byme_leftjoin = "LEFT JOIN activity_users AS au ON ay.id=au.activity_id LEFT JOIN activity_duty AS ad ON au.duty=ad.id LEFT JOIN security AS secu ON ay.security=secu.id"
@query_activity_info_created_byme_by_telegram_id = @client.prepare("SELECT #{query_created_byme} FROM activity AS ay #{query_created_byme_leftjoin} WHERE au.duty=1 AND au.telegram_id=? ORDER BY ay.updated_on")
@query_activity_created_byme_by_telegram_id = @client.prepare("SELECT ay.id,ay.name,ay.status FROM activity AS ay LEFT JOIN activity_users AS au ON ay.id=au.activity_id WHERE au.duty=1 AND au.telegram_id=? ORDER BY ay.updated_on")



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
			overview_kb_a<< Telegram::Bot::Types::InlineKeyboardButton.new(text: '存档的活动', callback_data: 'overview_archived_activity')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我创建的活动', callback_data: 'overview_available_activity_created_byme')
			overview_kb_a << Telegram::Bot::Types::InlineKeyboardButton.new(text: '查看我加入的活动', callback_data: 'overview_available_activity_joined_byme')
	end
	overview_kb = Array.new
	overview_kb_a.each_slice(3){|kb| overview_kb<<kb}
	overview_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: overview_kb)

	overview_welcome = "@#{message.from.username} ：\n欢迎来到魔懒懒懒个不停咸个不停小分队大厅嬉戏玩耍\n你现在权限为：#{agent_auth['authname']}\n"
	overview_welcome << "请按照选择您要进行的操作\n"
	begin
		#让修改就修改，不让改就转发送
		bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: overview_welcome, reply_markup: overview_makeup
	rescue
		bot.api.send_message chat_id: message.from.id, text: overview_welcome, reply_markup: overview_makeup
	end
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




