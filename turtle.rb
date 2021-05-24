class Turtle
  ACCELERATION = 11.0
  DECELERATION = 12.0
  LENGTH = 10
  FOLLOWING = 3 # seconds
  WITHIN_REACH = 5 # how many seconds of following distance is a car "in reach"
  REACTION = 1.4 # seconds
  DEVIATION = 1.05
  OVERSPEED = 1.2 # willing to go 1.2x speed limit to catch up

  attr_accessor :pos
  attr_accessor :road
  attr_accessor :speed
  attr_accessor :following

  # => [time, distance]
  def self.speed_test(start, finish)
    if start < finish # speeding up
      accel = ACCELERATION
    else
      accel = 0 - DECELERATION
    end

    # v_f = v_0 + a * s
    time = (finish - start) / accel

    # p_f = p_0 + v_0 * s + 0.5 * a * s ** 2
    # p_0 = 0
    dist = start * time + 0.5 * accel * time ** 2
    [time, dist]
  end

  def initialize
    @pos = 0.0
    @speed = 0.0
  end

  def accelerating?
    following_distance > FOLLOWING * DEVIATION
  end

  def decelerating?
    following_distance < FOLLOWING / DEVIATION
  end

  # TODO reaction time
  # Don't react unless there's some deviation from the following distance
  def tick(dt)
    if following_distance < FOLLOWING / DEVIATION # seconds
      @speed = [0, @speed - DECELERATION * dt].max
    elsif following_distance > FOLLOWING * DEVIATION
      if following && following_distance < WITHIN_REACH
        limit = OVERSPEED * road.speed_limit
      else
        limit = road.speed_limit
      end

      @speed = [limit, @speed + ACCELERATION * dt].min
    end

    @pos  += @speed * dt

    @pos   = @pos.round 1
    @speed = @speed.round 1
  end

  def left_on_road(type=:actual)
    if type == :actual
      #return Float::INFINITY if speed == 0
      s = [speed, 0.1].max
    else
      s = road.speed_limit
    end

    x = (road.length - pos) / s
    (x * 10).ceil / 10.0
  end

  # in seconds
  # this has the potential to divide by zero, which just returns infinity
  # or NaN (if the computation is weird? i guess?)
  def following_distance
    time_yellow = (road.map.time - road.transition).round 1

    if road.red?
      target = road.length

    # I know this is wrong (re: encapsulation), but I don't know how else
    # to do it.
    # Cars need to know if they can make it across an intersection in time:
    # in order to do that, they need to know how much time is left in the
    # yellow, because otherwise every moment is compared to "will I make it
    # across in 5 seconds?", which results in turtles NOT making it across
    # and they're then stuck in purgatory because they can't run a red.
    elsif road.yellow? &&
          left_on_road > (Intersection::YELLOW - time_yellow).round(1)
      target = road.length
    else
      next_car = road.succ.traffic.last
      target = next_car ? next_car.pos : road.succ.length

      target = target + road.length
    end

    target = (following && following.pos) || target

    # subtract LENGTH so that the car doesn't sit out into the road
    ((target - pos - LENGTH) / speed).round 1 # one decimal place
  end

  def inspect
    "#<Turtle x: #{pos} v: #{speed} fd: #{road ? following_distance : "N/A"}>"
  end
end

