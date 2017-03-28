require 'mysql2'
class Db
	def connect
		mysql_host = 'localhost'
		mysql_user = 'root'
		mysql_passwd = '123456'
		mysql_database = 'salt_res'
		client=Mysql2::Client.new(:host => mysql_host,
		                          :username => mysql_user,
		                          :password => mysql_passwd,
		                          :database => mysql_database,
		                          :encoding => 'utf8',
															:reconnect => true)
	end
end
# client = Mysql2::Client.new(:host => "localhost", :username => "root",:password=>"123456",:database=>"salt_res")
# results = client.query("select * from users");
# results.each do |hash|
# 	bot.logger.info(hash.map { |k,v| "#{k} = #{v}" }.join(", "))
# end