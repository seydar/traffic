class Blur
  include Enumerable

  attr_accessor :traffic
  attr_accessor :road

  def initialize(road, *cars)
    @road    = road
    @traffic = cars
  end

  def ==(other)
    road == other.road &&
      traffic == other.traffic
  end

  def each(&b); traffic.each(&b); end
  def <<(turtle); traffic << turtle; end
  def size; traffic.size; end

  def +(other)
    rues = [road]
    rues = road.roads if road.is_a? Group
    rues = rues + other.roads if other.is_a? Group

    b = Blur.new(Group.new(*rues))
    b.traffic = (traffic + other.traffic).sort_by {|t| t.left_on_road }
    b
  end

  def overlap?(other)
    # both out
    [other.finish >= finish && other.start <= start,

    # finish in
    other.finish <= finish && other.finish >= start,

    # start in
    other.start <= finish && other.start >= start].any?
  end

  def start
    return Float::INFINITY unless traffic[0]
    traffic[0].left_on_road(:limit)
  end

  def finish
    return Float::INFINITY unless traffic[-1]
    traffic[-1].left_on_road(:limit)
  end

  def midpoint
    return Float::INFINITY unless traffic[0]
    ((start + finish) / 2.0).round 1
  end

  def delay_for_holding(others)
    others = others.dup
    others.delete self

    total = others.map do |o|
      [0, finish - o.start].max * o.size
    end.sum
  end

  def inspect
    if start != finish
      "[#{start} - #{finish}: #{size}]"
    else
      "[#{start}]"
    end
  end

  def colorize
    return "[]" if traffic.empty?

    s, f = [traffic[0], traffic[-1]].map do |turtle|
      if turtle.speed > turtle.road.speed_limit
        turtle.pos.to_s.red
      elsif turtle.speed == turtle.road.speed_limit
        turtle.pos.to_s.green
      else # < speed_limit
        turtle.pos.to_s.yellow
      end
    end

    if start != finish
      "[#{s} - #{f}: #{size}]"
    else
      "[#{s}]"
    end
  end
end

