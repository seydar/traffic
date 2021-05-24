module TimingLogic
  def script
    @script ||= {}
  end

  def script=(val)
    @script = val
  end

  def scripted
    if map.time - @current.transition >= script[@current]
      next_green = (inroads - [@current])[0]
    else
      next_green = nil
    end

    {:reason => :script,
     :next_green => next_green,
     :info => "\t\tscripted wait of #{script[@current]} sec"}
  end
end

class Script
  attr_accessor :script
  attr_accessor :time
  attr_accessor :map
  attr_accessor :type

  PRNG = Random.new 9876

  def self.random(range, time, &map)
    size = map.call.cfs.size * 2
    new((1..size).map { PRNG.rand(range) }, time, &map)
  end

  def initialize(vals, time, &map)
    @script = vals
    @time   = time
    @map    = map
    @type   = map.call.class.name
  end

  def fitness
    return @result if @result

    m = @map.call
    m.install @script
    m.tick @time
    @result = m.fitness
  end

  def mutate!(rate)
    @script = @script.map do |gene|
      if PRNG.rand > rate
        # adding a value in [-5, 5)
        range = 2
        [gene + (PRNG.rand * range * 2) - range, 10].max
      else
        gene
      end
    end
  end

  def crossover(other)
    locus = PRNG.rand script.size
    child_1 = script[0..locus] + other.script[locus + 1..-1]
    child_2 = other.script[0..locus] + script[locus + 1..-1]
    [self.class.new(child_1, @time, &@map), self.class.new(child_2, @time, &@map)]
  end

  def inspect
    "#<Script #{script.size} genes, #{type} for #{time}>"
  end
end

# https://mattmazur.com/2013/08/18/a-simple-genetic-algorithm-written-in-ruby/
# Not related to the Darwinning gem
class DarwinMap
  attr_accessor :population
  attr_accessor :individual
  attr_accessor :rates
  attr_accessor :results

  PRNG = Random.new 19283

  def initialize(size, rates={}, &individual)
    @individual  = individual
    @rates       = {:crossover => rates[:crossover],
                    :mutation  => rates[:mutation]}
    
    # 1. Start with a randomly generated population
    # (candidate solutions to a problem).
    @size        = size
    @population  = (1..size).map { @individual.call }
    @results     = []
  end

  def fitness
    return @results[-1] if @calculated

    @calculated = true
    @results << population.map {|p| p.fitness }
    @results[-1]
  end

  # Select a pair of parent chromosomes from the current population, the
  # probability of selection being an increasing function of fitness.
  # Selection is done "with replacement," meaning that the same chromosome
  # can be selected more than once to become a parent.
  #
  # Selecting a weighted random element is not as intuitive as I thought.
  # https://blog.bruce-hill.com/a-faster-weighted-random-choice
  #
  # Linear scan because I don't care and these populations are ~100
  def selection
    dist = PRNG.rand * fitness.sum

    population.each do |script|
      dist -= script.fitness
      return script if dist <= 0
    end
  end

  def evolve
    next_gen = []

    # 2. Calculate the fitness f(x) of each chromosome x in the population.
    # The calculation of fitness is free after the maps have run
    info "Calculating fitness..."
    fitness

    # Elitism: the fittest 2 individuals automatically progress to the
    # next generation
    next_gen += population.sort_by {|s| s.fitness }[-2..-1]

    # 3. Repeat the following steps until n offspring have been created:
    until next_gen.size == @size
      # a. Select a pair of parent chromosomes from the current population
      info "Selecting two parents..."
      parent_1, parent_2 = selection, selection

      # b. With probability Pc (the "crossover probability" or "crossover rate"),
      # cross over the pair at a randomly chosen point (chosen with uniform
      # probability) to form two offspring. If no crossover takes place, form two
      # offspring that are exact copies of their respective parents.
      info "Crossing over..."
      offspring = [parent_1, parent_2]
      offspring = parent_1.crossover(parent_2) if PRNG.rand > rates[:crossover]

      # c. Mutate the two offspring at each locus with probability Pm (the
      # mutation probability or mutation rate), and place the resulting
      # chromosomes in the new population. 
      info "Mutating..."
      offspring.each {|o| o.mutate! rates[:mutation] }
      next_gen += offspring

      info "Building the generation: #{next_gen.size}"

      # (n is the size of the next generation)
      # "If n is odd, one new population member can be discarded at random."
      # ^^^ doesn't apply since we're always adding two at a time
    end

    @population = next_gen
    @calculated = false

    # this can in theory be called twice in a row, but it's cheap/memoized
    # so I don't care
    fitness
  end

  def inspect
    "#<DarwinMap #{population.size} pop, #{rates.inspect}>"
  end
end

