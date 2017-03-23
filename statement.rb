begin
  @conn = Db.new
  @client = @conn.connect
rescue
  puts 'db connect failed'
  retry
end


@query_agent_exist_statement = @client.prepare("SELECT agent_id,authority FROM users WHERE telegram_id = ?")#{message.from.id}

@query_ingressid_exist_statement = @client.prepare("SELECT * FROM users WHERE agent_id = ?")

@query_agent_admin_statement = @client.prepare("SELECT agent_id FROM users WHERE telegram_id = ? AND authority in (1,2)")

@query_waiting_agent_statement = @client.prepare("SELECT agent_id,telegram_username FROM users WHERE authority = '6' ORDER BY 'created_on' LIMIT ?,7")

@query_agent_auth_statement_by_agent_id = @client.prepare("SELECT * FROM users AS us LEFT JOIN authority_name AS an ON us.authority=an.id  WHERE us.agent_id=?")

@query_agent_auth_statement_by_telegram_id = @client.prepare("SELECT *,an.name AS authname FROM users AS us LEFT JOIN authority_name AS an ON us.authority=an.id WHERE us.telegram_id = ?")

@query_id_by_telegram_id = @client.prepare("SELECT id,agent_id,telegram_id,telegram_username,authority FROM users WHERE telegram_id = ?")

@query_profile_by_telegram_id = @client.prepare("SELECT * FROM profile WHERE telegram_id=?")

@update_agent_updatedate_by_telegram_id = @client.prepare("UPDATE users SET updated_on=\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\" WHERE telegram_id=?")

select_activity_info = "ay.id,ay.name,ay.detail,ay.security,secu.security_name,ay.created_on,ay.updated_on,ay.status,ad.id AS adid,ad.duty_name"
select_activity_info_leftjoin = "LEFT JOIN activity_users AS au ON ay.id=au.activity_id LEFT JOIN activity_duty AS ad ON au.duty=ad.id LEFT JOIN security AS secu ON ay.security=secu.id"
@query_activity_info_created_byme_by_telegram_id = @client.prepare("SELECT #{select_activity_info} FROM activity AS ay #{select_activity_info_leftjoin} WHERE au.duty=1 AND au.telegram_id=? ORDER BY ay.updated_on")

@query_activity_info = @client.prepare("SELECT #{select_activity_info} FROM activity AS ay #{select_activity_info_leftjoin} WHERE ay.id=? ORDER BY ay.updated_on")

@query_activity_joined_users_by_activity_id = @client.prepare("SELECT *,us.agent_id,us.telegram_id,us.telegram_username,us.authority,ad.duty_name FROM activity_users AS au LEFT JOIN users AS us ON au.telegram_id=us.telegram_id LEFT JOIN activity_duty AS ad ON au.duty=ad.id LEFT JOIN  authority_name AS an ON us.authority=an.id WHERE au.activity_id=? AND au.duty>2")

#duty id小于3为组织者以上，这个可以以后改
@query_activity_organizer_users_by_activity_id = @client.prepare("SELECT *,us.agent_id,us.telegram_id,us.telegram_username,us.authority,ad.duty_name FROM activity_users AS au LEFT JOIN users AS us ON au.telegram_id=us.telegram_id LEFT JOIN activity_duty AS ad ON au.duty=ad.id LEFT JOIN  authority_name AS an ON us.authority=an.id WHERE au.activity_id=? AND ad.id<3")

@insert_addagent_activity = @client.prepare("INSERT INTO activity_users (activity_id,telegram_id,duty) VALUES (?,?,?)")

@update_activity = @client.prepare("UPDATE activity SET updated_on=\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\" WHERE id=?")



@query_activity_duty_by_activity_id = @client.prepare("SELECT *,ad.duty_name,ad.id as adid FROM activity_users AS au LEFT JOIN users AS us ON au.telegram_id=us.telegram_id LEFT JOIN activity_duty AS ad ON au.duty=ad.id WHERE au.activity_id=? AND au.telegram_id=?")

@del_activity_agent_by_acid_and_telid_and_duty = @client.prepare("DELETE FROM activity_users WHERE activity_id=? AND telegram_id=? AND duty=?")
@mod_activity_agent_duty_by_acid_and_telid = @client.prepare("UPDATE activity_users SET duty=? WHERE activity_id=? AND telegram_id=?")

@insert_duty = @client.prepare("INSERT INTO activity_duty (duty_name) VALUES (?)")

@insert_achievement_title = @client.prepare("INSERT INTO achievement (f_id,frequency,title) VALUES (?,?,?)")

@insert_achievement_particular = @client.prepare("INSERT INTO achievement (f_id,frequency,particular) VALUES (0,0,?)")

@query_title_exist = @client.prepare("SELECT * FROM achievement WHERE f_id=? AND frequency=?")

@update_achievement_title = @client.prepare("UPDATE achievement SET frequency=?,title=? WHERE f_id=? AND frequency=?")

@query_myachievement_exist = @client.prepare("SELECT * FROM profile WHERE telegram_id=? AND achievement_id=?")

@query_users_in_activity = @client.prepare("SELECT * FROM activity_users where activity_id=? AND telegram_id=?")