QC_IP = '172.20.100.1'

def logit msg
  t = Time.now.strftime "%Y-%m-%d--%H-%M-%S.%L"
  puts "[#{t}];#{msg}"
end
