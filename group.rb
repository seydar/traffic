# Group of lights that share the same signal
class Group
  include Enumerable

  attr_accessor :roads
  attr_accessor :cf

  def initialize(*roads)
    @roads = roads
  end

  def each(&b)
    roads.each &b
  end

  # they move together, so you only need one
  def transition
    roads[0].transition
  end

  def transition=(val)
    roads.each {|r| r.transition = val }
  end

  def color
    roads[0].color
  end

  def color=(couleur)
    roads.each {|r| r.color = couleur }
  end

  def has_space?
    roads.any? {|r| r.has_space? }
  end

  def has_headroad?
    roads.any? {|r| r.succ.has_space? }
  end

  def blurs(granularity=cf.map.opts[:blur])
    traffic = roads.map {|r| r.traffic }
    traffic = traffic.flatten.sort_by {|r| r.left_on_road(:limit) }
    return [] if traffic.empty?

    blurz = [Blur.new(self, traffic[0])]
    traffic[1..-1].each do |t|
      if t.left_on_road(:limit) - blurz[-1].finish <= granularity
        blurz[-1] << t
      else
        blurz << Blur.new(self, t)
      end
    end

    blurz
  end

  def in_blur?(granularity=cf.map.opts[:blur])
    lead = blurs[0]
    return false unless lead

    lead.start < granularity
  end

  #def blurs(*args)
  #  blurz = roads.map {|r| r.blurs }.flatten.sort_by {|b| b.start }
  #  blurz = [*blurz[1..-1]].reduce([blurz[0]]) do |s, v|
  #    if s[-1].overlap? v
  #      s[-1] = s[-1] + v
  #      s
  #    else
  #      s + [v]
  #    end
  #  end

  #  blurz.is_a?(Blur) ? [blurz] : blurz
  #end

  def ehr
    roads.map {|r| r.ehr }.min
  end

  def delay
    roads.map {|r| r.delay }.sum
  end

  def delay=(val)
    roads.each {|r| r.delay = val }
  end

  def throughput
    roads.map {|r| r.throughput }.sum
  end

  def |(other)
    Intersection.new(self, other)
  end
end

