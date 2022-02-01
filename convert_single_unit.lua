-- Converts multi-unit airbases to single unit whilst saving the aircraft, loadouts and magazines

function IsEmpty(t) -- Checks is list is empty
    for _,_ in pairs(t) do
        return false
    end
    return true
end

function FindAircraftAndMags(base) -- Returns all aircraft at a particular base
    local aircraft_at_base = {}
    local all_wpns = {}
    local runways = {}
    local i = 1
    local first_unit = VP_GetUnit({guid=base.unitlist[1]})
    local lat, lon = first_unit.latitude, first_unit.longitude
    for k, v in pairs(base.unitlist) do
        local resolved_unit = VP_GetUnit({guid=v})
        if resolved_unit.type == 'Facility' and resolved_unit.subtype == '2001' then
            runways[i] = resolved_unit
            i = i + 1
        end
        local parked_units = resolved_unit.embarkedUnits
        if not IsEmpty(parked_units["Aircraft"]) then
            for l, unit in ipairs(parked_units["Aircraft"]) do
                local ac = VP_GetUnit({guid=unit})
                aircraft_at_base[ac.guid] = ac
            end
        end
        
        if resolved_unit.magazines[1] ~= nil then -- Gets all magazines of all subunits
            local mag_wpns = resolved_unit.magazines[1].mag_weapons
            if not IsEmpty(mag_wpns) then
                for i, wpn in ipairs(mag_wpns) do
                    if all_wpns[wpn.wpn_dbid] ~= nil then
                        all_wpns[wpn.wpn_dbid] = all_wpns[wpn.wpn_dbid] + wpn.wpn_current
                    else
                        all_wpns[wpn.wpn_dbid] = wpn.wpn_current
                    end
                end
            end
        end
    end
    return aircraft_at_base, all_wpns, runways, lat, lon
end

function GetEquivalentSingleUnitID(runways)
    local length = tonumber(string.match(runways[1].classname, "(%d+)"))
    if #runways == 1 then
        if length <= 450 then
            return 1595
        elseif length >= 451 and length <= 900 then
            return 1595
        elseif length >= 901 and length <= 1400 then
            return 1594
        elseif length >= 1401 and length <= 2000 then
            return 1593
        elseif length >= 2001 and length <= 3200 then
            return 1877
        elseif length >= 3201 and length <= 4000 then
            return 1592
        else
            return 1995
        end

    elseif #runways == 2 then
        if length <= 1400 then
            return 1711
        elseif length >= 1401 and length <= 2000 then
            return 1710
        elseif length >= 2001 and length <= 2600 then
            return 1713
        elseif length >= 2601 and length <= 3200 then 
            return 1714
        elseif length >= 3201 and length <= 4000 then
            return 430
        else
            return 1996
        end
    
    elseif #runways == 3 then
        if length <= 3200 then 
            return 2414
        elseif length >= 3201 and length <= 4000 then
            return 2415
        else
            return 2413
        end
    
    else
        return 2416
    end
end


    

-- Gets necessary data
local side_name = ScenEdit_PlayerSide()
local s = VP_GetSide({name = side_name})
local airbases = {}
for i, unit in ipairs(s:unitsBy("Facility", 2001)) do
    local vp_unit = VP_GetUnit(unit)
    airbases[vp_unit.group.guid] = vp_unit.group
end

-- Replaces all airbases with single-unit ones
for k, base in pairs(airbases) do
    local ac_list, wpns_list, runways, lat, lon = FindAircraftAndMags(base)
    local new_base_name = base.name
    local new_base_id = GetEquivalentSingleUnitID(runways)
    local new_base = ScenEdit_AddUnit({side=side_name, unitname=new_base_name, type="Facility", dbid=new_base_id, Lat=lat, Lon=lon})
    for l, ac in pairs(ac_list) do
        local loadout_id = ScenEdit_GetLoadout({UnitName = ac.guid, loadoutid=0}).dbid or 3
        local new_unit = ScenEdit_AddUnit({type = 'Aircraft', unitname = ac.name, loadoutid = loadout_id, dbid = ac.dbid, side=side_name, base=new_base.guid})
        new_unit.readytime = ScenEdit_GetUnit({guid = ac.guid}).readytime_v
        if ac.mission ~= nil then
            ScenEdit_AssignUnitToMission(new_unit.guid, ac.mission.name)
        end
    end
    
    for m, wpn_record in pairs(wpns_list) do -- Copy over magazines
        ScenEdit_AddWeaponToUnitMagazine({guid=new_base.guid, wpn_dbid=m, number=wpn_record})
    end
    print(new_base.name.." converted to single-unit")
end

for n, base in pairs(airbases) do
    ScenEdit_DeleteUnit({side = side_name, name = base.name}, true)
end
