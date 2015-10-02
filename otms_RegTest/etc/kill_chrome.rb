system 'ps -e | grep chrome > chrome.pid'
chrome = File.read('chrome.pid')
pid_and_time = chrome.split.select { |v| v =~ /\d/ }
first_pid = pid_and_time[0].to_i
pid = pid_and_time.select { |v| v.to_i >= first_pid }
pid.each { |p| system "kill -9 #{p}" }
File.delete('chrome.pid')
