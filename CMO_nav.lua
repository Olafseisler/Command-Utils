local salvoSize = 5
local interval = 5
local v_missile = 500
local wpn_dbid = 377
local mount_dbid = 2533
local event

function BuildCircleOfRPs(theside, attacker, range) --Builds detection area
  local refPoints = {}
  local tableofcirclepoints = World_GetCircleFromPoint({latitude=attacker.latitude,longitude=attacker.longitude,numpoints=4,radius=range})
  local counter = 1
  for k,v in ipairs(tableofcirclepoints) do
    table.insert(refPoints, ScenEdit_AddReferencePoint({side=theside,latitude=v.latitude,longitude=v.longitude, relativeto=attacker.guid, name=attacker.name .. "-" .. counter}).name)
    counter = counter + 1
  end
  return refPoints
end

local side_name = ScenEdit_PlayerSide()
local attacker_id = {name='SSGN 726 Ohio [DDS]', guid='GWKW9V-0HM9I5EHB3JF3'}
local target_contact_id = {name='67N6 Gamma-D', guid='GWKW9V-0HM9I5EHB3JDT'}
local attacker = ScenEdit_GetUnit(attacker_id)
local target = VP_GetUnit(target_contact_id)
local circlePoints = BuildCircleOfRPs(side_name, attacker, 0.25)

local scriptText = "local id_a = {name='SSGN 726 Ohio [DDS]', guid='GWKW9V-0HM9I5EHB3JF3'}\r\n"..
"local id_b = {name='67N6 Gamma-D', guid='GWKW9V-0HM9I5EHB3JDT'}\r\n"..
'local unit_a = ScenEdit_GetUnit(id_a)\r\n'..
'local unit_b = VP_GetUnit({guid=id_b.guid})\r\n'..
'\r\n'..
'local salvo_size = 5\r\n'..
'local interval = 5\r\n'..
'local v_missile = 500\r\n'..
'\r\n'..
'function CalculateDistance(a, deltaT)\r\n'..
'    local dist_m = (v_missile^2*deltaT^2 + 2*a*v_missile*deltaT) / (2*(a + v_missile*deltaT))\r\n'..
'    return dist_m / 1852\r\n'..
'end\r\n'..
'\r\n'..
'local get_value = ScenEdit_GetKeyValue(unit_a.guid)\r\n'..
'local missiles\r\n'..
'if get_value ~= "" then\r\n'..
'    missiles = tonumber(get_value)\r\n'..
'else\r\n'..
'    missiles = 1\r\n'..
'end\r\n'..
'\r\n'..
'local perp_dist = CalculateDistance(Tool_Range(unit_a.guid, unit_b.guid), interval*(salvo_size-missiles))\r\n'..
'local perp_bearing = Tool_Bearing(unit_a.guid, unit_b.guid) + 90 * (-1)^missiles\r\n'..
'local perp_point = World_GetPointFromBearing({latitude=unit_a.latitude, longitude=unit_a.longitude, distance=perp_dist, bearing=perp_bearing})\r\n'..
'\r\n'..
'local msl = ScenEdit_UnitX()\r\n'..
'msl.course = {{lat=perp_point.latitude, lon=perp_point.longitude}, {lat=msl.course[#msl.course].latitude, lon=msl.course[#msl.course].longitude}}\r\n'..
'\r\n'..
'if missiles >= salvo_size then\r\n'..
'    ScenEdit_ClearKeyValue(unit_a.guid)\r\n'..
'    ScenEdit_SetEvent("ToT CM Strike", {mode="remove", IsActive=true, IsRepeatable=true})\r\n'..
'    ScenEdit_SetAction({mode="remove", type="LuaScript", name="SetMslPath"})\r\n'..
'    ScenEdit_SetTrigger({mode="remove", type="UnitEntersArea", name="MslSpawned"})\r\n'..
'    for i=1, 4 do\r\n'..
'         ScenEdit_DeleteReferencePoint({side=unit_a.side, name=unit_a.name.."-"..i})\r\n'..
'    end\r\n'..
'else\r\n'..
'    ScenEdit_SetKeyValue(unit_a.guid, tostring(missiles + 1))\r\n'..
'end\r\n'

local status, exception = pcall(ScenEdit_GetEvent, "ToT CM Strike")
if status then
    ScenEdit_MsgBox(tostring(exception), 1)
else
    event = ScenEdit_SetEvent("ToT CM Strike", {mode="add", IsActive=true, IsRepeatable=true})

    ScenEdit_SetTrigger({mode='add',
            type='UnitEntersArea',
            name='MslSpawned', 
            targetfilter={TargetType='6', TargetSubType='2001', SpecificUnitClass=nil, SpecificUnit=nil, TargetSide=side_name},
            area=circlePoints})
    
    ScenEdit_SetAction({mode="add", name="SetMslPath", type="LuaScript", ScriptText = scriptText})

    ScenEdit_SetEventTrigger('ToT CM Strike', {mode='add', name='MslSpawned'})
    ScenEdit_SetEventAction('ToT CM Strike', {mode='add', name='SetMslPath'})
end

local attack = ScenEdit_AttackContact(attacker.guid, target_contact_id.guid, {mode='1', mount=mount_dbid, weapon=wpn_dbid, qty=5})
if attack then
print("Attack in progress")
else
print("Attack Unsuccessful")
end