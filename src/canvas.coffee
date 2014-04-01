module.exports = ->
  canvas = document.createElement('canvas')
  canvas.width = 400
  canvas.height = 400
  canvasBox = document.getElementById 'canvas-box'
  canvasBox.innerHTML = ""
  canvasBox.appendChild canvas
  ctx = canvas.getContext '2d'
  # human coordinate system
  # setTransform(m11, m12, m21, m22, dx, dy)
  # Matrix:
  # m11 m21 dx
  # m12 m22 dy
  # 0   0   1
  ctx.setTransform 1, 0, 0, -1, canvas.width / 2, canvas.height / 2
  return canvas