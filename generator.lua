local g = golly()
local gp = require "gplus"
local table = require "table"
local math = require "math"
local io = require "io"

-- cells for a "blocker" which kills LWSSes
local blocker = {2,0, 3,0, 1,1, 3,1, 1,2, 0,3, 1,3}

-- initial tiniest tape within world
g.putcells(g.parse([[
56bo$55bo2bo$42b2o10b5o10b2o$42b2o9b2ob3o10b2o$54bob2o$55b2o2$55b2o8b
2o$54bob2o6b3obo$53b2ob3o4bo4b3o$54b5o5b3obo$55bo2bo6b2o$56bo2$48bo30b
2o$48bobo28b2o$48b2o5$9b2o$2b3o4b2o50b2o$60b2o$bo3bo56bo$bo3bo31bo$2bo
bo31bo$2b3o31b3o$72b2o5b2o$71bo2bo3bo2bo$74b2ob2o$73bobobobo$73bobobob
o$2bo7bo60bo9bo$ob2o5b2obo53b2o2bo11bo$o3b2ob2o3bo54b2o$bo3bobo3bo54bo
7b2ob2o$2b3o3b3o14bo46bo2bobo2bo$25bobo44b3o3b3o$25b2o2$72b2o$72b2o3$
55bo$55b2o$54bobo4$22bo$23bo$21b3o$10b3o3b3o$9bo3bobo3bo$8bo3b2ob2o3bo
$8bob2o5b2obo22b2o$10bo7bo25b2o$43bo4$34bo$10b3o19bobo$10bobo20b2o$9bo
3bo15b2o$9bo3bo15b2o2$10b3o4b2o$17b2o$30bo5bo$29b3o3b3o$28b2o2bobo2b2o
$28b2ob2ob2ob2o$31b2ob2o$29bobo3bobo$28bo2bo3bo2bo$31bo3bo52b2o$28bobo
5bobo49b2o$29bo7bo3$30bo$29bobo2$27bo5bo$30bo$27b2o3b2o3$81b3o3b3o$27b
2o3b2o47b3o3b3o$30bo5b2o42bob2o3b2obo$27bo5bo2b2o42bob2o3b2obo$81b2o5b
2o$29bobo50bo5bo$30bo3$83b2ob2o$82bo5bo$80b2ob2ob5o$80b2ob2ob3ob2o$82b
o6b3o$88bobo$88b2o!
]]))

-- note down locations of all components of initial tape
local tapes = {
  {
    initial = {
      {21,51,3,3},
      {32,63,3,3},
    },
    arm1 = {
      {43,57,3,3},
      {54,45,3,3},
      {66,34,3,3},
    },
    between = {
      {60,22,3,3},
    },
    arm2 = {
      {48,14,3,3},
      {36,25,3,3},
      {25,37,3,3},
    },
    reflector_n_p1 = {42,0,29,13},
    reflector_n_p2 = {70,14,13,29},
    duplicator = {0,21,21,50},
    reflector_s = {27,66,12,32},
    lwss_builder = {80,78,12,29},
  }
}

-- utilities for moving, clearing, and copying areas
local function rect_move(rect, dx, dy)
  local cells = g.getcells(rect)
  g.putcells(cells, 0, 0, 1, 0, 0, 1, "not")
  g.putcells(cells, dx, dy, 1, 0, 0, 1, "or")
  rect[1] = rect[1] + dx
  rect[2] = rect[2] + dy
end

local function clear_rect(rect)
  local cells = g.getcells(rect)
  g.putcells(cells, 0, 0, 1, 0, 0, 1, "not")
end

local function rect_copy(rect, dx, dy, axx, ayy)
  axx = axx or 1
  ayy = ayy or 1
  local cells = g.getcells(rect)
  g.putcells(cells, dx, dy, axx, 0, 0, ayy, "or")

  local new_rect = {
    dx + rect[1] * axx,
    dy + rect[2] * ayy,
    rect[3] * axx,
    rect[4] * ayy,
  }
  if (new_rect[3] < 0) then
    new_rect[1] = new_rect[1] + new_rect[3] + 1
    new_rect[3] = -new_rect[3]
  end
  if (new_rect[4] < 0) then
    new_rect[2] = new_rect[2] + new_rect[4] + 1
    new_rect[4] = -new_rect[4]
  end
  return new_rect
end

