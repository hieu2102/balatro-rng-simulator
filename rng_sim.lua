#!/usr/bin/env luajit
local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function print_table(tbl, indent, breakline)
    if not tbl then
        return
    end
    if not indent then
        indent = 0
    end
    if not breakline then
        linebreak_char = ""
    else
        linebreak_char = "\r\n"
    end
    local toprint = string.rep(" ", indent) .. "{\r\n" .. linebreak_char
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. "= "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. "," .. linebreak_char
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\"," .. linebreak_char
        elseif (type(v) == "table") then
            toprint = toprint .. tprint(v, indent + 2) .. "," .. linebreak_char
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\"," .. linebreak_char
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "\r\n}"
    print(toprint)
end

function generate_starting_seed()
    pseudorandom = {}
    pseudorandom.seed = "MTEP6SI"
    for k, v in pairs(pseudorandom) do
        if v == 0 then
            pseudorandom[k] = pseudohash(k .. pseudorandom.seed)
        end
    end
    pseudorandom.hashed_seed = pseudohash(pseudorandom.seed)

    return pseudorandom
end
function pseudohash(str)
    if true then
        local num = 1
        for i = #str, 1, -1 do
            num = ((1.1239285023 / num) * string.byte(str, i) * math.pi + math.pi * i) % 1
        end
        return num
    else
        str = string.sub(string.format("%-16s", str), 1, 24)

        local h = 0

        for i = #str, 1, -1 do
            h = bit.bxor(h, bit.lshift(h, 7) + bit.rshift(h, 3) + string.byte(str, i))
        end
        return tonumber(string.format("%.13f", math.sqrt(math.abs(h)) % 1))
    end
end

function pseudoseed(key, predict_seed)
    if key == 'seed' then
        return math.random()
    end

    if predict_seed then
        local _pseed = pseudohash(key .. (predict_seed or ''))
        _pseed = math.abs(tonumber(string.format("%.13f", (2.134453429141 + _pseed * 1.72431234) % 1)))
        return (_pseed + (pseudohash(predict_seed) or 0)) / 2
    end

    if not pseudorandom[key] then
        pseudorandom[key] = pseudohash(key .. (pseudorandom.seed or ''))
    end

    pseudorandom[key] =
        math.abs(tonumber(string.format("%.13f", (2.134453429141 + pseudorandom[key] * 1.72431234) % 1)))
    return (pseudorandom[key] + (pseudorandom.hashed_seed or 0)) / 2
end

