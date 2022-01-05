-- Sets up event to automatically turn off radars if ELINT satellite is in range
-- Turn off event in Editor > Event Editor > Events > EMCONController for manual control 
  

function AddEvent()
    local status, exception = pcall(ScenEdit_GetEvent, "EMCONController")
    if status then
        print(exception)
    else
        -- Replace id_1 in scriptString with the GUID of the unit you want to manage
        -- Replace enemy_side with your enemy side name
        -- Change min_range to your liking, default for ELINT sats is 1500 nmi
        -- ScenEdit_SetEMCON works for single units in this case. Change to 'Group' or 'Side' if needed
        -- Adjust unitsBy codes if you want to include more than ELINT sats
        local scriptString = '-- Turns off radars if satellites are too close\r\n'..
        "local id_1 =  {name='3MN-1 Bison B [Bomber]', guid='RZD6HZ-0HME229RMEC53'}\r\n"..
        'local unit_a = ScenEdit_GetUnit(id_1) -- Whatever unit or group you want to manage\r\n'..
        'local enemy_side = "OPFOR"\r\n'..
        'local min_range = 1500 -- default value\r\n'..
        '\r\n'..
        'local s = VP_GetSide({name=enemy_side})\r\n'..
        'local units = s.units\r\n'..
        'local any_in_range = false;\r\n'..
        '\r\n'..
        "for i, unit in ipairs(s:unitsBy('Satellite', 1001, 2005)) do -- loop through all ELINT satellites \r\n"..
        '    local sat = VP_GetUnit(unit)\r\n'..
        '    print(sat.name)\r\n'..
        '    local range = Tool_Range({latitude=unit_a.latitude, longitude=unit_a.longitude}, {latitude=sat.latitude, longitude=sat.longitude});\r\n'..
        '    if range < min_range then\r\n'..
        '        any_in_range = true; -- turn off radars flag if satellite is nearby\r\n'..
        '        break\r\n'..
        '    end\r\n'..
        'end\r\n'..
        '\r\n'..
        'if any_in_range then\r\n'..
        "    ScenEdit_SetEMCON('Unit',id_1.name,'Radar=Passive')\r\n"..
        'else\r\n'..
        "    ScenEdit_SetEMCON('Unit',id_1.name,'Radar=Active')\r\n"..
        'end'
        
        local trigger = ScenEdit_SetTrigger({mode="add", name="EverySec", type="RegularTime", interval='0'})
        local condition = ScenEdit_SetCondition({mode="add", name="Started", type="ScenHasStarted"})
        local action = ScenEdit_SetAction({mode="add", name="ControlEMCON", type="LuaScript", ScriptText = scriptString})

        ScenEdit_SetEvent("EMCONController", {mode="add", IsActive=true, IsRepeatable=true} )
        ScenEdit_SetEventTrigger("EMCONController", {mode='add', name="EverySec"})
        ScenEdit_SetEventCondition("EMCONController", {mode='add', name="Started"})
        ScenEdit_SetEventAction("EMCONController", {mode='add', name="ControlEMCON"})
        print("EMCON control against satellites added.")
    end 
end

AddEvent() -- Driver code
