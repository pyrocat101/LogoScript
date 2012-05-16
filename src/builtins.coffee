Canvas = require 'canvas'
fs = require 'fs'

deg2rad = Math.PI / 180
rad2deg = 180 / Math.PI

getMathFuncs = (cb) ->
  # cb(name, func, argc)
  cb 'abs', Math.abs, 1
  cb 'acos', ((x) -> rad2deg * Math.acos(x)), 1
  cb 'asin', ((x) -> rad2deg * Math.asin(x)), 1
  cb 'atan', ((x) -> rad2deg * Math.atan(x)), 1
  cb 'atan2', ((y, x) -> rad2deg * Math.atan2(y, x)), 2
  cb 'ceil', Math.ceil, 1
  cb 'cos', ((x) -> Math.cos(x * deg2rad)), 1
  cb 'exp', Math.exp, 1
  cb 'floor', Math.floor, 1
  cb 'log', Math.log, 1
  cb 'max', Math.max, 2
  cb 'min', Math.min, 2
  cb 'pow', Math.pow, 2
  cb 'random', Math.random, 0
  cb 'round', Math.round, 1
  cb 'sin', ((x) -> Math.sin(x * deg2rad)), 1
  cb 'sqrt', Math.sqrt, 1
  cb 'tan', ((x) -> Math.tan(x * deg2rad)), 1

@getMathFuncs = getMathFuncs

class Turtle
  constructor: (options) ->
    # default canvas size is 400x400
    if options.width? and options.height?
      @_canvas = new Canvas options.width, options.height
    else
      @_canvas = new Canvas 400, 400
    @_ctx = @_canvas.getContext '2d'
    # default output path is 'output.png'
    @_output = options.output ? 'output.png'
    # no anti-alias?
    @_ctx.antilias = 'none' unless options.antilias == false
    
    # fill background with white
    @_ctx.save()
    @_ctx.fillStyle = 'white'
    @_ctx.fillRect 0, 0, @_canvas.width, @_canvas.height
    @_ctx.restore()
    # human coordinate system
    # setTransform(m11, m12, m21, m22, dx, dy)
    # Matrix:
    # m11 m21 dx
    # m12 m22 dy
    # 0   0   1
    @_ctx.setTransform 1, 0, 0, -1, @_canvas.width / 2, @_canvas.height / 2
    # set line cap and line join
    @_ctx.lineJoin = @_ctx.lineCap = 'round'
    @_posx = 0
    @_posy = 0
    @_heading = 0
    @_isPenUp = false

  fd: (step) ->
    x = @_posx + step * Math.sin @_heading / 180 * Math.PI
    y = @_posy + step * Math.cos @_heading / 180 * Math.PI
    @setxy x, y

  bk: (step) ->
    x = @_posx - step * Math.sin @_heading / 180 * Math.PI
    y = @_posy - step * Math.cos @_heading / 180 * Math.PI
    @setxy x, y

  lt: (angle) -> @_heading -= angle

  rt: (angle) -> @_heading += angle

  pu: -> @_isPenUp = true

  pd: -> @_isPenUp = false

  home: ->
    @setxy 0, 0
    @seth 0

  setx: (x) -> @setxy x, @_posy

  sety: (y) -> @setxy @_posx, y

  seth: (angle) -> @_heading = angle

  seth2: (x, y) ->
    dx = x - @_posx
    dy = y - @_posy
    @_heading = 90 + rad2deg * Math.atan dy, dx
    #if dy > 0
      #@_heading = rad2deg * Math.atan dx / dy
    #else
      #@_heading = 180 - rad2deg * Math.atan dx / dy
      #@_heading = -(@_heading) if x <= 0

  geth: -> @_heading % 180

  clear: (c) ->
    w = @_canvas.width
    h = @_canvas.height
    @_ctx.save()
    @_ctx.fillStyle = c
    @_ctx.fillRect -(w / 2), -(h / 2), w, h
    @_ctx.restore()

  setxy: (x, y) ->
    unless @_isPenUp
      @_ctx.beginPath()
      @_ctx.moveTo @_posx, @_posy
      @_ctx.lineTo x, y
      @_ctx.stroke()
    @_posx = x
    @_posy = y

  setpc: (c) ->
    @_ctx.strokeStyle = c
    @_ctx.fillStyle = c

  setpw: (w) -> @_ctx.lineWidth = w

  text: (t) ->
    @_ctx.save()
    # transform
    @_ctx.transform 1, 0, 0, -1, 0, 0
    @_ctx.fillText t, @_posx, @_posy
    @_ctx.restore()

  font: (f) -> @_ctx.font = f

  drawImage: (path) ->
    out = fs.createWriteStream path
    stream = @_canvas.createPNGStream()
    stream.on 'data', (chunk) -> out.write chunk

  getFuncs: (cb) ->
    # cb(name, func, argc)
    cb 'fd', @fd.bind(this), 1
    cb 'bk', @bk.bind(this), 1
    cb 'lt', @lt.bind(this), 1
    cb 'rt', @rt.bind(this), 1
    cb 'pu', @pu.bind(this), 0
    cb 'pd', @pd.bind(this), 0
    cb 'home', @home.bind(this), 0
    cb 'setx', @setx.bind(this), 1
    cb 'sety', @sety.bind(this), 1
    cb 'seth', @seth.bind(this), 1
    cb 'seth2', @seth2.bind(this), 2
    cb 'geth', @geth.bind(this), 0
    cb 'setxy', @setxy.bind(this), 2
    cb 'setpc', @setpc.bind(this), 1
    cb 'setpw', @setpw.bind(this), 1
    cb 'clear', @clear.bind(this), 1

@Turtle = Turtle
