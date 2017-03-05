#!/home/public/.rbenv/shims/ruby
#  _*_ coding: utf-8 _*_
require 'date'

require 'open-uri'
require 'nokogiri'
require 'json'
require 'json/add/core'
require 'optparse'

require 'socket'

module Steam
  class Steam_APIs
    def initialize
      @app = Hash.new
    end

    def select(appid)
      puts("show select list")

      ret = "select " + appid + "\n"
      if !@app.has_key?(appid)
        @app[appid.to_s] = get_game_info(appid)
      else
        ret += "already selecting of " + appid + "\n"
      end
      return ret
    end

    def delete(delNum)
      if @app.delete(delNum){ |name| name } != delNum
        # puts( "deleting select list at " + delNum )
        return "deleting select list at " + delNum + "\n"
      else
        # puts( "not found appid " + delNum )
        return "not found appid: " + delNum + "\n"
      end
    end

    def clear
      @app = Hash.new()
      return "clear select list"
    end

    def format_all_select_list(format)
      puts("show all select list")
      ret = 'You are selecting ' + @app.length.to_s + ' games\n'
      for key in @app.keys
        ret += format_game_info(@app[key], format) + "\n"
      end
      return ret
    end

    def get_game_info(appid)
      puts("get game info from appid: #{appid}")

      ret = Hash.new("title"=>nil,"p_initial"=>nil,"p_final"=>nil,"discount_per"=>nil)

      begin
        url = "http://store.steampowered.com/api/appdetails?appids=#{appid}"
        game_data= JSON.parse(open(url).read)
        sleep(0.1)

        ret["appid"] = appid
        ret["title"] = game_data[appid]['data']['name']
        begin
          ret["p_initial"]    = game_data[appid]['data']['price_overview']['initial']/100
          ret["p_final"]      = game_data[appid]['data']['price_overview']['final']/100
          ret["discount_per"] = game_data[appid]['data']['price_overview']['discount_percent']
        rescue => e
          ret["p_initial"]    = -1
          ret["p_final"]      = -1
          ret["discount_per"] = -1
          puts e
          puts( %{can't get #{@appid} game data} )
        end
      rescue => e
        puts( "ERROR: get wishlist details and initialize" )
        puts e
      end

      return ret
    end

    def format_game_info(data, format)
      puts("format game info")
      fmt = format.dup
      begin
        fmt = fmt.gsub( %r{%%t}, data["title"] )
        fmt = fmt.gsub( %r{%%a}, data["appid"] )
        fmt = fmt.gsub( %r{%%i}, data["p_initial"].to_s )
        fmt = fmt.gsub( %r{%%f}, data["p_final"].to_s )
        fmt = fmt.gsub( %r{%%p}, data["discount_per"].to_s )
        return fmt
      rescue => e
        puts "Fault show_only_game_from_appid"
        puts e
        puts
        return ""
      end
    end

    def get_wishlist(user_name, format)
      wish_games = []
      begin
        url = "https://steamcommunity.com/id/#{user_name}/wishlist?sort=price"
        for item in Nokogiri::HTML(open(url)).xpath('//div[@class="wishlistRow "]/@id') do
          wish_games.push(item.to_s.match(/game_([0-9]+)/)[1])
        end
      rescue => e
        puts("ERROR: get wishlist number")
        puts e
        return
      end
      return wish_games.map { |appid| format_game_info(get_game_info(appid),format) }.join
    end

    def format_total_price
      puts( "format total price" )
      sum = 0
      for key in @app.keys
        if( @app[key]["p_initial"] != -1 )
          sum += @app[key]["p_initial"]
        end
      end

      # puts( sprintf( "Total Price: %dY", sum ) )
      return sprintf( "Total Price: %dY\n", sum )
    end

    def format_total_discount
      puts( "format total discount" )
      sum = 0
      for key in @app.keys
        if( @app[key]["p_initial"] != -1 and @app[key]["p_final"] != -1 )
          sum += @app[key]["p_initial"] - @app[key]["p_final"]
        end
      end

      # puts( sprintf( "Total Discount Price: %dY", sum ) )
      return sprintf( "Total Discount Price: %dY\n", sum )
    end
  end
end

# options help declare
def set_option(options)
  OptionParser.new do |opt|
    begin
      opt.program_name = File.basename($0)
      opt.version      = '0.0.1'

      opt.banner = "Usage: #{opt.program_name} [options]"

      opt.separator 'Steam Purchase Simulator'
      opt.separator ''
      opt.separator 'Examples:'
      opt.separator "    % #{opt.program_name} -s [appid] -l"

      opt.separator ''
      opt.separator 'Specific options:'

      opt.on('-l', '--list',         'Show all wishlist with select number') {|v| options[:list] = v}
      opt.on('-f [format]', '--format',         """Show list dependeing of format
                                                 title:        %%t
                                                 appid:        %%a
                                                 p_initial:    %%i
                                                 p_final:      %%f
                                                 discount_per: %%p
                                                 def: appid: %%a\\ntitle: %%t\\ninit: %%i => final: %%f, dicount_per %%p""") {|v| options[:format] = v}
      opt.on('-w SteamID', '--wishlist',   'Show wishlist data depending of specify a Steam ID with format option.') {|v| option[:wishlist] = v}
      opt.on('-s [appid]', '--select', 'Add list of appid\'s game.') {|v| option[:select] = v}
      opt.on('-c', '--clear',        'Select list clear') {|v| options[:clear] = v}
      opt.on('-d VAL', '--delete',   'Delete game of specify number') {|v| options[:delete] = v}
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


def do_cmd(steam, params)
  set_option(params)
  format = ""
  puts(params)

  results = ""

  if( !params.has_key?(:format) )
    format = %{appid: %%a\ntitle: %%t\ninit: %%i => final: %%f, dicount_per %%p\n}
  else
    format = %{#{params[:format].gsub(%r{\\n}, %{\n})}}
  end
  if( params.has_key?(:wishlist) )
    results += steam.get_wishlist(params[:wishlist], format)
  end
  if( params.has_key?(:list) )
    results += steam.format_all_select_list(format)+"\n"
    results += steam.format_total_price+"\n"
    results += steam.format_total_discount
  end
  if( params.has_key?(:select) )
    results+= steam.select(params[:select])
  end
  if( params.has_key?(:delete) )
    results += steam.delete(params[:delete])
  end
  if( params[:clear] == true )
    results += steam.clear
  end
  if( params[:kill] == true )
    exit(1)
  end
  if( params == {} )
    results += "usage: -h, --help"
  end
  return results
end

def do_cmd_loop steam
  server = TCPServer.open(9345)
  loop do
    Thread.start(server.accept) do |client|
      begin
        puts("connected")
        client.puts(do_cmd(steam,eval(client.gets))+"\n")
        puts
      ensure
        client.close
      end
    end
  end

  server.close
end

def main()
  do_cmd_loop Steam::Steam_APIs.new()
end

main()
