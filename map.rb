class Map
  # These four are supplied by #build in subclasses
  attr_accessor :roads
  attr_accessor :cfs
  attr_accessor :generators
  attr_accessor :collectors

  attr_accessor :time
  attr_accessor :transitions
  attr_accessor :opts

  def initialize(length, opts={})
    default = {:blur => 6,
               :algorithm => :midpoint,
               :dt => 0.1,
               :prng => Random.new(1234)}

    @time = 0
    @opts = default.merge opts
    @transitions = []

    build length

    @roads.each {|road| road.each {|r| r.map = self } }
    @cfs.each {|cf| cf.map = self }
  end

  def install(script)
    groups = @cfs.map {|cf| cf.inroads }.flatten
    groups.zip(script).each {|g, t| g.cf.script[g] = t }

    # I just got bit by not having this...
    @opts[:algorithm] = :script
  end

  def display
  end

  def tick(kerrat)
    kerrat.times do
      @time += @opts[:dt]
      @time  = @time.round 1

      @roads.each do |road|
        road.each do |section|
          section.tick @opts[:dt]
        end
      end

      @generators.each {|g| g.tick @time } # time-varying function

      @cfs.map {|cf| cf.tick @opts[:dt], @opts[:algorithm]}
    end
  end

  def fitness
    throughput - backlog
  end

  def throughput
    @collectors.reduce(0) {|s, v| s + v.total }
  end

  def backlog
    @generators.reduce(0) {|s, v| s + v.backlog.size }
  end

  def inspect
    "#<Map @algorithm=#{opts[:algorithm]} @time=#{time} # roads=#{roads.size}>"
  end

  # car exit is at pos 0, car entry is last
  # do not install generators or collectors
  # average DC block is ~528' x 528' (ten blocks per mile)
  # NYC blocks are 284' x 900'
  def street(size, group=nil)
    roads = (1..size).map do
      Road.new :length => 500, :speed_limit => 35, :group => group
    end
  
    roads.each_with_index do |l, i|
      l.succ = i - 1 < 0 ? nil : roads[i - 1]
      l.prev = roads[i + 1] # if it's outside the bounds, it'll be nil (duh)
    end
  end
  
  def car_every(odds)
    opts[:prng].rand(odds.to_i) == 1 ? Turtle.new : nil
  end
  
  def road(opts={})
    Road.new opts
  end
end

