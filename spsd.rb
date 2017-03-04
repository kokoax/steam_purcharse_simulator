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
      @app        = Hash.new
      @select_app = Hash.new
    end
    def updateWishGames( userName )
      begin
        wishGames = []
        for item in Nokogiri::HTML(open("https://steamcommunity.com/id/#{userName}/wishlist?sort=price")).xpath('//div[@class="wishlistRow "]/@id') do
          wishGames.push( item.to_s.match( /game_([0-9]+)/ )[1] )
        end
      rescue => e
        puts( "ERROR: get wishlist number" )
        puts e
        return
      end
      p wishGames
      for item in wishGames
        puts( "appid: " + item )
        begin
          gameData = JSON.parse( open( "http://store.steampowered.com/api/appdetails?appids=#{item}" ).read )
          sleep(0.1)

          @app[item] = Hash.new("title"=>nil,"p_initial"=>nil,"p_final"=>nil,"discount_per"=>nil)
          @app[item]["title"]        = gameData[item]['data']['name']
          begin
            @app[item]["p_initial"]    = gameData[item]['data']['price_overview']['initial']/100
            @app[item]["p_final"]      = gameData[item]['data']['price_overview']['final']/100
            @app[item]["discount_per"] = gameData[item]['data']['price_overview']['discount_percent']
          rescue => e
            @app[item]["p_initial"]    = -1
            @app[item]["p_final"]      = -1
            @app[item]["discount_per"] = -1
            puts e
            puts( %{can't get #{@item} game data} )
          end
        rescue => e
          puts( "ERROR: get wishlist details and initialize" )
          puts e
        end
      end
      puts( "update complete" )
      return "update complete\n"
    end
    def showOnlyGameFromAppid( appid, format )
      str = format.dup
      begin
        if( %r{%%t} =~ str )
          str.gsub!( %r{%%t}, @app[appid]["title"] )
        end
        if( %r{%%a} =~ str )
          str.gsub!( %r{%%a}, appid )
        end
        if( %r{%%i} =~ str )
          str.gsub!( %r{%%i}, @app[appid]["p_initial"].to_s )
        end
        if( %r{%%f} =~ str )
          str.gsub!( %r{%%f}, @app[appid]["p_final"].to_s )
        end
        if( %r{%%p} =~ str )
          str.gsub!( %r{%%p}, @app[appid]["discount_per"].to_s )
        end
        puts(str)
        return str
      rescue => e
        puts e
        puts
      end
    end
    def showGames format
      puts("show all wishlit")
      ret = 'You wish ' + @app.length.to_s + ' games\n'
      for index in @app.keys
        ret += showOnlyGameFromAppid( index, format ) + "\n"
      end
      return ret
    end
    def select( selectNum )
      puts("show select list")
      ret = "select " + selectNum + "\n"
      if !@select_app.has_key?(selectNum)
        if @app.has_key?(selectNum)
          @select_app[selectNum] = nil
        else
          # puts selectNum + " appid game is nothing"
          ret += selectNum + " appid game is nothing\n"
        end
      else
        # puts "already selecting of " + selectNum + "\n"
        ret += "already selecting of " + selectNum + "\n"
      end
      return ret
    end
    def deleteSelect( delNum )
      if @select_app.delete(delNum){ |name| name } != delNum
        # puts( "deleting select list at " + delNum )
        return "deleting select list at " + delNum + "\n"
      else
        # puts( "not found appid " + delNum )
        return "not found appid " + delNum + "\n"
      end
    end
    def clearSelect
      @select_app = Hash.new()
      # File.open( "selectlist.json", "w" ) do |file| file.write("") end
    end
    def showSelect format
      puts( "showSelect" )
      begin
        ret = "You select " + @select_app.size.to_s + " games\n\n"
        # puts
        for index in @select_app.keys
          ret += showOnlyGameFromAppid(index, format)
        end
      rescue => e
        puts "nothing select items"
        puts e
        puts
        return "nothing select items\n"
      else
        puts ret
        return ret
      end
    end
    def showTotalPrice
      puts( "showTotalPrice" )
      sum = 0
      for index in @select_app.keys
        if( @app[index]["p_initial"] != -1 )
          sum += @app[index]["p_initial"]
        end
      end
      # puts( sprintf( "Total Price: %dY", sum ) )
      return sprintf( "Total Price: %dY\n", sum )
    end
    def showTotalDiscount
      puts( "showTotaldIscount" )
      sum = 0
      for index in @select_app.keys
        if( @app[index]["p_initial"] != -1 and @app[index]["p_final"] != -1 )
          sum += @app[index]["p_initial"] - @app[index]["p_final"]
        end
      end

      # puts( sprintf( "Total Discount Price: %dY", sum ) )
      return sprintf( "Total Discount Price: %dY\n", sum )
    end
  end
end

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

      opt.on('-l', '--list',         'Show all wishlist with select number') {|v| option[:list] = v}
      opt.on('-f [format]', '--format',         """Put list dependeing of format
                                                 title:        %%t
                                                 appid:        %%a
                                                 p_initial:    %%i
                                                 p_final:      %%f
                                                 discount_per: %%p
                                                 def: appid: %%a\\ntitle: %%t\\ninit: %%i => final: %%f, dicount_per %%p\\n""") {|v| option[:format] = v}
      opt.on('-u SteamID', '--update',   'Update depending of specify a Steam ID') {|v| option[:update] = v}
      opt.on('-s [appid]', '--select', 'Add list of select number\'s game. if no arg when showing select games') {|v| option[:select] = v}
      opt.on('-c', '--clear',        'Select list clear') {|v| option[:clear] = v}
      opt.on('-d VAL', '--delete',   'Delete game of specify number') {|v| option[:delete] = v}

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

def do_cmd( steam, params )
  puts params
  set_option(params)
  format = ""
  # puts( params )

  results = ""

  if( params[:format] == nil )
    format = %{appid: %%a\ntitle: %%t\ninit: %%i => final: %%f, dicount_per %%p\n}
  else
    format = %{#{params[:format].gsub(%r{\\n}, %{\n})}}
  end
  if( params[:update] != nil )
    # puts( "UPDATED of: " + params[:update] )
    results += steam.updateWishGames(params[:update])
  end
  if( params[:list] == true )
    results += steam.showGames format
  end
  if( params.has_key?(:select) )
    if( params[:select] == nil )
      results += steam.showSelect format+"\n"
      results += steam.showTotalPrice+"\n"
      results += steam.showTotalDiscount
    else
      results+= steam.select( params[:select] )
    end
  end
  if( params[:delete] != nil )
    results += steam.deleteSelect( params[:delete] )
  end
  if( params[:clear] == true )
    results += steam.clearSelect
  end
  if( params[:kill] == true )
    exit(1)
  end
  if( params == {} )
    # puts( "usage: -h, --help" )
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

