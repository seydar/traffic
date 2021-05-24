require 'wirble'

class String
  def nothing     ; Wirble::Colorize.colorize_string self, :nothing     ; end
  def black       ; Wirble::Colorize.colorize_string self, :black       ; end
  def red         ; Wirble::Colorize.colorize_string self, :red         ; end
  def green       ; Wirble::Colorize.colorize_string self, :green       ; end
  def brown       ; Wirble::Colorize.colorize_string self, :brown       ; end
  def blue        ; Wirble::Colorize.colorize_string self, :blue        ; end
  def cyan        ; Wirble::Colorize.colorize_string self, :cyan        ; end
  def purple      ; Wirble::Colorize.colorize_string self, :purple      ; end
  def light_gray  ; Wirble::Colorize.colorize_string self, :light_gray  ; end
  def dark_gray   ; Wirble::Colorize.colorize_string self, :dark_gray   ; end
  def light_red   ; Wirble::Colorize.colorize_string self, :light_red   ; end
  def light_green ; Wirble::Colorize.colorize_string self, :light_green ; end
  def yellow      ; Wirble::Colorize.colorize_string self, :yellow      ; end
  def light_blue  ; Wirble::Colorize.colorize_string self, :light_blue  ; end
  def light_cyan  ; Wirble::Colorize.colorize_string self, :light_cyan  ; end
  def light_purple; Wirble::Colorize.colorize_string self, :light_purple; end
  def white       ; Wirble::Colorize.colorize_string self, :white       ; end

  def ljust_visible(num)
    simple = gsub /\e\[\d;\d{1,2}m/, ''
    adjusted = simple.ljust(num)
    self + ' ' * (adjusted.size - simple.size)
  end

  def rjust_visible(num)
    simple = gsub /\e\[\d;\d{1,2}m/, ''
    adjusted = simple.rjust(num)
    ' ' * (adjusted.size - simple.size) + self
  end
end

module Enumerable
  def sum
    self.inject(0){|accum, i| accum + i }
  end

  def mean
    self.sum / self.size.to_f
  end

  def sample_variance
    m   = self.mean
    sum = self.inject(0) {|accum, i| accum + (i - m) ** 2 }
    sum / (self.size - 1).to_f
  end

  def standard_deviation
    Math.sqrt self.sample_variance
  end
  alias_method :std_dev, :standard_deviation
end

