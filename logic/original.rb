module TimingLogic

  def original_blurring
    blur_road  = blurred     # road
    empty_road = empty_roads # road

    if blur_road && empty_road

      # blur always has precedence, so there needs to be at least
      # YELLOW + FOLLOWING seconds so the light can turn back before
      # the blur has to slow down
      if empty_road.ehr + Intersection::YELLOW + Turtle::FOLLOWING < blur_road.ehr
        reason = :empty
        next_green = empty_road
      else
        reason = :blur
        next_green = blur_road
      end
    elsif blur_road
      reason = :blur
      next_green = blur_road
    else
      reason = :empty
      next_green = empty_road
    end

    if reason == :empty
      info = "\t\tempty road"
    else
      info = "\t\tblurring (#{next_green.blurs[0].inspect})"
    end

    {:reason => reason, :next_green => next_green, :info => info}
  end

  # designed for single cars, so provide enough time to go back to the main road
  def empty_roads
    next_greens = inroads

    next_greens = next_greens.select {|r| r.has_headroad? }

    # but really, we can switch as soon as we know that another road
    # has traffic before the current green
    #
    # stays super dumb. this is just to gain control without doing any
    # pseudo-blurring.
    next_greens = next_greens.select do |r|
      # this ternary-if statement is only useful if the current road length
      # is shorter than the other possible roads
      addl = @current.traffic.empty? ? 0 : Intersection::YELLOW + Turtle::FOLLOWING

      # if there's enough EHR
      # OR the current road is empty and you've got traffic coming
      # (still has to have less EHR, just in case a car comes along
      # on the current road)
      r.ehr + addl < @current.ehr
    end

    # TODO this should prolly sort by either delay or
    # who has the most incoming traffic
    next_greens[0]
  end

  # more rapid changing back and forth of lights
  #
  # this naively finds the nearest blur and cedes RoW to that road
  #
  # TODO what is a sufficiently dense blur?
  # 
  # if the granularity is greater than the length of a yellow light, then
  # the last car of a blur is never going to make it across. this is bad.
  # therefore, the yellow light needs to be at LEAST as long as the blur
  # granularity
  def blurred
    time_to_blur = {}
    inroads.each do |r|
      blur = r.blurs.select {|b| b.size > 1 }[0]
      next unless blur

      time_to_blur[r] = blur.start
    end

    if @current.in_blur?
      nil # so that we don't change the light
    else
      min_blur = time_to_blur.values.min
      nearest_blurs = inroads.select {|r| time_to_blur[r] == min_blur }

      if nearest_blurs.include? @current
        nil
      else
        nearest_blurs[0]
      end
    end
  end
end
