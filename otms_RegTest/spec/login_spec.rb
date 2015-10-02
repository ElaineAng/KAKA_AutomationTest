require_relative '../load_path'
require 'lib/login'

describe 'Login' do
  attr_reader :login

  before do
    @login = Otms::Login.new
  end

  after do
    login.close
  end

  it 'can decode object to formatted array' do
    common = login.object_array(login.decode_file('bin/object/_common.yml'))
    expect(common.class).to eq(Array)
    expect(common.each { |v| v.is_a?(Hash) }.size).to eq(common.size)
    expect(common.each { |v| v.include?(:varname) }.size).to eq(common.size)
  end

  it 'can login as sr' do
    login.user_on
    login.user_off
  end

  it 'can login as sp' do
    login.user_on(role: 'sp')
    login.user_off
  end

  it 'can change language' do
    login.user_on
    login.change_lang
    login.user_off
    login.user_on
    login.user_off
  end
end
