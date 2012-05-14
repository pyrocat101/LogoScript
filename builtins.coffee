Canvas = require 'canvas'
fs = require 'fs'

_toRadian (_d) -> _d * Math.PI / 180
_toDegree (_d) -> 180 * _d / Math.PI

getMathFuncs = (cb) ->
  # cb(name, func, argc)
  cb 'abs', Math.abs, 1
  cb 'acos', Math.acos, 1
  cb 'asin', Math.asin, 1
  cb 'atan', Math.atan, 1
  cb 'atan2', Math.atan2, 2
  cb 'ceil', Math.ceil, 1
  cb 'cos', Math.cos, 1
  cb 'exp', Math.exp, 1
  cb 'floor', Math.floor, 1
  cb 'log', Math.log, 1
  cb 'max', Math.max, 2
  cb 'min', Math.min, 2
  cb 'pow', Math.pow, 2
  cb 'random', Math.random, 0
  cb 'round', Math.round, 1
  cb 'sin', Math.sin, 1
  cb 'sqrt', Math.sqrt, 1
  cb 'tan', Math.tan, 1

@getMathFuncs = getMathFuncs

class Turtle
  constructor: ->
    # default canvas size is 400x400
    # TODO change canvas size
    @_canvas = new Canvas 400, 400
    @_ctx = @_canvas.getContext '2d'
    # human coordinate system
    # setTransform(m11, m12, m21, m22, dx, dy)
    # Matrix:
    # m11 m21 dx
    # m12 m22 dy
    # 0   0   1
    @_ctx.setTransform 1, 0, 0, -1, 200, 200
    # set line cap and line join
    @_ctx.lineJoin = @_ctx.lineCap = 'round'
    @_posx = 200
    @_posy = 200
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
    if dy > 0
      @_heading = _toDegree Math.atan dx / dy
    else
      @_heading = 180 - _toDegree Math.atan dx / dy
      @_heading = -(@_heading) if x <= 0

  geth: -> @_heading % 180

  setxy: (x, y) ->
    unless @_isPenUp
      ctx.moveTo @_posx, @_posy
      ctx.beginPath()
      ctx.lineTo x, y
      ctx.stroke()
    @_posx = x
    @_posy = y

  setpc: (c) ->
    @_ctx.strokeStyle = c
    @_ctx.fillStyle = c

  setpw: (w) -> @_ctx.lineWidth = w

  text: (t) ->
    ctx.save()
    # transform
    ctx.transform 1, 0, 0, -1, 0, 0
    ctx.fillText t, @_posx, @_posy
    ctx.restore()

  font: (f) -> @_ctx.font = f

  drawImage: (path) ->
    out = fs.createWriteStream path
    stream = canvas.createPNGStream()
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

@Turtle = Turtle
