class SquareMatrix < Map
  def build(blocks)
    @two_way = opts[:two_way]

    @e_w = []
    @n_s = []
    @w_e = []
    @s_n = []

    blocks.times do
      @n_s << street(blocks)
      @e_w << street(blocks)

      if @two_way
        @w_e << street(blocks)
        @s_n << street(blocks)
      end
    end

    # Leaving this structure here in case I want to come back
    # and install progression lights
    streets = Hash.new {|h, k| h[k] = {} }
    blocks.times do |i|
      blocks.times do |j|
        if @two_way
          streets[i][j] = Group.new(@e_w[i][j], @w_e[i][blocks - j - 1]) |
                          Group.new(@n_s[j][i], @s_n[j][blocks - i - 1])
        else
          streets[i][j] = @e_w[i][j] | @n_s[j][i]
        end
      end
    end

    @cfs = streets.values.map {|h| h.values }.flatten

    @roads = @e_w + @n_s + @w_e + @s_n

    @collectors = @roads.map do |r|
      r[0].succ = Collector.new(r[0])
    end

    @generators = @roads.map do |r|
      # 600 cars/hr
      Generator.new(r[-1]) { car_every(6 / opts[:dt]) }
    end
  end

  #def bones
  #  @cfs.each do |cf|
  #    cf.inroads.map do |group|
  #      group.roads.each do |block|
  #        print location_of_road(block).values.inspect
  #        print ", "
  #      end
  #      puts
  #    end
  #  end
  #end

  #def location_of_road(block)
  #  streets = {"N-S" => @n_s, "S-N" => @s_n, "E-W" => @e_w, "W-E" => @w_e}
  #  letter  = streets.keys[streets.values.index {|direction| direction.any? {|street| street.include? block } }]
  #  {:letter => letter, :number => streets[letter].index {|street| street.include? block }}
  #end

  def display
    if @s_n.size == 1
      n = @n_s[0][0]
      s = @s_n[0][0]
      e = @e_w[0][0]
      w = @w_e[0][0]

      @groups = @cfs[0].inroads

      print "E-W: [", @groups[0].blurs.map {|b| b.colorize }.join(", "), "]\n"
      print "N-S: [", @groups[1].blurs.map {|b| b.colorize }.join(", "), "]\n"
      puts

      puts n.blurs.map {|b| b.colorize }.join(", ").ljust_visible(80)
      puts "#{n.ehr} #{n.color} R(#{n.object_id.to_s[-4..-2]})".center(80)
      puts "#{e.ehr} #{e.color} R(#{e.object_id.to_s[-4..-2]}) #{e.blurs.map {|b| b.colorize }.join(", ")}".rjust_visible(80)
      puts "#{w.blurs.map {|b| b.colorize }.join(", ")} R(#{w.object_id.to_s[-4..-2]}) #{w.color} #{w.ehr}".ljust_visible(80)
      puts "#{s.ehr} #{s.color} R(#{s.object_id.to_s[-4..-2]})".center(80)
      puts s.blurs.map {|b| b.colorize }.join(", ").rjust_visible(80)

    elsif @two_way
      out = @e_w.map.with_index do |e_w, i|
        @n_s.map.with_index do |n_s, j|
          e_ehr = e_w[j].ehr
          n_ehr = n_s[i].ehr
          w_ehr = @w_e[i][j].ehr
          s_ehr = @s_n[j][i].ehr
          "#{e_ehr == Float::INFINITY ? "   @" : e_ehr.to_s.rjust(4)}|"+
          "#{w_ehr == Float::INFINITY ? "   @" : w_ehr.to_s.rjust(4)}^" +
          "#{n_ehr == Float::INFINITY ? "   @" : n_ehr.to_s.rjust(4)}|"+
          "#{s_ehr == Float::INFINITY ? "   @" : s_ehr.to_s.rjust(4)}"
        end
      end

      out.each {|row| puts "[ #{row.join ", "} ]" }
    else
      out = @e_w.map.with_index do |e_w, i|
        @n_s.map.with_index do |n_s, j|
          e_ehr = e_w[j].ehr
          n_ehr = n_s[i].ehr
          "#{e_ehr == Float::INFINITY ? "   @" : e_ehr.to_s.rjust(5)}|"+
          "#{n_ehr == Float::INFINITY ? "   @" : n_ehr.to_s.rjust(5)}"
        end
      end

      out.each {|row| puts "[ #{row.join ", "} ]" }
    end

    nil
  end
end
