require 'singleton'
class User
  include Singleton
  attr_accessor :info
  def initialize
    @info = Hash.new
    @conn = Db.new
    @client = @conn.connect
  end

  def get_info
    @info
  end

  def authority tele_id
    result = @client.prepare("SELECT * FROM users AS us LEFT JOIN authority_name AS an ON us.authority=an.id WHERE us.telegram_id = ?").execute(tele_id).first
    # authority = @users.authority message.from.id
  end

  def activities tele_id
    activities_prepare = @client.prepare("SELECT * FROM activity_users AS au LEFT JOIN activity_duty as ad ON au.duty=ad.id LEFT JOIN activity AS ay ON au.activity_id=ay.id where telegram_id=?")
    result = activities_prepare.execute tele_id

    # @users.activities(message.from.id).each do |item|
    #   y << item.map { |value | "#{value[0]}=>#{value[1]}"}.join(',')
    #   y << "\n"
    # end
  end


  def achievements tele_id
    tmp_pre = @client.prepare("SELECT * FROM profile WHERE telegram_id=?")
    tmp_result = tmp_pre.execute tele_id
    am_pre = @client.prepare("SELECT * FROM achievement WHERE f_id=? AND frequency<? ORDER BY frequency DESC LIMIT 1")
    result = Array.new
    result << tmp_result.map {|item|am_pre.execute(item['achievement_id'],item['achievement_frequency']).first}

    # @users.achievements(message.from.id).each do |item|
    #   z << item.map { |value |
    #     value['title'] unless value.nil?
    #   }.join("\n")
    # end
  end

  def self.method_missing(method_sym, *arguments, &block)
    # the first argument is a Symbol, so you need to_s it if you want to pattern match
    if method_sym.to_s =~ /^find_by_(.*)$/
      find $1.to_sym => arguments.first
    else
      super
    end
  end
  # fred.instance_variable_set(:@c, 'cat')
end