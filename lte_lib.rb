$D = false

QC_IP = '172.20.100.1'
TESTRUN_CONFIG = '/tmp/testrun.json'
TESTRUN_STATUS = '/tmp/testrun.status'
TESTRUN_PID = '/tmp/testrun.pid'

def logit msg
  t = Time.now.strftime "%Y-%m-%d--%H-%M-%S.%L"
  if $D
    puts "[#{t}];#{msg}"
  else
    File.open("/tmp/lte_test.log", 'a') do |f|
      f.puts "[#{t}];#{msg}"
    end
  end
end
