require "colorize"
require "json"
require "option_parser"

require "./mm2utils"

version = "MM2 PSDL room flag switcher, v. 0.1\n\
           Piotr \"Drogosław\" Doroszewski, 2024"

debug = false
changes = Array(Int16).new
option_output = ""

OptionParser.parse do |parser|
  parser.banner = "Usage: mm2bai FILE [OPTIONS] ROOM [...]"
  parser.on("-d", "--debug", "Debug mode") { debug = true }
  parser.on("-h", "--help", "Show this help") { puts parser; exit }
  parser.on("-o", "--output=FILE", "Output to FILE") { |x| option_output = x }
  parser.on("--version", "Show version info") { puts version; exit }

  parser.on("--set-unknown", "Set unknown flag")            { changes.push(+1) }
  parser.on("--set-echo", "Set echo flag")                  { changes.push(+2) }
  parser.on("--set-normal", "Set normal flag")              { changes.push(+4) }
  parser.on("--set-road", "Set road flag")                  { changes.push(+8) }
  parser.on("--set-intersection", "Set intersection flag") { changes.push(+16) }
  parser.on("--set-special", "Set special flag")           { changes.push(+32) }
  parser.on("--set-warp", "Set warp flag")                 { changes.push(+64) }
  parser.on("--set-instance", "Set instance flag")        { changes.push(+128) }

  parser.on("--unset-unknown", "Unset unknown flag")        { changes.push(-1) }
  parser.on("--unset-echo", "Unset echo flag")              { changes.push(-2) }
  parser.on("--unset-normal", "Unset normal flag")          { changes.push(-4) }
  parser.on("--unset-road", "Unset road flag")              { changes.push(-8) }
  parser.on("--unset-intersection", "Unset inters. flag")  { changes.push(-16) }
  parser.on("--unset-special", "Unset special flag")       { changes.push(-32) }
  parser.on("--unset-warp", "Unset warp flag")             { changes.push(-64) }
  parser.on("--unset-instance", "Unset instance flag")    { changes.push(-128) }

  parser.invalid_option do |flag|
    puts "ERROR: #{flag} is not a valid option."
    puts parser
    exit 1
  end
  if ARGV.size < 2
    puts parser
    exit 2
  end
end

option_input = ARGV[0]
option_rooms = Array(UInt32).new
ARGV[1..-1].each { |x| option_rooms.push(x.to_u32) }

if debug
  p! changes
  p! option_rooms
end

i = File.new(option_input)
o = IO::Memory.new

header = i.read_string(4)
if header != "PSD0"
  STDERR.puts "This doesn't look like a valid PSDL file!"
  exit 3
end
o.write_string(header.to_slice)

o.write_bytes(i.read_bytes(UInt32)) # targetSize
nVertices = i.read_bytes(UInt32)
o.write_bytes(nVertices)
nVertices.times { o.write_bytes(i.read_bytes(Vertex)) }
nFloats = i.read_bytes(UInt32)
o.write_bytes(nFloats)
nFloats.times { o.write_bytes(i.read_bytes(Float32)) }
nTextures = i.read_bytes(UInt32)
o.write_bytes(nTextures)
(nTextures-1).times { skip_string i, o }
nRooms = i.read_bytes(UInt32)
o.write_bytes(nRooms)
o.write_bytes(i.read_bytes(UInt32))
(nRooms-1).times { skip_room i, o }

flags = Array(UInt8).new
nRooms.times { flags.push(i.read_bytes(UInt8)) }

p! flags if debug

if changes.size == 0
  option_rooms.each { |x| p! flags[x] }
else
  option_rooms.each do |x|
    changes.each do | y |
      if y < 0
        flags[x] = (flags[x] & (~(-y)))
      else
        flags[x] = (flags[x] | y)
      end
    end
  end
end

p! flags if debug
exit 0 if changes.size == 0
flags.each { |x| o.write_bytes(x) }

o.print(i.gets_to_end())
i.close
o.rewind

if option_output == ""
  option_output = option_input
end
output_file = File.open(option_output, "w")
output_file.write(o.getb_to_end())
output_file.close
o.close

def skip_string(i, o)
  l = i.read_bytes(UInt8)
  o.write_bytes(l)
  l.times { o.write_bytes(i.read_bytes(UInt8)) }
end

def skip_room(i, o)
  nPerimeterPoints = i.read_bytes(UInt32)
  attributeSize = i.read_bytes(UInt32)
  o.write_bytes(nPerimeterPoints)
  o.write_bytes(attributeSize)
  nPerimeterPoints.times { o.write_bytes(i.read_bytes(UInt32)) }
  attributeSize.times { o.write_bytes(i.read_bytes(UInt16)) }
end
