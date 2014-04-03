module.exports = ->
  canvas = document.getElementById('canvas');
  ctx = canvas.getContext '2d'
  # reset state
  ctx.restore()
  ctx.save()
  # human coordinate system
  # setTransform(m11, m12, m21, m22, dx, dy)
  # Matrix:
  # m11 m21 dx
  # m12 m22 dy
  # 0   0   1
  ctx.setTransform 1, 0, 0, -1, canvas.width / 2, canvas.height / 2
  return canvas