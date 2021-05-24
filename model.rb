#require 'ruby-graphviz'
require "./road.rb"
require "./group.rb"
require "./traffic.rb"
require "./turtle.rb"
Dir['./logic/*.rb'].each {|f| require f }
require "./intersection.rb"
require "./blur.rb"
require "./map.rb"
Dir["./maps/*.rb"].each {|f| require f }
require "./graph.rb"
require "./core_ext.rb"


$watch = []
def info(*args); puts *args if $watch.include?(self); end
#def info(*args); puts *args if ENV['DEBUG']; end

def model
  inp = 0
  loop do
    print `clear`
    puts "#{inp} iterations later..."

    @map.tick inp

    puts
    puts "*" * 80
  
    @map.display
  
    inp = gets.chomp
    break if inp == "x"
    inp = inp == inp.to_i.to_s ? inp.to_i : 10
  end
end

def timing
  a = Time.now
  ret = yield
  puts "#{Time.now - a} seconds"
  ret
end

@map = Mainline.new 10
model

#@dm = DarwinMap.new 100, :mutation => 0.1, :crossover => 0.7 do
#  Script.random(10..30, 1000) { SquareMatrix.new 5 }
#end
#
##$watch << @dm
##timing { 3.times { puts Time.now; @dm.evolve; p @dm.fitness } }
#gens = 1
#until File.read("quit.txt").chomp == "x"
#  puts "Generation #{gens}"
#  @dm.evolve
#  p [@dm.fitness.max, @dm.fitness.min, @dm.fitness.mean, @dm.fitness.std_dev]
#  gens += 1
#end

