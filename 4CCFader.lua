-- 4CCFader v1.0
--
-- HANJO, Tokyo, Japan.
-- K2: Toggle focus (Patch A / Patch B / Fader).
-- K3: Randomize Patch A & B values.
-- E1: Change page (Main / Settings).
-- E2: Select param (A/B) or adjust fader / Select setting.
-- E3: Adjust value of param or setting.
-- Live MIDI CC interpolation via fader.
--

local midi_out
local fader = 0.0
local patch_a = {64, 64, 64, 64}
local patch_b = {127, 0, 32, 96}
local cc_numbers = {20, 21, 22, 23}
local midi_channel = 1

local current_page = 1 -- 1 = Main, 2 = Settings
local edit_target = "a" -- "a", "b", or "fader"
local selected_param = 1 -- param index for Patch A/B or setting index
local setting_index = 0 -- 0 = MIDI channel, 1–4 = CC params

function init()
  midi_out = midi.connect()
  send_ccs()
  redraw()
end

function enc(n, d)
  if current_page == 1 then
    if n == 1 then
      current_page = 2
      redraw()
    elseif n == 2 then
      if edit_target == "fader" then
        fader = util.clamp(fader + d / 100, 0, 1)
        send_ccs()
      else
        selected_param = util.clamp(selected_param + d, 1, 4)
      end
      redraw()
    elseif n == 3 then
      if edit_target == "a" then
        patch_a[selected_param] = util.clamp(patch_a[selected_param] + d, 0, 127)
        send_ccs()
      elseif edit_target == "b" then
        patch_b[selected_param] = util.clamp(patch_b[selected_param] + d, 0, 127)
        send_ccs()
      end
      redraw()
    end
  elseif current_page == 2 then
    if n == 1 then
      current_page = 1
      redraw()
    elseif n == 2 then
      setting_index = util.clamp(setting_index + d, 0, 4)
      redraw()
    elseif n == 3 then
      if setting_index == 0 then
        midi_channel = util.clamp(midi_channel + d, 1, 16)
      else
        local idx = setting_index
        cc_numbers[idx] = util.clamp(cc_numbers[idx] + d, 0, 127)
      end
      send_ccs()
      redraw()
    end
  end
end

function key(n, z)
  if n == 2 and z == 1 and current_page == 1 then
    if edit_target == "a" then
      edit_target = "b"
    elseif edit_target == "b" then
      edit_target = "fader"
    else
      edit_target = "a"
    end
    redraw()
  elseif n == 3 and z == 1 and current_page == 1 then
    for i = 1, 4 do
      patch_a[i] = math.random(0, 127)
      patch_b[i] = math.random(0, 127)
    end
    send_ccs()
    redraw()
  end
end

function send_ccs()
  for i = 1, 4 do
    local value = math.floor(util.linlin(0, 1, patch_a[i], patch_b[i], fader))
    midi_out:cc(cc_numbers[i], value, midi_channel)
  end
end

function redraw()
  screen.clear()
  screen.level(15)

  if current_page == 1 then
    screen.move(10, 10)
    screen.text("Patch A")

    screen.move(80, 10)
    screen.text("Patch B")

    for i = 1, 4 do
      screen.level(edit_target == "a" and selected_param == i and 15 or 5)
      screen.move(10, 10 + i * 10)
      screen.text(string.format("%2d: %3d", cc_numbers[i], patch_a[i]))

      screen.level(edit_target == "b" and selected_param == i and 15 or 5)
      screen.move(80, 10 + i * 10)
      screen.text(string.format("%2d: %3d", cc_numbers[i], patch_b[i]))
    end

    -- Crossfader line
    screen.level(edit_target == "fader" and 15 or 5)
    screen.move(20, 60)
    screen.line(120, 60)
    screen.stroke()

    -- Crossfader position
    local fader_x = util.linlin(0, 1, 20, 120, fader)
    screen.move(fader_x, 55)
    screen.line(fader_x, 65)
    screen.stroke()

  elseif current_page == 2 then
    screen.move(10, 10)
    screen.text("Settings")

    screen.level(setting_index == 0 and 15 or 5)
    screen.move(10, 25)
    screen.text("MIDI CH: " .. midi_channel)

    for i = 1, 2 do
      local idx1 = i
      local idx2 = i + 2

      screen.move(10, 35 + i * 10)
      screen.level(setting_index == idx1 and 15 or 5)
      screen.text("CC " .. cc_numbers[idx1])

      screen.move(90, 35 + i * 10)
      screen.level(setting_index == idx2 and 15 or 5)
      screen.text("CC " .. cc_numbers[idx2])
    end
  end

  screen.update()
end