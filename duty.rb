def view_duty message,bot
  duty_kb_array =Array.new
  duties = @client.query("SELECT * FROM activity_duty")
  duties.each do |duty|
    duty_kb_array << Telegram::Bot::Types::InlineKeyboardButton.new(text: duty['duty_name'], callback_data: "none")
  end
  duty_kb = Array.new
  duty_kb_array.each_slice(3){|kb| duty_kb<<kb}
  duty_kb << [Telegram::Bot::Types::InlineKeyboardButton.new(text: '添加新活动职责', callback_data: "add_duty"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "返回大厅", callback_data: "back_overview")]
  duty_kb_makeup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: duty_kb)
  begin
    bot.api.edit_message_text chat_id: message.from.id, message_id:message.message.message_id, text: '当前所有活动内职责列表', reply_markup: duty_kb_makeup
  rescue
    bot.api.send_message chat_id: message.from.id, text: '当前所有活动内职责列表', reply_markup: duty_kb_makeup
  end
end


def add_duty message,bot
  bot.api.send_message chat_id: message.from.id, text: '请输入要新增的活动职责：', reply_markup:@force_reply
end


def create_new_duty message,bot
  duty = message.text.strip
  begin
    @insert_duty.execute duty
    bot.api.send_message chat_id: message.from.id, text: "成功添加活动职责：#{duty} ,点击 /go 返回大厅(懒得写按钮了)"
    @update_agent_updatedate_by_telegram_id.execute message.from.id
  rescue
    bot.api.send_message chat_id: message.from.id, text: "发生错误，联系豆腐丝 @tolves 修bug"
    return false
  end
end