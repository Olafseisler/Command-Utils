local id_a = {name='SSGN 726 Ohio [DDS]', guid='RZD6HZ-0HMEPM7A970LA'}
local id_b = {name='67N6 Gamma-D', guid='RZD6HZ-0HMEPM7A971IQ'}
local unit_a = ScenEdit_GetUnit(id_a)
local unit_b = VP_GetUnit({guid=id_b.guid})

local salvo_size = 5
local interval = 5
local v_missile = 500

function CalculateDistance(a, deltaT)
    local dist_m = (v_missile^2*deltaT^2 + 2*a*v_missile*deltaT) / (2*(a + v_missile*deltaT))
    return dist_m / 1852
end

local get_value = ScenEdit_GetKeyValue(unit_a.guid)
local missiles
if get_value ~= "" then
    missiles = tonumber(get_value)
else
    missiles = 1
end

local perp_dist = CalculateDistance(Tool_Range(unit_a.guid, unit_b.guid), interval*(salvo_size-missiles))
local perp_bearing = Tool_Bearing(unit_a.guid, unit_b.guid) + 90 * (-1)^missiles
local perp_point = World_GetPointFromBearing({latitude=unit_a.latitude, longitude=unit_a.longitude, distance=perp_dist, bearing=perp_bearing})

local msl = ScenEdit_UnitX()
msl.course = {{lat=perp_point.latitude, lon=perp_point.longitude}, {lat=msl.course[#msl.course].latitude, lon=msl.course[#msl.course].longitude}}

if missiles >= salvo_size then
    ScenEdit_ClearKeyValue(unit_a.guid)
else
    ScenEdit_SetKeyValue(unit_a.guid, tostring(missiles + 1))
end