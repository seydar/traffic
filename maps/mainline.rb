class Mainline < Map

  def build(length)
    @main  = street length
    @sides = (1..length).map { street 1 }
    @roads = @sides + [@main]

    @cfs = @sides.map.with_index do |side, i|
      @main[i] | side[0]
    end

    # in case I ever want to use the progression algorithm
    #@cfs.each.with_index do |cf, i|
    #  cf.progression = {:previous => @cfs[i + 1],
    #                    :road     => @main[i]}
    #end

    @collectors = @roads.map do |r|
      r[0].succ = Collector.new r[0]
    end

    @generators = @sides.map do |side|
      # 360 cars/hr
      Generator.new(side[-1]) { car_every(10 / opts[:dt]) }
    end

    # 1800 cars/hr
    @generators << Generator.new(@main[-1]) { car_every(2 / opts[:dt]) }
  end

  def display
    pairs = @main.zip(@sides.map {|s| s[0] })
    pairs.each do |m, s|
      print s.inspect.ljust(34)
      print s.sub_info.ljust(18)
      print s.blurs.map {|b| b.colorize }.join(" ").ljust_visible(39)

      print m.inspect.ljust(34)
      print m.sub_info.ljust(18)
      puts m.blurs.map {|b| b.colorize }.join " "
    end
  end
end

