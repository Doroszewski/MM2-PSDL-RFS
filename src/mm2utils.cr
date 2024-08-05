struct Vector
  property x, y, z

  def initialize(@x : Float32, @y : Float32, @z : Float32)
  end

  def to_s(io : IO)
    io << "[ #{self.x}, #{self.y}, #{self.z} ]"
  end

  def self.from_io(io : IO, format : IO::ByteFormat)
    return Vector.new(io.read_bytes(Float32),
                      io.read_bytes(Float32),
                      io.read_bytes(Float32))
  end
  def to_io(io : IO, format : IO::ByteFormat)
    io.write_bytes(self.x);
    io.write_bytes(self.y);
    io.write_bytes(self.z);
  end
end

struct Vertex
  property x, y, z

  def initialize(@x : Float32, @y : Float32, @z : Float32)
  end

  def to_s(io : IO)
    io << "[ #{self.x}, #{self.y}, #{self.z} ]"
  end

  def self.from_io(io : IO, format : IO::ByteFormat)
    return Vertex.new(io.read_bytes(Float32),
                      io.read_bytes(Float32),
                      io.read_bytes(Float32))
  end
  def to_io(io : IO, format : IO::ByteFormat)
    io.write_bytes(self.x);
    io.write_bytes(self.y);
    io.write_bytes(self.z);
  end
end

