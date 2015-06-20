require 'sinatra'
require 'json'
require_relative '../lte_lib.rb'

get '/' do
  erb :index
end

get '/status' do
  begin
    @pid = File.open(TESTRUN_PID).readlines.to_s
    @status = File.open(TESTRUN_STATUS).readlines.to_s
  rescue
    @pid = 'n/a'
    @status = 'n/a'
  end
  erb :status
end

post '/status' do
  c = {}
  c["TestID"] = params['desc']
  c["rpUDP"] = []
  c["qcUDP"] = []
  c["bandwidth"] = params['bandwidth'].to_i

  params['pkgSize'].size.times do |i|
    k = ''
    if params['sender'][i] == 'rp'
      k = 'rpUDP'
    else
      k = 'qcUDP'
    end
    c[k] << {"pkgSize" => params['pkgSize'][i].to_i, "pkgInterval" => params['pkgInt'][i].to_f}
  end

  File.open(TESTRUN_CONFIG, 'w') {|f| f.puts c.to_json}
  @pid = spawn("#{File.dirname(File.expand_path(__FILE__))}/../testrun.rb '#{TESTRUN_CONFIG}' 'rp'")
  File.open(TESTRUN_PID, 'w') {|f| f.puts @pid}
  @status = "Start @ #{Time.now}"
  File.open(TESTRUN_STATUS, 'w') {|f| f.puts @status}

  erb :status
end
