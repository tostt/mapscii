###
  termap - Terminal Map Viewer
  by Michael Strassburger <codepoet@cpan.org>

  Simple pixel to barille character mapper

  Implementation inspired by node-drawille (https://github.com/madbence/node-drawille)
  * added written text support
  * added color support
  * general optimizations
    -> more bit shifting/operations, less Math.floors

  Will either be merged into node-drawille or become an own module at some point
###

module.exports = class BrailleBuffer
  characterMap: [[0x1, 0x8],[0x2, 0x10],[0x4, 0x20],[0x40, 0x80]]

  pixelBuffer: null
  charBuffer: null
  colorBuffer: null

  constructor: (@width, @height) ->
    @pixelBuffer = new Buffer @width*@height/8
    @clear()

  clear: ->
    @pixelBuffer.fill 0
    @charBuffer = []
    @colorBuffer = []

  setPixel: (x, y, color) ->
    @_locate x, y, (idx, mask) =>
      @pixelBuffer[idx] |= mask
      @colorBuffer[(x>>1)+(y*@height<<2)] = @termColor color

  unsetPixel: (x, y) ->
    @_locate x, y, (idx, mask) =>
      @pixelBuffer[idx] &= ~mask

  _locate: (x, y, cb) ->
    return unless 0 <= x < @width and 0 <= y < @height
    idx = (x>>1) + (@width>>1)*(y>>2)
    mask = @characterMap[y&3][x&1]
    cb idx, mask

  frame: ->
    output = []
    delimeter = "\n"
    color = null

    for idx in [0...@pixelBuffer.length]
      output.push delimeter unless idx % (@width/2)

      if @charBuffer[idx]
        output.push @charBuffer[idx]
      else if @pixelBuffer[idx] is 0
        output.push ' '
      else
        output.push color = colorCode if color isnt colorCode = @colorBuffer[idx] or "\x1B[39m"
        output.push String.fromCharCode 0x2800+@pixelBuffer[idx]

    output.push "\x1B[39m"+delimeter
    output.join ''

  termColor: (color) ->
    "\x1B[38;5;#{color}m"

  setChar: (char, color, x, y) ->
    return unless 0 <= x < @width/2 and 0 <= y < @height/4
    idx = x+y*@width/2
    @charBuffer[idx] = char
    @colorBuffer[idx] = color

buffer = new BrailleBuffer 100, 16
for i in [0...100]
  buffer.setPixel i, 8+8*Math.cos(i/10*Math.PI/2), i>>2
console.log buffer.frame()