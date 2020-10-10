class Sphere
    attr_accessor :radius
    attr_accessor :color
    attr_reader :volume
    attr_reader :area

    def initialize(radius)
        @radius = radius
        set_volume
        set_area
    end

    def radius=(value)
        @radius = value
        set_volume
        set_area
    end

    def to_h
        {
            radius: radius,
            volume: volume,
            area: area,
            color: color
        }
    end

    private
    def set_volume
        # v = 4/3 * pi * r^3
        @volume = (4.0/3.0) * Math::PI * (@radius**3)
    end

    def set_area
        # a = 4 * pi * r^2
        @area = 4.0 * Math::PI * (@radius**2)
    end
end