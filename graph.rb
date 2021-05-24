COLORS = [:red, :blue, :purple, :green]

class Intersection
  def color
    ""
  end

  def label(opts={})
    "[ CF #{object_id.to_s[-4..-2]} #{roads.size} road#{roads.size == 1 ? '' : 's'} ]"
  end

  def to_graph
    txt = []
    @roads.each_with_index do |road, ix|
      # make it a grouping
      txt << "("

      # don't double-count the intersecting road
      points = road.road_after[0..-2] + [self] + road.road_before

      (0..points.size - 2).each do |i|
        edge = [points[i + 1].label(:group => road.group),
                points[i    ].label(:group => road.group)]

        txt << edge.join(" -> { label: #{points[i + 1].color}; }")
      end

      txt << ")"
    end

    txt.join "\n"
  end
end

class Group
  def label(opts={})
    "[ #{roads.map {|r| "R(" + r.object_id.to_s[-4..-2] + ")" }.join "|"} " +
    "#{roads.map {|r| r.traffic.size.to_s }.join "|"}]"
  end
end

class Road

  def label(opts={})
    color = opts[:color] ? " { color: #{opts[:color]}; }" : ""
    "[ R(#{object_id.to_s[-4..-2]}) #{group} #{traffic.size} ]#{color}"
  end

  def to_graph(opts={})
    node = opts[:intersection] || label
    opts[:direction] ||= :both
    txt = []

    if prev and [:back, :both].include? opts[:direction]
      p, edges = prev.to_graph :direction => :back
      txt += edges
      txt << [p, node].join(" -> ")
    end

    if succ and [:forward, :both].include? opts[:direction]
      s, edges = succ.to_graph :direction => :forward
      txt += edges
      txt << [node, s].join(" -> ")
    end

    [node, txt]
  end
end

class Intersection
  def self.graph(cfs, roads)
    kadut = {}
    txt = []

    cfs.each do |cf|
      cf.roads.each do |k|
        r = kadut[k.road.last] || k.road
        kadut[k.road.last] = r.insert(r.index(k) + 1, cf)
      end
    end

    kadut.each do |_, points|
      txt << "("
      (0..points.size - 2).each do |i|
        edge = [points[i + 1].label,
                points[i    ].label]

        txt << edge.join(" -> { label: #{points[i + 1].color}; }")
      end
      txt << ")"
    end

    txt.join "\n"
  end
end

