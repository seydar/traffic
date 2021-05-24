# roads are the space between lights
#   x  distance between lights? currently all of unit length
#   x  speed limit?
#   x  does a car go from the previous light immediately do the next light,
#      or is there some time it spends on the road before it counts as being
#      bunched up?
#   x  this is unidirectional. what would two-directional look like?
#      yep yep. two directional would simply mean tying the lights together
#      at the intersection, but a road is only ever going to be one-way
class Road
  attr_accessor :succ
  attr_accessor :prev
  attr_accessor :traffic
  attr_accessor :color
  attr_accessor :transition
  attr_accessor :length
  attr_accessor :speed_limit
  attr_accessor :delay
  attr_accessor :throughput
  attr_accessor :group
  attr_accessor :cf
  attr_accessor :map

  COLORS = {:red    => 'R',
            :yellow => 'Y',
            :green  => 'G'}

  def initialize(opts={})
    @succ = opts[:succ]
    @prev = opts[:prev]
    @color = :green # color is controlled by the intersection
    @transition = 0
    @speed_limit = opts[:speed_limit]
    @group = opts[:group]

    @length = opts[:length]
    @traffic = []
    @delay = 0
    @throughput = 0
  end

  def inspect
    "#<Road(#{object_id.to_s[-4..-2]}) #{COLORS[color]} l: #{length} s: " +
    "#{speed_limit} #:#{traffic.size}>"
  end

  def sub_info
    return "" unless @cf

    if red?
      "[ Delay: #{delay.round 1} ]"
    elsif yellow?
      "[ Yellow: #{(map.time - transition).round 1} ]"
    else # green
      "[ Green: #{(map.time - transition).round 1} ]"
    end
  end

  def red?;    color == :red;    end
  def yellow?; color == :yellow; end
  def green?;  color == :green;  end

  def road_before
    [self] + (prev ? prev.road_before : [])
  end

  def road_after
    (succ ? succ.road_after : []) + [self]
  end

  def road
    road_after[0..-2] + road_before
  end

  def delay
    @delay.round 1
  end

  def has_headroad?
    succ.has_space?
  end

  def has_space?
    return true unless traffic.last
    traffic.last.pos > Turtle::LENGTH or
      traffic.last.speed > (Turtle::LENGTH / Intersection::YELLOW)
  end

  # empty head road
  # empty road in front of lead turtle
  #
  # this is not as accurate because it uses `speed_limit` vice the turtle's
  # speed, but this is to alleviate a bug where a blur's midpoint is Infinity
  # because the caboose turtle has speed = 0 (caboose ehr = Infinity, blur
  # midpoint = Infinity).
  #
  # But the issue is with BLUR calling #left_on_road, so what happens if I
  # change how blur calculates it, but not here? This method isn't even used
  # for the midpoint scheduler
  def empty_head_road
    return Float::INFINITY unless traffic[0]
    traffic[0].left_on_road(:limit)
  end
  alias_method :ehr, :empty_head_road

  def push(car)
    car.pos = 0
    car.following = traffic[-1]
    car.road = self

    traffic << car
  end
  alias_method :<<, :push

  def +(road)
    road.succ = self
    self.prev = road
  end

  def |(road)
    Intersection.new self, road
  end

  def tick(dt)

    # reverse it so that all turtles don't move at the same time
    # ten turtles require ten ticks to move
    # this could be managed more accurately with reaction time
    traffic.reverse.each do |t|
      moved_on = false
      t.tick dt

      # A car is passing through the last part of a road while the light
      # is yellow. It is going to make it. Everything is alright. Life is good.
      # But then, a traffic jam (however small) hits it at just the right time,
      # and now the car slows down to accomodate for that. As a result, it NO
      # LONGER makes it across the intersection in time. As a further result,
      # the light is now red and it is sssssssssscreaming across the
      # intersection, but the condition above did not allow it to pass through!
      #
      # Fuck it. WRT "what if the light is red?", this is exactly that case.
      # WRT "what if it doesn't have space?", i'll assume the rest of my code
      # will catch it.
      # WRT < 2 vs < 1, I have no idea why I chose 2 in the first place.
      if length - t.pos < 1
        moved_on = true
        @throughput += 1

        succ << traffic.shift

        traffic[0] && traffic[0].following = nil
      end

      # calculate delay, per vehicle
      # 7.5 feet/sec ~ 5 mph
      if (red? || yellow?) && t.speed < 7.5
        @delay += dt
      end

      if t.pos > length and not moved_on
        raise "turtle too far #{t.inspect} at #{map.time}" 
      end
    end

    # is the first car stuck waiting at the end of the road?
    # only checking for "stopped" cars, not the time slowing down
    if green?
      @delay = 0 # reset the clock as soon as they're moving again
    end

    if red?
      @throughput = 0
    end
  end

  # returns an array of blurs that mark the sections
  # that describe turtles within +granularity+ of each other
  #
  # +granularity+ is in following seconds, based off of the speed limit
  #
  # singletons are in blurs by themselves
  def blurs(granularity=map.opts[:blur])
    return [] if traffic.empty?

    blurz = [Blur.new(self, traffic[0])]
    traffic[1..-1].each do |t|
      if t.left_on_road(:limit) - blurz[-1].finish <= granularity
        blurz[-1] << t # replace the previous endpoint with this new one
      else
        blurz << Blur.new(self, t)
      end
    end

    blurz
  end

  def in_blur?(granularity=map.opts[:blur])
    lead = blurs[0]
    return false unless lead

    lead.start < granularity
  end
end

