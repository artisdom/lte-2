QC_IP = '172.20.100.1'

def logit msg
  t = Time.now.strftime "%Y-%m-%d--%H-%M-%S.%L"
  File.open("/var/log/lte_test.log", 'w') do |f|
    f.puts "[#{t}];#{msg}"
  end
end
