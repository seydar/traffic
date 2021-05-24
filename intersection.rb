# intersection is a pairing of roads
# no protected turns in this implementation
class Intersection
  include TimingLogic

  attr_accessor :roads
  attr_accessor :current
  attr_accessor :transitioning
  attr_accessor :kaanto
  attr_accessor :map
  attr_accessor :script

  WAIT   = 100 # car-seconds
  YELLOW = 3.5 # seconds

  Transition = Struct.new :prev,
                          :next,
                          :prev_blur,
                          :next_blur,
                          :time,
                          :green,
                          :throughput,
                          :delay,
                          :wasted,
                          :reason

  def initialize(*roads)
    @roads  = roads
    @wasted = 0

    roads.each {|r| r.cf = self }
    # somewhat arbitrarily, make all but one road red
    roads[0..-2].each {|l| l.color = :red }

    @script = {}

    @current = roads[-1]
  end

  def transitioning?
    transitioning
  end

  def inroads
    roads
  end

  def outroads
    roads.map {|r| r.succ }
  end

  def tick(dt, way=:midpoint)
    if @current.ehr > YELLOW && inroads.any? {|r| r.ehr < YELLOW }
      @wasted += dt
    end

    # deal with a yellow light that's in progress
    if transitioning? && map.time - current.transition > YELLOW
      complete_transition
    end

    # put timing logic here
    # when do we have to clear the opposing lane of traffic
    #   o  given wasted seconds at one light and useful seconds
    #      at another, try to maximize number of total useful seconds
    #      total = useful + wasted
    #      but how do i figure out which timing sequence is best?
    #   o  need a predictor of how long a light will be accumulating
    #      wasted seconds or useful seconds
    #   x  form continuous stretches of traffic by "blurring" short
    #      distances (that are based on speed limit/realtime speed and
    #      the timing of the yellow lights)
    #   x  don't give a green if there's nowhere for the cars to go
    #      on the other side
    #   o  since boilerplate reduction is the same for both traffic
    #      currents, then whether traffic flows instantaneously or not
    #      shouldn't matter. so then yellow lights shouldn't matter?
    #      except they do matter for blurring.
    #   o  total seconds ∝ # of cars on the road - # of potential car spots
    #   o  what's the motivation for the light to even switch? if there is
    #      continuous traffic on both roads, why switch the light?
    #      ^^^ this is key
    #   o  if you have a continuous flow of traffic, crosstraffic will take
    #      crossing time + delay
    #   o  if a light is limited to be max 30 seconds of wasted seconds,
    #      then should it only be looking at the next 30 seconds of traffic?
    #   o  longer lights mean more time spent at the speed limit and less time
    #      spent speeding up and slowing down, so preference is given to
    #      longer lights
    #   x  which means light switching is really at the mercy of the random
    #      holes in traffic
    #   o  is there any difference between doing discrete 30 sec chunks and
    #      doing a running 30-sec look? yes
    #   o  can't do a running look. it would change too frequently. need to
    #      do a 30-sec lookahead, decide when in the next 30 sec to change,
    #      and then do another 30-sec lookahead at that point (which may
    #      occur 15 sec in). Q. is this true? A. no. i do a running look now
    #   o  maybe instead of measuring time spent with cars waiting at the
    #      light, i should be measuring the time like that AND the speed
    #      that is lower than the speed limit? but this violates the
    #      assumption that cars go from 0 to speed limit (instantly?)
    #   x  okay, don't worry about the speed below the speed limit because
    #      while the value of "wasted seconds" might no longer be accurate
    #      as an absolute value, it will still be accurate when compared to
    #      the other light's wasted seconds
    #   x  ^^^ further made difficult because sometimes traffic simply doesn't
    #      flow at the rate of the speed limit, but it doesn't mean that that
    #      time should be counted as delay, per se
    #   x  wasted seconds = delay while no cross traffic
    #   x  there is always greater longterm benefit for having fewer light
    #      transitions. therefore, in a worst-case scenario of a solid stream
    #      of cars from one direction, all algorithms will suggest that they
    #      let the constant stream continue.
    #   x  the only way to stop that is to have a maximum wait time for any
    #      car, which will be specific to the nature of the sinusoidal nature
    #      of traffic for each road. i.e., a solid stream of traffic means you
    #      wait 3 minutes. since traffic isn't truly a solid stream of cars,
    #      the best number is somewhere less than that, depending on its
    #      porosity.
    #   o  porosity would be an interesting measurement of traffic
    #   o  how to get entire roads operating with like minds? isn't that
    #      what blurs are supposed to do?
    #   x  if cars start from a standstill, they can start as a blur, and then
    #      they spread out. how to account for that? need to allow cars to go
    #      above speed limit in order to catch up
    #   o  what about when a blur starts far enough back that singletons can
    #      make it across? TODO
    #   o  lights are turning mid-blur (new blur, caused by a red, can take
    #      priority from completing a blur) TODO
    
    case way
    when :midpoint
      result = minimum_waiting
      result = midpoint_scheduling unless result[:next_green]
    when :progression
      result = progressive_lights
    when :script
      result = scripted
    end

    t_ing = transitioning?
    transition result[:next_green], result[:reason]

    if !t_ing && transitioning?
      info "\tdue to:"
      info result[:info]
    end
  end

  def transition(light, reason=nil)
    return unless light and not transitioning?
    return if light == @current

    info "#{map.time}\t#{light.label} (EHR: #{light.ehr}) is transitioning!"
    info "\t\tin opposition to:"
    info "\t\t#{@current.label} (EHR: #{@current.ehr} sec, " +
         "Green: #{(map.time - @current.transition).round 1} sec)"

         
    @transitioning = true
    @kaanto = Transition.new @current,
                             light,
                             @current.blurs.inspect,
                             light.blurs.inspect,
                             map.time,
                             (map.time - @current.transition).round(1),
                             nil,
                             nil,
                             nil,
                             reason

    @current.color      = :yellow
    @next               = light # only used during changing of lights
    @current.transition = map.time # mark time
  end

  def complete_transition
    raise "Not in transition" unless transitioning?

    info "#{map.time}\t#{@next.label} complete (now green)!"
    info "\t\tdelayed #{@next.delay} sec"

    @transitioning      = false
    @kaanto.delay       = @next.delay
    @kaanto.wasted      = @wasted
    @kaanto.throughput  = @current.throughput
    @map.transitions   << @kaanto

    @current.color      = :red

    @current            = @next
    @current.color      = :green
    @current.transition = map.time

    @next               = nil

    # reset this otherwise we'll try to transition to it again
    @current.delay      = 0
    @wasted             = 0
  end
end

