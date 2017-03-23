def view_achievements message,bot
  achi_kb_array =Array.new
    achievements = @client.query("SELECT * FROM achievement WHERE f_id=0 AND frequency=0")
  achievements.each do |achievement|
    achi_kb_array << Telegram::Bot::Types::InlineKeyboardButton.new(text: achievement['particular'], callback_data: "view_achievement_#{achievement['id']}")
  end
  user_auth = @query_agent_auth_statement_by_telegram_id.execute(message.from.id).first

  achi_kb = Array.new
  achi_kb_array.each_slice(2){|kb| achi_kb<<kb}
  if user_auth['authority']<3
    achi_kb << [Telegram::Bot::Types::InlineKeyboardButton.new(text: '添加新成就', callback_data: 'add_achievement'),
                Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回大厅', callback_data: 'back_overview')]
  else
    achi_kb << [Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回大厅', callback_data: 'back_overview')]
  end
  achi_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: achi_kb)
  begin
    bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: '当前所有成就列表，点击查看详情', reply_markup: achi_kb_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text: '当前所有成就列表，点击查看详情', reply_markup: achi_kb_makeup
  end

end


def view_achievement message,bot
  f_id = message.data.sub(/view_achievement_/ , "")
  instance_variable_set("@_am#{message.from.id}", [message.from.id,f_id])
  info = @client.query("SELECT * FROM achievement WHERE f_id=#{f_id} ORDER BY frequency")
  achievement = @client.query("SELECT * FROM achievement WHERE id=#{f_id} AND f_id=0 AND frequency=0")
  if achievement.size == 0
    bot.api.answer_callback_query callback_query_id:message.id , text: '出错啦'
    return false
  end
  achievement = achievement.first
  detail = '该成就不同级别的称号:\n'
  detail = "#{achievement['particular']}:\n"
  info.each do |achi|
    detail << "#{achi['frequency']} => #{achi['title']} \n"
  end
  detail << "\n本项成就top5：\n"
  top5 = @client.query("SELECT * FROM profile WHERE achievement_id=#{f_id} ORDER BY achievement_frequency DESC LIMIT 5")
  detail << top5.map { |user|
    agent = @query_id_by_telegram_id.execute(user['telegram_id']).first
    "#{agent['agent_id']} => #{user['achievement_frequency']}"
  }.join("\n")

  achi_kb = Array.new
  user_auth = @query_agent_auth_statement_by_telegram_id.execute(message.from.id).first
  if user_auth['authority']<3
    achi_kb << [Telegram::Bot::Types::InlineKeyboardButton.new(text: '添加新数量级与对应称号', callback_data: "add_title"),
                Telegram::Bot::Types::InlineKeyboardButton.new(text: '修改数量级与对应称号', callback_data: "modify_title")]
  end
  achi_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: '已完成此项成就', callback_data: "add_myachievement_#{f_id}")
  achi_kb << [Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回成就列表', callback_data: "overview_achievement"),Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]
  achi_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: achi_kb)
  begin
    bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: detail, reply_markup: achi_kb_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text: detail, reply_markup: achi_kb_makeup
  end

end


def add_myachievement message,bot
  f_id = message.data.sub(/add_myachievement_/ , "")
  instance_variable_set("@_am#{message.from.id}", [message.from.id,f_id])
  if f_id.nil?
    begin
      bot.api.answer_callback_query callback_query_id:message.id , text: '发生错误'
      return false
    rescue
      bot.api.send_message chat_id: message.from.id, text: "发生错误"
      return false
    end

  end
  bot.api.send_message chat_id: message.from.id, text: "成就系统中的数值就是由特工自行输入\n所以希望大家如实填写"
  bot.api.send_message chat_id: message.from.id, text: "请输入你在本项成就中完成的数值\n某些值为boolean的成就，输入1即可", reply_markup:@force_reply
end


def add_myachievement_frequency message,bot
  m_id = instance_variable_get("@_am#{message.from.id}")
  bot.logger.info(m_id.inspect)
  if m_id.nil? || m_id[0]!=message.from.id
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  frequency = message.text.strip
  frequency = frequency.to_i
  if frequency.class != Fixnum || frequency == '' || frequency == 0
    bot.api.send_message chat_id:message.from.id , text: '必须输入数字'
    bot.api.send_message chat_id: message.from.id, text: "请输入你在本项成就中完成的数值\n某些值为boolean的成就，输入1即可", reply_markup:@force_reply
    return false
  end
  achi_exist = @query_myachievement_exist.execute message.from.id,m_id[1]
  update_myachie = @client.prepare("UPDATE profile SET achievement_frequency=? WHERE telegram_id=? AND achievement_id=?")
  insert_myachie = @client.prepare("INSERT INTO profile (telegram_id,achievement_id,achievement_frequency) VALUES (?,?,?)")

  achi_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回成就详情', callback_data: "view_achievement_#{m_id[1]}"),Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回成就列表', callback_data: "overview_achievement"),Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回大厅', callback_data: "back_overview")]]
  achi_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: achi_kb)

  begin
    if achi_exist.size!=0
        update_myachie.execute frequency,message.from.id,m_id[1]
    elsif achi_exist.size==0
        insert_myachie.execute message.from.id,m_id[1],frequency
    end
    bot.api.send_message chat_id: message.from.id, text: "当前成就统计已更新", reply_markup: achi_kb_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text: "哎呀呀呀出错辣，快小窗敲豆腐丝 @tolves，反正敲了也不会修"
    return false
  end
