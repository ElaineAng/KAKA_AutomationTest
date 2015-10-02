require_relative '_required'
require 'bin/_case'
require 'pg'
require 'headless'

# Initialize online tariff for auto-dispatch order
class InitOnlineTariff < Otms::Case
  attr_accessor :user, :password, :mail, :db_set

  def report
    @report_step = 'initialize online tariffs'
  end

  def no_scenario_0_invite_shippers
    print "  -> connecting #{user}..."
    invite_shipper
    code = query_invitation_code
    accept_invitation(user, code)
    delete_invitation_code
    print "done.\n"
    results << 'Pass'
  end

  def scenario_1_add_tariffs
    print "  -> connecting tariff of #{user}..."
    switch_user('sp')
    mc.navigate
    add_new_tariff(user)
    accept_tariff(user)
    print "done.\n"
    results << 'Pass'
  end

  private

  def exit_user
    login.user_off
    login.navigate_url(login.otms_url)
  end

  def tariff_data(partner)
    init = mc.data[:init]
    init[:name] = "#{partner} INIT TARIFF"
    init[:partner] = "#{partner}.*"
    init[:negotiable] = '是'
    init.merge!(type: '销售价')
    init.merge!(tariff_periods)
  end

  def tariff_periods
    { starting_period: mc.next_work_day.strftime('%Y.%m.%d'),
      validity_period: (mc.next_work_day + 100).strftime('%Y.%m.%d') }
  end

  def add_new_tariff(partner)
    mc.navigate_sub_tab('my_tariffs')
    mc.add_new_tariff(tariff_data(partner))
    mc.exit_tariff
    mc.search_by_tariff_name("#{partner} INIT TARIFF")
    mc.send_tariff
    exit_user
  end

  def accept_tariff(user)
    login.user_on(data_set: { 'username' => user, 'password' => password })
    mc.navigate
    mc.navigate_sub_tab('my_tariffs')
    mc.search_by_tariff_name("#{user} INIT TARIFF")
    mc.accept_tariff
    exit_user
  end

  def exec_sql(sql)
    db = PG.connect(db_set)
    db.exec(sql)
  end

  def query_invitation_code
    query = 'select code from invitation ' \
            "where invitee_email = 'chao.li@otms.cn' " \
            'order by invitation_date DESC limit 1'
    exec_sql(query).values[0][0]
  end

  def delete_invitation_code
    delete = "delete from invitation where invitee_email = 'chao.li@otms.cn'"
    exec_sql(delete)
  end

  def invite_shipper
    switch_user('sp')
    mc.navigate
    mc.navigate_sub_tab('my_invitations')
    mc.invite_by_email(mail, '对方是客户（甲方），我是承运商')
    exit_user
  end

  def accept_invitation(user, code)
    login.user_on(data_set: { 'username' => user, 'password' => password })
    mc.navigate
    mc.navigate_sub_tab('my_invitations')
    mc.accept_invitation(code)
  end
end

sr = YAML.load_file('etc/users.yml')[:sr]
users = sr[:username].reverse
loop do
  begin
    @user = users.pop
    break unless @user
    Headless.ly do
      init = InitOnlineTariff.new
      init.user = @user
      init.password = sr[:password]
      init.mail = 'chao.li@otms.cn'
      init.db_set = { host: '10.5.1.71',
                      port: '5432',
                      dbname: 'otmstest',
                      user: 'postgres',
                      password: 'postgres' }
      init.process
    end
  rescue StandardError => e
    puts e
    users.push(@user)
    next
  end
end