-- lengthen a given tape, in practice I only use this on the initial tape
local function lengthen_tape(tape_idx, n)
  local dx = tapes[tape_idx].arm1[3][1] - tapes[tape_idx].arm1[1][1]
  local dy = tapes[tape_idx].arm1[3][2] - tapes[tape_idx].arm1[1][2]
  rect_move(tapes[tape_idx].reflector_n_p1, dx * n, dy * n)
  rect_move(tapes[tape_idx].reflector_n_p2, dx * n, dy * n)
  rect_move(tapes[tape_idx].between[1], dx * n, dy * n)

  arm1_len = #(tapes[tape_idx].arm1)
  for i=1,n do
    local new1 = rect_copy(tapes[tape_idx].arm2[1], dx, dy)
    local new2 = rect_copy(tapes[tape_idx].arm2[2], dx, dy)
    table.insert(tapes[tape_idx].arm2, 1, new2)
    table.insert(tapes[tape_idx].arm2, 1, new1)

    local new3 = rect_copy(tapes[tape_idx].arm1[arm1_len+(i-1)*2-1], dx, dy)
    local new4 = rect_copy(tapes[tape_idx].arm1[arm1_len+(i-1)*2], dx, dy)
    table.insert(tapes[tape_idx].arm1, new3)
    table.insert(tapes[tape_idx].arm1, new4)
  end
end

-- get the nth glider of a tape, in order of emission
local function nth_glider(tape_idx, i)
  local n = #(tapes[tape_idx].arm2)
  if (i <= n) then return tapes[tape_idx].arm2[n-i+1] end
  i = i - n

  local n = #(tapes[tape_idx].between)
  if (i <= n) then return tapes[tape_idx].between[n-i+1] end
  i = i - n

  local n = #(tapes[tape_idx].arm1)
  if (i <= n) then return tapes[tape_idx].arm1[n-i+1] end
  i = i - n

  local n = #(tapes[tape_idx].initial)
  if (i <= n) then return tapes[tape_idx].initial[n-i+1] end
  i = i - n

  return nth_glider(tape_idx, i)
end

-- show a glider as a tuple
local function show_glider(glider)
  return tostring(glider[1])..", "..tostring(glider[2])
end

-- copy a tape, with and offset and mirror
local function tape_copy(old_tape, dx, dy, axx, ayy)
  local new_tape = {}
  new_tape.reflector_n_p1 = rect_copy(old_tape.reflector_n_p1, dx, dy, axx, ayy)
  new_tape.reflector_n_p2 = rect_copy(old_tape.reflector_n_p2, dx, dy, axx, ayy)
  new_tape.reflector_s = rect_copy(old_tape.reflector_s, dx, dy, axx, ayy)
  new_tape.duplicator = rect_copy(old_tape.duplicator, dx, dy, axx, ayy)
  new_tape.lwss_builder = rect_copy(old_tape.lwss_builder, dx, dy, axx, ayy)
  new_tape.initial = {}
  for i=1,#(old_tape.initial) do
    new_tape.initial[i] = rect_copy(old_tape.initial[i], dx, dy, axx, ayy)
  end
  new_tape.arm1 = {}
  for i=1,#(old_tape.arm1) do
    new_tape.arm1[i] = rect_copy(old_tape.arm1[i], dx, dy, axx, ayy)
  end
  new_tape.between = {}
  for i=1,#(old_tape.between) do
    new_tape.between[i] = rect_copy(old_tape.between[i], dx, dy, axx, ayy)
  end
  new_tape.arm2 = {}
  for i=1,#(old_tape.arm2) do
    new_tape.arm2[i] = rect_copy(old_tape.arm2[i], dx, dy, axx, ayy)
  end
  return new_tape
end

