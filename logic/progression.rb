module TimingLogic
  attr_accessor :progression

  def progressive_lights
    # a rolling progression of lights
    travel_time = progression[:road].length /
                  progression[:road].speed_limit

    # if the previous green has turned, and we've given time
    # for cars to move along
    #if progression[:previous] && progression[:previous].progression[:road].green?
    if progression[:previous]
      prev_road = progression[:previous].progression[:road]
    else
      prev_road = nil
    end

    # if the progression is switching to green, give it some travel time and
    # then turn green
    if (prev_road &&
        prev_road.green? &&
        $time > (prev_road.transition + travel_time -
                 Intersection::YELLOW + 30)) \
       ||
       (!prev_road &&
        progression[:road].red? &&
        $time > (progression[:road].transition + travel_time -
                 Intersection::YELLOW + 30))


      return {:next_green => nil} if progression[:road] == @current

      prev_road ||= progression[:road]
      info =  "\t\tprogression (prev changed @ #{prev_road.transition.round 1})\n" +
              "\t\t\ttravel time: #{travel_time}"

      {:next_green => progression[:road],
       :reason     => :progression,
       :info       => info}

    # if the progression is switching to red, give it some travel time, plus
    # 30 sec and then turn red
    elsif (prev_road &&
           prev_road.red? &&
           $time > (prev_road.transition + travel_time -
                    Intersection::YELLOW + 45)) \
          ||
          (!prev_road &&
           progression[:road].green? &&
           $time > (progression[:road].transition + travel_time -
                    Intersection::YELLOW + 45))

      prev_road ||= progression[:road]
      info =  "\t\tprogression (prev changed @ #{prev_road.transition.round 1})\n" +
              "\t\t\ttravel time: #{travel_time}"

      {:next_green => (inroads - [progression[:road]]).sort_by {|r| r.delay }[0],
       :reason     => :progression,
       :info       => info}

    else
      {:next_green => nil}
    end
  end
end

# down here, add the code to the maps to setup the progressions