function pseudorandom_element(_t, seed)

    if seed then
        -- print('create rng sequence for seed: ', seed)
        math.randomseed(seed)
    end
    local keys = {}
    for k, v in pairs(_t) do
        keys[#keys + 1] = {
            k = k,
            v = v
        }
    end

    if keys[1] and keys[1].v and type(keys[1].v) == 'table' and keys[1].v.sort_id then
        table.sort(keys, function(a, b)
            return a.v.sort_id < b.v.sort_id
        end)
    else
        table.sort(keys, function(a, b)
            return a.k < b.k
        end)
    end

    local key = keys[math.random(#keys)].k
    if seed then
        -- print('pseudorandom_element - choosing for seed value:', seed)
        for i = 1, #keys do
            if type(keys[i].v) == 'table' then
                print('pseudorandom_element - sorted input list:', "index:", i, ";key:", keys[i].k, ";label:",
                    keys[i].v.name)
            else
                -- print("index:", i, ";key:", keys[i].k, ";label:", keys[i].v)
            end
        end
        if type(_t[key]) == 'table' then
            print(string.format('pseudorandom_element - chosen key: %d [%s]', key, _t[key].name))
            return _t[key].name
        else
            return key
        end
    end
end



function trigger_invisible_joker(joker_list, ij_indx)
    print("===== triggering Invisible Joker RNG =====")
    seed_value = pseudoseed('invisible')
    -- filtering jokers
    local temp_pool = {}
    if not ij_indx
    then 
        local found_ij = false
        -- only 1 IJ
        for k, v in pairs(joker_list) do
            if v.name == 'Invisible Joker' and not found_ij then
                found_ij = true
            else 
                table.insert(temp_pool, v)
            end
        end
    else 
        for i = 1, #joker_list do 
            if i ~= ij_indx then 
                temp_pool[#joker_list +1 ] = joker_list[i]
            end 
        end     
    end
    

    cloned_joker_name = pseudorandom_element(temp_pool, seed_value)
    -- updating joker_list
    for k, v in pairs(joker_list) do
        if v.name == 'Invisible Joker' then
            v.name = cloned_joker_name
        end
    end

end

function trigger_ectoplasm(joker_list)
    print("===== triggering Ectoplasm RNG =====")
    seed_value = pseudoseed('ectoplasm')
    -- filtering jokers
    local temp_pool = {}
    for k, v in pairs(joker_list) do
        if not v.edition then
            table.insert(temp_pool, v)
        end
    end
    -- local temp_pool = (self.ability.name == 'The Wheel of Fortune' and self.eligible_strength_jokers) or
    --   ((self.ability.name == 'Ectoplasm' or self.ability.name == 'Hex') and
    --   self.eligible_editionless_jokers) or {}
    local eligible_card = pseudorandom_element(temp_pool, seed_value)

end

function reroll_boss(boss_list)
    seed_value = pseudoseed('boss')
    -- filter out bosses above min use
    local min_use = 100
    local filtered_list = {}
    for k, v in pairs(boss_list) do
        if min_use > v then
            min_use = v
        end
    end
    for k, v in pairs(boss_list) do
        if v <= min_use then
            filtered_list[k] = v
        end
    end
    -- print('min use', min_use)
    print_table(filter)
    local rolled_boss = pseudorandom_element(filtered_list, seed_value)
    print('rolled_boss', rolled_boss)
    for k, v in pairs(boss_list) do
        if k == rolled_boss then
            boss_list[k] = v + 1
        end
    end
    return rolled_boss
end

function roll_for_boss(boss_list, target_boss)
    print(string.format('===== Reroll for boss %s =====', target_boss))
    local counter = 0
    local rolled_boss = reroll_boss(boss_list)
    while rolled_boss ~= target_boss do
        rolled_boss = reroll_boss(boss_list)
        -- print(target_boss, rolled_boss, rolled_boss == target_boss, rolled_boss ~= target_boss)
        counter = counter + 1
    end
    print_table(boss_list)
    print(string.format("Reroll for %s tooks %d tries", target_boss, counter))
end

jokers_table = {
 
}

pseudorandom = generate_starting_seed()

-- trigger_ectoplasm(jokers_table)
boss_list = {
    bl_hook = 0,
    bl_needle = 0,
    bl_mark = 1,
    bl_psychic = 1,
    bl_goad = 0,
    bl_water = 0,
    bl_wheel = 0,
    bl_tooth = 0,
    bl_eye = 0,
    bl_wall = 0,
    bl_flint = 1,
    bl_plant = 0,
    bl_pillar = 0,
    bl_manacle = 0,
    bl_house = 0,
    bl_window = 0,
    bl_arm = 1,
    bl_club = 1,
    bl_fish = 0,
    bl_head = 1,
    bl_mouth = 1
}

-- for i = 3, 20, 1 do 
--     print('roll time: ' , i )
-- roll_for_boss(boss_list, 'bl_manacle')
-- end 

-- for i = 1, 20 , 1 do 

-- print(reroll_boss(boss_list))
-- end

joker_adding_stream = {
{ name = 'scary face'},
{ name = 'Invisible Joker'},
{ name = 'chicot'},
{ name = 'brainstorm'},
{ name = 'perkeo'},
{ name = 'sock and buskin'},
{ name = 'blueprint'},
{ name = 'Invisible Joker'},
{ name = 'baron'},
{ name = 'Invisible Joker'},
{ name = 'Invisible Joker'},
{ name = 'Invisible Joker'},
{ name = 'Mime'},
-- { name = 'Invisible Joker'},
-- { name = 'Invisible Joker'},
}

jokers_list = {}
-- trigger invisible joker after joker #i is added 
invis_proc_indx = {4,9,11}

-- remove joker x after add joker #y
remove_joker_stream = {{ at_idx = 6, remove_jk = 1 }}
for k, v in pairs(joker_adding_stream)
do 
    if remove_joker_stream[1] ~= nil and remove_joker_stream[1].at_idx == k
    then 
        print('remove joker')
        jokers_list[remove_joker_stream[1].remove_jk] = nil
    end 
    table.insert(jokers_list, v)
    if has_value(invis_proc_indx, k)
    then 
        trigger_invisible_joker(jokers_list)
    end
end 

-- trigger_invisible_joker(jokers_table)
