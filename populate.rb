require 'net/http'
require 'uri'
require "rubygems"
require 'neo4j'


class Road
  include Neo4j::RelationshipMixin
  
  property :cost
end

class Waypoint
  include Neo4j::NodeMixin
  
  property :lat, :lon, :name
  index :name
  has_n(:roads).to(Waypoint).relationship(Road)
  
  #we right now just calculate the straight distance as cost
  def connect(other)
    latitude1 = lat.to_f * Math::PI/180 #in radian
    longitude1 = lon.to_f * Math::PI/180 #in radian
    latitude2 = other.lat.to_f * Math::PI/180 #in radian
    longitude2 = other.lon.to_f * Math::PI/180 #in radian
    cLa1 = Math.cos( latitude1 );
    x_A = RADIUS_EARTH * cLa1 * Math.cos( longitude1 )
    y_A = RADIUS_EARTH * cLa1 * Math.sin( longitude1 )
    z_A = RADIUS_EARTH * Math.sin( latitude1 );

    cLa2 = Math.cos( latitude2 );
    x_B = RADIUS_EARTH * cLa2 * Math.cos( longitude2 )
    y_B = RADIUS_EARTH * cLa2 * Math.sin( longitude2 )
    z_B = RADIUS_EARTH * Math.sin( latitude2 )
    
    #in meters
    distance = Math.sqrt( ( x_A - x_B ) * ( x_A - x_B ) + ( y_A - y_B ) * ( y_A - y_B ) + ( z_A - z_B ) * ( z_A - z_B ) )
    self.roads.new(other).update(:cost => distance)
  end
end

APP_ID = 'JzJ0LQ_V34EWH5agHt7TZxD0Eqz2CoEkX.xAM9y8PeAIjYALdy4C9Psh0pcZ1t6dpPf9zxXXjICw'
RADIUS_EARTH = 6371*1000 #in meters

def createWaypoint(c, st)
  city = URI.escape(c)
  state = URI.escape(st)
  url = "http://local.yahooapis.com/MapsService/V1/geocode?appid=#{APP_ID}"
  res = Net::HTTP.get(URI.parse( url + "&state=#{state}&city=#{city}") )
  puts res
  lat = res.slice(/Latitude\>(.*)\<\/Latitude/,1)
  lon = res.slice(/Longitude\>(.*)\<\/Longitude/,1)
  point = Waypoint.new :name=>city, :lon=>lon, :lat=>lat
  
end

Neo4j::Transaction.run do
  NYC = createWaypoint('New York', 'New York')
  KAN = createWaypoint('Kansas City', 'Kansas')
  SFE = createWaypoint('Santa Fe', 'New Mexico')
  SEA = createWaypoint('Seattle', 'Washington')
  SF = createWaypoint('San Francisco', 'CA')
  NYC.connect(KAN)
  NYC.connect(SEA)
  SEA.connect(SF)
  KAN.connect(SFE)
  SFE.connect(SF)
end