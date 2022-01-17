local radius = 6371e3

local salvoSize = 2
local interval = 5
local v_missile = 500

local missiles = 0
local flip

local event
local trig
local con
local act

local function BuildCircleOfRPs(theside, unit, range)
  local refPoints = {}
  local tableofcirclepoints = World_GetCircleFromPoint({latitude=unit.latitude,longitude=unit.longitude,numpoints=4,radius=range})
  local counter = 1
  for k,v in ipairs(tableofcirclepoints) do
    table.insert(refPoints, ScenEdit_AddReferencePoint({side=theside,latitude=v.latitude,longitude=v.longitude, relativeto=unit.guid, name=unit.name .. "-" .. counter}).name)
    counter = counter + 1
  end
  return refPoints
end

local unit = ScenEdit_GetUnit({name='SSGN 726 Ohio [DDS]', guid='GWKW9V-0HM9I5EHB3JF3'})
local circlePoints = BuildCircleOfRPs('BLUFOR', unit, 1)

function calculateDistance(a, deltaT)
    return (v_missile^2*deltaT^2 + 2*a*v_missile*deltaT) / (2*(a + v_missile*deltaT))
end

if trig == nil then
    local trig = ScenEdit_SetTrigger({mode='add',
    type='UnitEntersArea',
    name='MissileSpawned', 
    targetfilter={TargetType='6'},
    area=circlePoints})
end

if con == nil then
    local con = ScenEdit_SetCondition({mode='add',
    type='ScenHasStarted',
    name='ScenStarted'})
end

if act == nil then  
    local script = 'print("works")'
    act = ScenEdit_SetAction({mode='add',type='Points',name='MyFunction',
    SideID="BLUFOR", PointChange=10})
    print(missiles)
end

if event == nil then
    local event = ScenEdit_SetEvent('event', {mode='add'})
    ScenEdit_SetEventTrigger('event', {mode='add', name='MissileSpawned'})
    ScenEdit_SetEventCondition('event', {mode='add', name='ScenStarted'})
    ScenEdit_SetEventAction('event', {mode='add', name='MyFunction'})
    event.isRepeatable = true
end

local scriptText = 'local salvoSize = 2 \r\n'..
'local interval = 5 \r\n'..
'local v_missile = 500 \r\n'..
'local  missiles = 0 \r\n'..
'local unit = ScenEdit_GetUnit({name="SSGN 726 Ohio [DDS]", guid="GWKW9V-0HM9I5EHB3JF3"}) \r\n'..
'function calculateDistance(a, deltaT) \r\n'..
'    return (v_missile^2*deltaT^2 + 2*a*v_missile*deltaT) / (2*(a + v_missile*deltaT)) \r\n'..
'end \r\n'..
'local msl = ScenEdit_UnitX() \r\n'..
'local missiles = missiles + 1 \r\n'..
'local perp_dist = calculateDistance(Tool_Range("unit.guid", "target.guid"), interval*(salvoSize-missiles)) \r\n'..
'local perp_point = World_GetPointFromBearing({latitude="unit.latitude", longitude="unit.longitude", distance = perp_dist, bearing = Tool_Bearing("unit.guid", "target.guid")}) \r\n'..
'local course = {} \r\n'..
'table.insert(course, perp_point) \r\n'..
'msl.course = course'
  