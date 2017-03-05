#!/home/public/.rbenv/shims/ruby
#  _*_ coding: utf-8 _*_
require 'date'

require 'open-uri'
require 'nokogiri'
require 'json'
require 'json/add/core'
require 'optparse'

require 'date'
require 'socket'

# options help declare
def set_option( option )
  OptionParser.new do |opt|
    begin
      opt.program_name = File.basename($0)
      opt.version      = '0.0.1'

      opt.banner = "Usage: #{opt.program_name} [options]"

      opt.separator 'Steam Purchase Simulator'
      opt.separator ''
      opt.separator 'Examples:'
      opt.separator "    % #{opt.program_name} -u UserName -l"

      opt.separator ''
      opt.separator 'Specific options:'

      opt.on('-l', '--list',         'Show all selected games list.') {|v| option[:list] = v}
      opt.on('-f [format]', '--format',         """Put list dependeing of format.
                                                 title:        %%t
                                                 appid:        %%a
                                                 p_initial:    %%i
                                                 p_final:      %%f
                                                 discount_per: %%p
                                                 def: appid: %%a\\ntitle: %%t\\ninit: %%i => final: %%f, dicount_per %%p""") {|v| option[:format] = v}
      opt.on('-w SteamID', '--wishlist',   'Show wishlist data depending of specify a Steam ID with format option.') {|v| option[:wishlist] = v}
      opt.on('-s [appid]', '--select', 'Add list of appid\'s game.') {|v| option[:select] = v}
      opt.on('-c', '--clear',        'Select list clear.') {|v| option[:clear] = v}
      opt.on('-d VAL', '--delete',   'Delete game of specify number.') {|v| option[:delete] = v}
      opt.on('-k', '--kill',   'kill of daemon.') {|v| option[:kill] = v}

      opt.separator ''
      opt.separator 'Common options:'

      opt.on_tail('-h', '--help', 'show this help message and exit') do
        puts opt
        exit
      end
      opt.on_tail('-v', '--version', 'show program\'s version number and exit') do
        puts "#{opt.program_name} #{opt.version}"
        exit
      end
      opt.parse!(ARGV)
    rescue => e
      puts "ERROR #{e}. \nSee #{opt}"
      exit
    end
  end
end

def send_cmd params
  sock = TCPSocket.open("127.0.0.1", 9345)

  sock.write((params.to_s)+"\n")
  print(sock.read)

  sock.close
end

def main()
  params = {}
  set_option(params)

  send_cmd params
end

main()