-- create n tapes, with appropriate mirroring
local function create_tapes(n)
  local old_tape = tapes[#tapes]
  for j=1,n/2 do
    local new_tape = tape_copy(old_tape, 115, 18)
    table.insert(tapes, new_tape)
    old_tape = new_tape
  end
  local new_tape = tape_copy(
    old_tape,
    23,
    5 + old_tape.arm1[1][2] - old_tape.arm2[1][2] + 92 + old_tape.reflector_n_p1[2] + old_tape.lwss_builder[2],
    1, -1)
  table.insert(tapes, new_tape)
  old_tape = new_tape
  for j=n/2+2,n do
    local new_tape = tape_copy(old_tape, -115, 18)
    table.insert(tapes, new_tape)
    old_tape = new_tape
  end

  local last_tape_arm = tapes[n].arm1
  local arm_room = last_tape_arm[#last_tape_arm][1] - last_tape_arm[1][1]
  arm_room = math.max(arm_room - 30, 0)
  behind_tapes = arm_room + math.ceil(n/2) * 115 + 1 - 200

  local DEBUG = false
  if DEBUG then behind_tapes = 0 end

  for j=0,n-1 do
    if (j & 1 == 1) == (j >= n) then
      g.putcells(blocker, behind_tapes, 102 + j * 18)
    else
      g.putcells(blocker, behind_tapes, 102 + j * 18 - 4, 1, 0, 0, -1)
    end
  end
end

-- given a 2D array, initialize the sufficient number of tapes of sufficient
-- length, and remove the right gliders to spell out the message
local function initialize(data)
  local rows = #data
  local columns = #(data[1])
  local lengthening = math.max(0, math.ceil((columns - 9) / 4))
  local actual_columns = lengthening * 4 + 9

  local function timing_offset(row)
    local symmetric = row - math.ceil(rows / 2)
    if symmetric <= 0 then symmetric = symmetric - 1 end
    local offset = math.abs(symmetric) * 5
    if symmetric < 0 then offset = offset + 1 end
    return offset
  end

  lengthen_tape(1, lengthening)
  create_tapes(rows)

  g.show(tostring(rows).." "..tostring(#tapes))
  for col=1,columns do
    for row=1,rows do
      -- Calculate column timing offset for row
      if 0 == data[row][col] then
        clear_rect(nth_glider(row, col + timing_offset(row)))
      end
    end
  end

  for col=columns+1,actual_columns do
    for row=1,rows do
      clear_rect(nth_glider(row, col + timing_offset(row)))
    end
  end
end

initialize({
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,},
  {1,1,0,0,1,1,0,0,0,1,1,0,0,0,0,1,1,1,1,0,0,1,1,0,0,1,1,0,1,1,0,0,0,0,0,0,1,1,0,0,0,1,1,1,1,1,0,0,0,0,0,0,1,0,1,1,1,0,0,0,0,},
  {1,1,0,0,1,1,0,0,1,1,1,1,0,0,0,1,1,1,1,1,0,1,1,0,0,1,1,0,1,1,0,0,0,0,0,1,1,1,1,0,0,1,1,0,0,1,1,0,0,0,1,1,1,0,0,0,1,1,1,0,0,},
  {1,1,0,0,1,1,0,1,1,0,0,1,1,0,1,1,0,0,0,0,0,1,1,0,1,1,0,0,1,1,0,0,0,0,1,1,0,0,1,1,0,1,1,0,0,1,1,0,0,1,0,0,1,0,1,1,1,0,0,1,0,},
  {1,1,1,1,1,1,0,1,1,0,0,1,1,0,1,1,0,0,0,0,0,1,1,1,1,0,0,0,1,1,0,0,0,0,1,1,0,0,1,1,0,1,1,1,1,1,0,0,0,1,0,0,1,0,0,0,1,0,0,1,0,},
  {1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,0,0,0,0,0,1,1,1,1,0,0,0,1,1,0,0,0,0,1,1,1,1,1,1,0,1,1,1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,},
  {1,1,0,0,1,1,0,1,1,1,1,1,1,0,1,1,0,0,0,0,0,1,1,0,1,1,0,0,1,1,0,0,0,0,1,1,1,1,1,1,0,1,1,0,0,1,1,0,0,1,0,0,1,0,1,0,1,0,0,1,0,},
  {1,1,0,0,1,1,0,1,1,0,0,1,1,0,0,1,1,1,1,1,0,1,1,0,0,1,1,0,1,1,1,1,1,0,1,1,0,0,1,1,0,1,1,0,0,1,1,0,0,1,0,0,1,0,1,0,1,0,0,1,0,},
  {1,1,0,0,1,1,0,1,1,0,0,1,1,0,0,1,1,1,1,0,0,1,1,0,0,1,1,0,1,1,1,1,1,0,1,1,0,0,1,1,0,1,1,1,1,1,0,0,0,0,1,1,1,0,0,0,1,1,1,0,0,},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,0,},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,0,},
})

g.fit()
g.save("out.rle", "rle", false)
g.doevent("key q cmd")
