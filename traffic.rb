class Generator
  attr_accessor :function
  attr_accessor :output
  attr_accessor :backlog
  attr_accessor :total

  def initialize(dep, &func)
    @output = dep
    @function = func
    @backlog = []
    @total = 0
  end

  # time-varying function to allow for sinusoids
  def tick(t)
    car = function.call(t) # time-varying function
    @total += 1 if car

    return unless car ||= @backlog.pop

    if @output.has_space?
      @output << car
    else
      @backlog << car
    end
  end
end

# `tick` is never called
# `road_after` is required because this is the successor of a light/road
# this is not defensively coded
# this should... prolly? be a subclass, given that it needs:
#   length
#   traffic # => [...]
#   has_space?
#   push
#   road_after
# TODO refactor to be a subclass
class Collector
  attr_accessor :source
  attr_accessor :total
  attr_accessor :traffic
  attr_accessor :length

  def initialize(src=nil)
    @source = src
    @traffic = []
    @total = 0
    @length = 1000
  end

  def road_after(opts={})
    []
  end

  def push(car)
    @total += 1
  end
  alias_method :<<, :push

  def has_space?
    true
  end

  def +(road)
    road.succ   = self
    self.source = road
  end
end

