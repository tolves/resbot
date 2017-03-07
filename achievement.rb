def view_achievements message,bot
  achi_kb_array =Array.new
    achievements = @client.query("SELECT * FROM achievement WHERE f_id=0 AND frequency=0")
  achievements.each do |achievement|
    achi_kb_array << Telegram::Bot::Types::InlineKeyboardButton.new(text: achievement['particular'], callback_data: "view_achievement_#{achievement['id']}")
  end
  achi_kb = Array.new
  achi_kb_array.each_slice(2){|kb| achi_kb<<kb}
  achi_kb << [Telegram::Bot::Types::InlineKeyboardButton.new(text: '添加新成就', callback_data: "add_achievement"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]
  achi_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: achi_kb)
  bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: '当前所有成就列表，点击查看详情', reply_markup: achi_kb_makeup
end


def view_achievement message,bot
  @f_id = f_id = message.data.sub(/view_achievement_/ , "")
  info = @client.query("SELECT * FROM achievement WHERE f_id=#{f_id}")
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
  achi_kb = Array.new
  achi_kb << [Telegram::Bot::Types::InlineKeyboardButton.new(text: '添加新数量级与对应称号', callback_data: "add_title"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: '修改数量级与对应称号', callback_data: "modify_title")]
  achi_kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")
  achi_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: achi_kb)
  bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: detail, reply_markup: achi_kb_makeup
end


def add_title message,bot
  if @f_id.nil?
    bot.api.answer_callback_query callback_query_id:message.id , text: '发生错误'
    return false
  end
  bot.api.send_message chat_id: message.from.id, text: "请输入要新增数量级与称号\n格式为：数量=>称号\n例如：2=>大魔王", reply_markup:@force_reply
end


def add_frequency_title message,bot
  if @f_id.nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  frequency,title = message.text.strip.split('=>',2)
  frequency = frequency.to_i
  if frequency.class != Fixnum || frequency == ''
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    @f_id = nil
    return false
  end
  if title.class != String || title==''
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    @f_id = nil
    return false
  end
  title_exist = @query_title_exist.execute @f_id,frequency
  if title_exist.size!=0
    bot.api.send_message chat_id:message.from.id , text: '该数量级已经存在，请再次输入'
    bot.api.send_message chat_id: message.from.id, text: "请输入要新增数量级与称号\n格式为：数量=>称号\n例如：2=>大魔王", reply_markup:@force_reply
    return false
  end
  begin
    @insert_achievement_title.execute @f_id,frequency,title
    bot.api.send_message chat_id: message.from.id, text: "新的数量级与称号输入成功,点击 /go 返回大厅(其实还可以返回成就"
    @f_id = nil
  rescue
    bot.api.send_message chat_id: message.from.id, text: "哎呀呀呀出错辣，快小窗敲豆腐丝 @tolves，反正敲了也不会修"
    return false
  end
end


def modify_title message,bot
  if @f_id.nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  bot.api.send_message chat_id: message.from.id, text: "请输入要修改的数量级与称号中的数量级：", reply_markup:@force_reply
end


def modify_frequency_title message,bot
  if @f_id.nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  @frequency = frequency = message.text.to_i
  if frequency==0
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    @f_id = nil
    return false
  end
  exist = @query_title_exist.execute @f_id,frequency
  if exist.size !=1
    bot.api.send_message chat_id:message.from.id , text: '该数量级不存在，请再次输入'
    bot.api.send_message chat_id: message.from.id, text: "请输入要修改的数量级与称号中的数量级：", reply_markup:@force_reply
    return false
  end
  bot.api.send_message chat_id: message.from.id, text: "请输入要修改的数量级与称号\n格式为：数量=>称号\n例如：2=>大魔王", reply_markup:@force_reply
end


def modify_frequency_and_title message,bot

  if @f_id.nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    return false
  end
  if @frequency.nil?
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    @f_id = nil
    return false
  end
  mod_frequency,title = message.text.strip.split('=>',2)
  mod_frequency = mod_frequency.to_i
  if mod_frequency.class != Fixnum || mod_frequency == ''
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    @f_id = nil
    return false
  end
  if title.class != String || title==''
    bot.api.send_message chat_id:message.from.id , text: '发生错误'
    @f_id = nil
    return false
  end

  begin
    @update_achievement_title.execute mod_frequency,title,@f_id,@frequency
    bot.api.send_message chat_id: message.from.id, text: "数量级与称号修改成功,点击 /go 返回大厅(其实还可以返回成就"
    @f_id = nil
    @frequency = nil
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
  begin
    @insert_achievement_particular.execute particular
    bot.api.send_message chat_id: message.from.id, text: "新增成就成功，点击 /go 返回大厅"
  rescue

  end
end