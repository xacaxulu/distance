require 'net/http'
class Distance < ActiveRecord::Base

  def airports=(airport_list)
    @airport_list = airport_list
  end

  def airports
    @airport_list
  end 
  
  scope :origin_or_destination, lambda { |airport|
    where("origin = ? OR destination = ?", airport, airport)
  }

  scope :origin, lambda { |airport|
    { :conditions => { :origin => airport } }
  }

  scope :destination, lambda { |airport|
    { :conditions => { :destination => airport } }
  }

  scope :distance, lambda { |distance|
    { :conditions => { :distance => 0..distance } }
  }

  def self.airport_origin_destination_combinations
    airports = []    
    File.open("airports.txt", "r").each_line { |line| airports << line.chomp }
    combinations = []
    temp = airports
    re = /.*\<b\>(\d+)\<\/b \> miles.*/m
    File.open("airport_combinations.txt", "w") do |f|
      while origin = temp.pop
        airports.each do |destination| 
          sleep(1)
          begin
            unless destination == "N/A"
              distance_html = Net::HTTP.get(URI("http://www.world-airport-codes.com/dist/?a1=#{origin}&a2=#{destination}"))
            miles = distance_html.match(re)[1]
            combinations << "#{origin},#{destination},#{miles}"
            puts "#{origin}, #{destination}, #{miles}\n"
            f.write "#{origin},#{destination},#{miles}\n" 
            end
        rescue Timeout::Error 
            puts "timed out, retrying"
            retry
          end
        end
      end
    end
  end
  
  #bundle exec rake distance:combinator
  def self.combinator
    File.open("airport_combinations.txt", "r").each_line do |line|
      lines = []
      lines << line.chomp
      lines.each do |l|
        @lines = []
        @lines << l.split(",")
          @lines.each do |line|
            if line[2].to_i <= 500
              Distance.find_or_create_by_origin_and_destination_and_distance(line[0], line[1], line[2])
            else
          end
        end
      end
    end
  end

end

