local patch = {}
patch.__index = patch

local l = require("lume")
local efx = require('efx')
local sampler = require('sampler')
local fretboard = require('fretboard')

local colorScheme = {
  wood    = {l.rgba(0x8a533bff)},
  neck    = {l.rgba(0x4c2f22ff)},
  fret    = {l.rgba(0x8ca697ff)},
  string  = {l.rgba(0x8ca697ff)},
  dot     = {l.rgba(0xeee8b6ff)},
  light   = {l.rgba(0xe4ebd8ff)},
  nut     = {l.rgba(0xeee8b6ff)},
}

function patch.load()
  local self = setmetatable({}, patch)
  self.layout = fretboard.new{ tuning_preset='EBGDAE', skipDrawingEdgeFrets=true }
  self.clean = sampler.new({
    {path='patches/guitar/clean-e1st-str-pluck.ogg',  note =  4},
    {path='patches/guitar/clean-g-str-pluck.ogg',     note = -5},
    {path='patches/guitar/clean-d-str-pluck.ogg',     note = -10},
    {path='patches/guitar/clean-a-str-pluck.ogg',     note = -15},
    {path='patches/guitar/clean-e-str-pluck.ogg',     note = -20},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 1.8 },
    })
  self.dirty = sampler.new({
    {path='patches/guitar/pic1_F#1.ogg', note = -30 + 12 },
    {path='patches/guitar/pic2_B2.ogg',  note = -25 + 12 },
    {path='patches/guitar/pic4_C3.ogg',  note = -12 + 12 },
    {path='patches/guitar/pic6_C4.ogg',  note =   0 + 12 },
    {path='patches/guitar/pic3_F#2.ogg', note =   6 + 12 },
    {path='patches/guitar/pic8_C5.ogg',  note =  12 + 12 },
    {path='patches/guitar/pic5_F#3.ogg', note =  18 + 12 },
    {path='patches/guitar/pic7_F#4.ogg', note =  30 + 12 },
    envelope = { attack = 0, decay = 0, sustain = 0.5, release = 1.8 },
    })
  self.power = sampler.new({
    {path='patches/guitar/cho1_F#1.ogg', note = -30 + 12},
    {path='patches/guitar/cho2_C2.ogg',  note = -24 + 12},
    {path='patches/guitar/cho3_F#2.ogg', note = -18 + 12},
    {path='patches/guitar/cho4_C3.ogg',  note = -12 + 12},
    {path='patches/guitar/cho5_F#3.ogg', note =  -6 + 12},
    envelope = { attack = 0, decay = 0, sustain = 0.5, release = 0.2 },
    })

  self.sustn = sampler.new({
    {path='patches/guitar/sus1_F#1.ogg', note = -30 + 12},
    {path='patches/guitar/sus2_C2.ogg',  note = -24 + 12},
    {path='patches/guitar/sus3_F#2.ogg', note = -18 + 12},
    {path='patches/guitar/sus4_C3.ogg',  note = -12 + 12},
    {path='patches/guitar/sus5_F#3.ogg', note =  -6 + 12},
    envelope = { attack = 5, decay = 0, sustain = 1, release = 0.2 },
    looped = true,
    })
  self.efx = efx.load()
  self.efx.reverb.decaytime = 2
  self.layout.colorScheme.wood = colorScheme.wood
  self.layout.colorScheme.neck = colorScheme.neck
  self.layout.colorScheme.fret = colorScheme.fret
  self.layout.colorScheme.string = colorScheme.string
  self.layout.colorScheme.dot = colorScheme.dot
  self.layout.colorScheme.light = colorScheme.light
  self.layout.colorScheme.nut = colorScheme.nut
  love.graphics.setBackgroundColor(colorScheme.wood)
  return self
end


function patch:process(s)
  self.layout:interpret(s)
  -- whammy bar
  for _,touch in pairs(s.touches) do
    if touch.note then
      touch.note = l.remap(s.tilt[2], -0.1, -1, touch.note, touch.note - 3, 'clamp')
    end
  end
  -- increase the duration of released notes with vertical tilt
  self.clean.envelope.release = l.remap(s.tilt.lp[2], 0.7, -0.5, 0.2, 5,   'clamp')
  self.dirty.envelope.release = l.remap(s.tilt.lp[2], 0.7, -0.5, 0.2, 2,   'clamp')
  self.power.envelope.release = l.remap(s.tilt.lp[2], 0.7, -0.5, 0.2, 1,   'clamp')
  -- crossfade between clean / dirty / dirty+power
  self.clean.masterVolume = l.remap(s.tilt.lp[1],-0.2, 0.1, 1, 0, 'clamp')
  self.dirty.masterVolume = l.remap(s.tilt.lp[1],-0.1, 0.2, 0, 1, 'clamp')
  self.power.masterVolume = l.remap(s.tilt.lp[1], 0.2, 0.3, 0, 1, 'clamp')
  self.sustn.masterVolume = l.remap(s.tilt.lp[1], 0.2, 0.3, 0, 1, 'clamp')
  self.efx:process()
  self.clean:processTouches(s.dt, s.touches, self.efx)
  self.dirty:processTouches(s.dt, s.touches, self.efx)
  self.power:processTouches(s.dt, s.touches, self.efx)
  self.sustn:processTouches(s.dt, s.touches, self.efx)
  return s
end


function patch:draw(s)
  self.layout:draw(s)
  -- draw nut
  local fretX = -0.4 * 4
  love.graphics.setLineWidth(0.09)
  love.graphics.setColor(colorScheme.fret)
  local offX = 0.02 -- nut shadow
  love.graphics.line(fretX - offX, -self.layout.neckHeight * 1.01, fretX - offX, self.layout.neckHeight * 1.01)
  love.graphics.setColor(colorScheme.nut)
  love.graphics.line(fretX, -self.layout.neckHeight * 1.01, fretX, self.layout.neckHeight * 1.01)
  -- dots
  love.graphics.setColor(colorScheme.dot)
  love.graphics.circle('fill', 0.2, 0, 0.05)
  love.graphics.circle('fill', 1.0, 0, 0.05)
end


function patch.icon(time, s)
  -- neck
  love.graphics.setColor(colorScheme.neck)
  love.graphics.rectangle('fill', -2, -2, 4, 4)
  -- dot
  love.graphics.setColor(colorScheme.dot)
  love.graphics.circle('fill', 0, 0, 0.4)
  -- strings
  love.graphics.setLineWidth(0.08)
  love.graphics.setColor(colorScheme.string)
  love.graphics.line(-1, -0.7, 1, -0.7 + math.sin(50*time) * 0.02)
  love.graphics.line(-1, 0.7 , 1,  0.7)
  love.graphics.setLineWidth(0.04)
  love.graphics.setColor(colorScheme.light)
  love.graphics.line(-1, -0.7, 1, -0.7 + math.sin(50*time) * 0.02)
  love.graphics.line(-1, 0.7 , 1,  0.7)
end


return patch