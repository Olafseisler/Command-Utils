-- [REQUIRED]
local salvo_size = 5 -- How many missiles to fire
local interval = 5 -- How much time between shots
local v_missile = 500 -- Missile speed in knots
local r_missile = 1600 -- Missile max range
local wpn_dbid = 377 -- Missile database ID
local mount_dbid = 387 -- Mount database ID. Find it from unit Weapons>Add Mount search
local side_name = ScenEdit_PlayerSide() -- Currently viewed from side
local attacker_id = {name='SSGN 726 Ohio [DDS]', guid='RZD6HZ-0HMEPM7A970LA'} -- ID of the firing unit. Replace with your desired unit ID.
local target_contact_id = {name='67N6 Gamma-D', guid='RZD6HZ-0HMEPM7A971IQ'} -- ID of the enemy CONTACT. Get it from Unit Orders>Scenario Editor
-- [REQUIRED]

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

function UnixToDotnet(unix) -- Converts Unix time to DotNet ticks because Command be like that
  return unix * 10000000 + 621355968000000000
end

local attacker = ScenEdit_GetUnit(attacker_id)
local target = VP_GetUnit(target_contact_id) -- Resolved unit
local circlePoints = BuildCircleOfRPs(side_name, attacker, 0.25)

local scriptText = string.format('local id_a = "%s"\r\n'..
'local id_b = "%s"\r\n'..
'local unit_a = ScenEdit_GetUnit({guid=id_a})\r\n'..
'local unit_b = VP_GetUnit({guid=VP_GetContact({guid=id_b}).guid})\r\n'..
'\r\n'..
'local salvo_size = %d\r\n'..
'local interval = %d\r\n'..
'local v_missile = %d\r\n'..
'local r_missile = %d\r\n'..
'\r\n'..
'function CalculateDistance(a, deltaT)\r\n'..
'    local dist_m = (v_missile^2*deltaT^2 + 2*a*v_missile*deltaT) / (2*(a + v_missile*deltaT))\r\n'..
'    return dist_m / 1852\r\n'..
'end\r\n'..
'\r\n'..
'local get_value = ScenEdit_GetKeyValue("Missile")\r\n'..
'local missiles\r\n'..
'if get_value ~= "" then\r\n'..
'    missiles = tonumber(get_value)\r\n'..
'else\r\n'..
'    missiles = 1\r\n'..
'end\r\n'..
'\r\n'..
'local perp_dist = CalculateDistance(Tool_Range(id_a, id_b), interval*(salvo_size-missiles))\r\n'..
'local total_dist = perp_dist + math.sqrt(perp_dist^2 + Tool_Range(id_a, id_b)^2)\r\n'..
'if total_dist > r_missile then\r\n'..
'  perp_dist = r_missile\r\n'..
'  ScenEdit_MsgBox("Target too far for simultaneous impact!", 1)\r\n'..
'end\r\n'..
'local perp_bearing = Tool_Bearing(id_a, id_b) + 90 * (-1)^missiles\r\n'..
'local perp_point = World_GetPointFromBearing({latitude=unit_a.latitude, longitude=unit_a.longitude, distance=perp_dist, bearing=perp_bearing})\r\n'..
'\r\n'..
'local msl = ScenEdit_UnitX()\r\n'..
'msl.course = {{lat=perp_point.latitude, lon=perp_point.longitude}, {lat=msl.course[#msl.course].latitude, lon=msl.course[#msl.course].longitude}}\r\n'..
'\r\n'..
'if missiles >= salvo_size then\r\n'..
'    ScenEdit_ClearKeyValue("Missile")\r\n'..
'    ScenEdit_SetEvent("ToT CM Strike", {mode="remove", IsActive=true, IsRepeatable=true})\r\n'..
'    ScenEdit_SetAction({mode="remove", type="LuaScript", name="SetMslPath"})\r\n'..
'    ScenEdit_SetTrigger({mode="remove", type="UnitEntersArea", name="MslSpawned"})\r\n'..
'    for i=1, 4 do\r\n'..
'         ScenEdit_DeleteReferencePoint({side=unit_a.side, name=unit_a.name.."-"..i})\r\n'..
'    end\r\n'..
'else\r\n'..
'    ScenEdit_SetKeyValue("Missile", tostring(missiles + 1))\r\n'..
'end\r\n', attacker.guid, target_contact_id.guid, salvo_size, interval, v_missile, r_missile)

local status, exception = pcall(ScenEdit_GetEvent, "ToT CM Strike") -- Sets up a firing event if there isn't one ongoing
if status then
    ScenEdit_MsgBox(tostring(exception), 1)
else
    ScenEdit_SetEvent("ToT CM Strike", {mode="add", IsActive=true, IsRepeatable=true})

    ScenEdit_SetTrigger({mode='add',
            type='UnitEntersArea',
            name='MslSpawned',
            targetfilter={TargetType='6', TargetSubType='2001', SpecificUnitClass=nil, SpecificUnit=nil, TargetSide=side_name},
            area=circlePoints, -- Filter for spawned guided weapons
            ETOA=UnixToDotnet(ScenEdit_CurrentTime()), -- Set up event time cause it might break otherwise
            LTOA=UnixToDotnet(ScenEdit_CurrentTime() + 86400)})

    ScenEdit_SetAction({mode="add", name="SetMslPath", type="LuaScript", ScriptText = scriptText})

    ScenEdit_SetEventTrigger('ToT CM Strike', {mode='add', name='MslSpawned'})
    ScenEdit_SetEventAction('ToT CM Strike', {mode='add', name='SetMslPath'})
end
-- Attack target
local attack = ScenEdit_AttackContact(attacker.guid, target_contact_id.guid, {mode='1', mount=mount_dbid, weapon=wpn_dbid, qty=salvo_size})
if attack then
  print("Attack in progress")
else
  print("Attack unsuccessful")
end