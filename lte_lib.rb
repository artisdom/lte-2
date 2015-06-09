QC_IP = '0.0.0.0'

def logit msg
  t = Time.now.strftime "%Y-%m-%d--%H-%M-%S.%L"
  puts "[#{t}];#{msg}"
end
