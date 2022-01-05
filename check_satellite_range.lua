-- Turns off radars if satellites are too close
local id_1 =  {name='3MN-1 Bison B [Bomber]', guid='RZD6HZ-0HME229RMEC53'}
local unit_a = ScenEdit_GetUnit(id_1) -- Whatever unit or group you want to manage
local enemy_side = "OPFOR"
local min_range = 1500 -- default value

local s = VP_GetSide({name=enemy_side})
local units = s.units
local any_in_range = false;

for i, unit in ipairs(s:unitsBy('Satellite', 1001, 2005)) do -- loop through all ELINT satellites 
    local sat = VP_GetUnit(unit)
    print(sat.name)
    local range = Tool_Range({latitude=unit_a.latitude, longitude=unit_a.longitude}, {latitude=sat.latitude, longitude=sat.longitude});
    if range < min_range then
        any_in_range = true; -- turn off radars flag if satellite is nearby
        break
    end
end

if any_in_range then
    ScenEdit_SetEMCON('Unit',id_1.name,'Radar=Passive')
else
    ScenEdit_SetEMCON('Unit',id_1.name,'Radar=Active')
end