end


def add_title message,bot
  m_id = instance_variable_get("@_am#{message.from.id}")
  if m_id.nil?
    bot.api.answer_callback_query callback_query_id:message.id , text: '发生错误'
    return false
  end
  bot.api.send_message chat_id: message.from.id, text: "请输入要新增数量级与称号\n格式为：数量=>称号\n例如：2=>大魔王\n某些值为boolean的成就，可设置为1=>称号", reply_markup:@force_reply
end


def add_frequency_title message,bot
  m_id = instance_variable_get("@_am#{message.from.id}")
  if m_id.nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  frequency,title = message.text.strip.split('=>',2)
  frequency = frequency.to_i
  if frequency.class != Fixnum || frequency == ''
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  if title.class != String || title==''
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  title_exist = @query_title_exist.execute m_id[1],frequency
  if title_exist.size!=0
    bot.api.send_message chat_id:message.from.id , text: '该数量级已经存在，请再次输入'
    bot.api.send_message chat_id: message.from.id, text: "请输入要新增数量级与称号\n格式为：数量=>称号\n例如：2=>大魔王", reply_markup:@force_reply
    return false
  end
  achi_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回成就详情', callback_data: "view_achievement_#{m_id[1]}"),Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回成就列表', callback_data: "overview_achievement"),Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回大厅', callback_data: "back_overview")]]
  achi_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: achi_kb)
  begin
    @insert_achievement_title.execute m_id[1],frequency,title
    bot.api.send_message chat_id: message.from.id, text: "新的数量级与称号输入成功", reply_markup: achi_kb_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text: "哎呀呀呀出错辣，快小窗敲豆腐丝 @tolves，反正敲了也不会修"
    return false
  end
end


def modify_title message,bot
  m_id = instance_variable_get("@_am#{message.from.id}")
  if m_id.nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  bot.api.send_message chat_id: message.from.id, text: "请输入要修改的数量级与称号中的数量级：", reply_markup:@force_reply
end


def modify_frequency_title message,bot
  m_id = instance_variable_get("@_am#{message.from.id}")
  if m_id.nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  frequency = message.text.to_i
  instance_variable_set("@_am#{message.from.id}", [message.from.id,m_id[1],frequency])
  if frequency==0
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  exist = @query_title_exist.execute m_id[1],frequency
  if exist.size !=1
    bot.api.send_message chat_id:message.from.id , text: '该数量级不存在，请再次输入'
    bot.api.send_message chat_id: message.from.id, text: "请输入要修改的数量级与称号中的数量级：", reply_markup:@force_reply
    return false
  end
  bot.api.send_message chat_id: message.from.id, text: "请输入要修改的数量级与称号\n格式为：数量=>称号\n例如：2=>大魔王", reply_markup:@force_reply
end


def modify_frequency_and_title message,bot
  m_id = instance_variable_get("@_am#{message.from.id}")
  if m_id.nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  if m_id[2].nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  mod_frequency,title = message.text.strip.split('=>',2)
  mod_frequency = mod_frequency.to_i
  if mod_frequency.class != Fixnum || mod_frequency == ''
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  if title.class != String || title==''
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  achi_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回成就详情', callback_data: "view_achievement_#{m_id[1]}"),Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回成就列表', callback_data: "overview_achievement"),Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回大厅', callback_data: "back_overview")]]
  achi_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: achi_kb)
  begin
    @update_achievement_title.execute mod_frequency,title,m_id[1],m_id[2]
    bot.api.send_message chat_id: message.from.id, text: "数量级与称号修改成功"  , reply_markup: achi_kb_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text: "哎呀呀呀出错辣，快小窗敲豆腐丝 @tolves，反正敲了也不会修"
    return false
  end
end


def add_achievement message,bot
  bot.api.send_message chat_id: message.from.id, text: "请输入新增加的成就描述：", reply_markup:@force_reply
end


def add_achievement_particular message,bot
  particular = message.text.strip
  achi_kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: '继续添加', callback_data: "add_achievement"),Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回成就列表', callback_data: "overview_achievement"),Telegram::Bot::Types::InlineKeyboardButton.new(text: '返回大厅', callback_data: "back_overview")]]
  achi_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: achi_kb)
  begin
    @insert_achievement_particular.execute particular
    bot.api.send_message chat_id: message.from.id, text: "新增成就成功", reply_markup: achi_kb_makeup
  rescue

  end
end