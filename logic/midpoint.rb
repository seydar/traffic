module TimingLogic

  def minimum_waiting
    next_greens = inroads.select {|r| r.has_headroad? }
    past_wait   = next_greens.select {|r| r.delay > Intersection::WAIT }
    next_green  = past_wait.sort_by {|r| r.delay }.reverse[0]

    {:reason => :wait,
     :next_green => next_green,
     :info => "\t\tdelay > #{Intersection::WAIT} sec"}
  end

  # TODO
  #   o get lights to shift in advance of the blur finishing
  #   x at ~ 30 seconds, one of the lights isn't shifting and it should
  #   x this doesn't match the algorithm on paper. this doesn't properly
  #     use YELLOW. Does this *actually* shift lights in anticipation
  #     of a blur finishing?
  #   o what if this actually calculated possible delay times and chose
  #     the best outcome?
  #   x from rev 25, at time 1.3 sec, the versions deviate. what changed?
  #     turns out it was just rounding differences when calculating system time
  #   x don't change if in the middle of blur
  #   o reevaluate whether the Intersection::YELLOW minimum is the right move
  def midpoint_scheduling(method=:midpoint)
    next_greens = inroads.select {|r| r.has_headroad? }

    blurs = next_greens.map do |r|
      r.blurs[0]
    end.compact

    blurs = blurs.select {|b| b.start <= Intersection::YELLOW +
                                         Turtle::FOLLOWING }

    # preemptive switching
    # don't look at the first blur if it's almost done, but rather look
    # at the next one behind it
    preemptive = false
    cur_blurs = @current.blurs
    if next_greens.include?(@current) &&
       @current.in_blur? &&
       cur_blurs[0].traffic[-1].left_on_road <= Intersection::YELLOW

      preemptive = true
      blurs.delete cur_blurs[0]
      blurs << cur_blurs[1] if cur_blurs[1]
    end

    soonest_blurs = case method
                    when :midpoint
                      blurs_by_midpoint blurs
                    when :delay
                      blurs_by_delay blurs
                    else
                      []
                    end

    soonest_roads = soonest_blurs.map {|blur| blur.road }
    
    # don't shift if there's a "big" blur
    # judge actual speed, not speed_limit
    big_blur = @current.blurs[0] &&
               @current.blurs[0].traffic[-1].left_on_road > Intersection::YELLOW

    if soonest_roads.include? @current
      next_green = nil
    elsif next_greens.include?(@current) &&
          @current.in_blur? &&
          big_blur

      remaining = @current.blurs[0].traffic[-1].left_on_road
      info "#{@current.label}: finishing up a blur, not ready to " +
           "change yet (#{remaining} sec left)"

      next_green = nil
    else
      next_green = soonest_roads[0]
    end

    # info logging
    info = []
    if next_green
      p = @current.blurs[0]
      s = p ? p.midpoint : @current.ehr
      n = next_green.blurs[0]

      if preemptive
        info << "\t\tpreemptive switching"
        info << "\t\t\t#{p.traffic[-1].left_on_road} remaining here"
        info << "\t\t\t#{n.start} to blur on next road (@ speed limit)"
      end

      if method == :midpoint
        info << ("\t\tmidpoint (#{n.midpoint}|#{n.size}" +
                 " vs #{s}|#{p && p.size or 0})")
        info << ("\t\t\t" + blurs.inspect)
        info << "\t\t\tsoonest: #{soonest_blurs.inspect}"
      elsif method == :delay
        info << "\t\tmin delay: #{blurs.map {|b| b.delay_for_holding blurs }.min}"
        info << "\t\t\tblurs: #{blurs.inspect}"
        info << "\t\t\ttotal: #{
          blurs.map {|b| b.delay_for_holding blurs }.inspect}"
      end
    end

    {:next_green => next_green, :reason => :midpoint, :info => info.join("\n")}
  end

  def blurs_by_delay(blurs)
    return [] if blurs.empty?

    blurs.min_by {|b| b.delay_for_holding blurs }
  end

  def blurs_by_midpoint(blurs)
    min = blurs.map do |blur|
      blur.midpoint / blur.size
    end.min

    soonest_blurs = blurs.select do |blur|
      min == blur.midpoint / blur.size
    end
  end

end
