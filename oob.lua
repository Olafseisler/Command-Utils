-- get all units on a side
-- extract the base they are assigned to
-- report by base
local s = VP_GetSide({name='BLUFOR'})
local function split(str, pat)
local t = {}
local fpat = "(.-)" .. pat
local last_end = 1
local s, e, cap = str:find(fpat, 1)
while s do
if s ~= 1 or cap ~= "" then
table.insert(t,cap)
end
last_end = e+1
s, e, cap = str:find(fpat, last_end)
end
if last_end <= #str then
cap = str:sub(last_end)
table.insert(t, cap)
end
return t
end
local function sortName(a,b)
return(ScenEdit_GetUnit({guid=a}).name<ScenEdit_GetUnit({guid=b}).name)
end
local function orderedPairs(t,f)
local array = {}
for n in pairs(t) do array[#array +1] = n end
table.sort(array,f)
local index = 0
return function ()
index = index + 1
return array[index],t[array[index]]
end
end
-- main logic
local base = {}
for k,v in pairs(s.units)
do
local unit = ScenEdit_GetUnit({guid=v.guid})
if unit.base ~= nil then
local b = unit.base
if b.group ~= nil then
-- has a parent group; use it rather than the group members
if base[b.group.guid] == nil and b.group.guid ~= v.guid then
base[b.group.guid] = v.guid
elseif b.group.guid ~= v.guid then
base[b.group.guid] = base[b.group.guid] .. ',' .. v.guid
end
elseif base[b.guid] == nil and b.guid ~= v.guid then
base[b.guid] = v.guid
elseif b.guid ~= v.guid then
base[b.guid] = base[b.guid] .. ',' .. v.guid
end
elseif unit.group ~= nil then
local b = unit.group
if base[b.guid] == nil and b.guid ~= v.guid then
base[b.guid] = v.guid
elseif b.guid ~= v.guid then
base[b.guid] = base[b.guid] .. ',' .. v.guid
end
else
-- units not based somewhere
if base['xindependent'] == nil then
base['xindependent'] = v.guid
else
base['xindependent'] = base['xindependent'] .. ',' .. v.guid
end
end
end
local k,v
for k,v in orderedPairs(base)
do
print('\n')
if k == 'xindependent' then
print('Un-based units');
else
print('Base: ' .. ScenEdit_GetUnit({guid=k}).name);
end
local k1,v1
local t = split(v,',')
if t ~= nil then
-- group like names together
table.sort(t, sortName)
for k1,v1 in pairs(t)
do
if v1 == k then next(t) end
local unit = ScenEdit_GetUnit({guid=v1})
if unit.condition ~= nil then
print(string.format(" %s (%s)",unit.name, unit.condition));
else
print(string.format(" %s ",unit.name));
end
end
end
end