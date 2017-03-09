# encoding: utf-8
require 'telegram/bot'
require 'json'
require 'uri'
require 'openssl'
require 'open-uri'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
token = '344686538:AAGWv2ANcHGZhoZDvubC5xMF2l9bOdJnh9k'

require_relative  'relatives'

Telegram::Bot::Client.run(token, logger: Logger.new($stderr)) do |bot|
	bot.logger.info('Bot has been started')
	bot.listen do |message|
		case message.class.to_s
			when 'Telegram::Bot::Types::Message'
				next if message.date < (Time.now - 240).to_i
				case message.text
					when '/start'
						next if bind message,bot
					when '/start@saltres_bot'
						next if bind message,bot
					when '/go'
						next if overview message,bot
					when '/go@saltres_bot'
						next if overview message,bot
					else
						if !message.reply_to_message.nil?
							case message.reply_to_message.text
								when '请认真输入你的游戏id，输错了就打pp'
									next if resiger message,bot
								when '请输入需要修改权限特工的ingress id：'
									next if check_modified_agent message,bot
								when '请输入要创建的活动名称：'
									next if create_activity_name message,bot
								when '成功新建活动，请继续输入活动详情：'
									next if create_activity_detail message,bot
								when '请输入特工游戏id，多人输入以","分割：'
									next if addagent_into_activity message,bot
								when '请输入广播给活动内除组织者外所有成员的信息：'
									next if notice_all_in_activity message,bot
                when '请输入要新增的活动职责：'
                  next if create_new_duty message,bot
                when "请输入要新增数量级与称号\n格式为：数量=>称号\n例如：2=>大魔王\n某些值为boolean的成就，可设置为1=>称号"
                  next if add_frequency_title message,bot
                when "请输入要修改的数量级与称号中的数量级："
                  next if modify_frequency_title message,bot
                when "请输入要修改的数量级与称号\n格式为：数量=>称号\n例如：2=>大魔王"
                  next if modify_frequency_and_title message,bot
                when "请输入新增加的成就描述："
                  next if add_achievement_particular message,bot
                when "请输入你在本项成就中完成的数值\n某些值为boolean的成就，输入1即可"
                  next if add_myachievement_frequency message,bot

								else
									bot.logger.info(message.reply_to_message)
							end
						end
				end
			when 'Telegram::Bot::Types::CallbackQuery'
				next if message.message.date < (Time.now - 240).to_i
				case message.data
					when 'back_overview'
						next if overview message,bot
					when 'overview_review_agent'
						review_waiting message,bot
					when 'overview_get_me'
						get_me message,bot
					when 'overview_modify_agent_auth'
						modify_agent_auth message,bot
					when 'overview_create_activity'
						create_activity message,bot
					when 'overview_agent_duty'
						view_duty message,bot
          when 'overview_achievement'
            view_achievements message,bot


					when /overview_activities_./
						next if view_activities message,bot
					when /view_activity_.*/
						next if view_activity message,bot

					when /review_waiting_./
						get_waiting_detail message,bot
					when /review_agent_./
						judgement_waiting message,bot

					when /modify_auth_./
						amend_agent message,bot
					when /security_level_./
						create_activity_security_level message,bot



					when /activity_addagent_./
						activity_addagent message,bot
					when /activity_modagent_./
						activity_agent_list message,bot,'mod'
					when /activity_delagent_./
						activity_agent_list message,bot,'del'
					when /activity_noticeagent_./
						activity_noticeagent message,bot
					when /agent_activity_mod_.+_.+_.+/
						modagent_activity message,bot
					when /agent_activity_del_.+_.+_.+/
						delagent_activity message,bot
					when /duty_level_.*_.*_.*/
						modagent_activity_duty message,bot
          when 'add_duty'
            add_duty message,bot
          when /view_achievement_./
            view_achievement message,bot
          when 'add_title'
            add_title message,bot
          when 'modify_title'
            modify_title message,bot
          when 'add_achievement'
            add_achievement message,bot
          when 'add_myachievement'
            add_myachievement message,bot
				end
			else

		end
	end
end