-- scratch lua for random campaign

local rc = {}
local helper = wesnoth.require("lua/helper.lua")
local wml_actions = wesnoth.wml_actions

function rc.upgrade_era(era, era_type)
	-- receives an era table
	-- returns an upgraded era
	-- update leader, random_leader, recruit
	-- add check that era is a table, and era_type is a string
	local upgrade_era = rc.deep_copy(era)
	for multiplayer_side in helper.child_range(upgrade_era, "multiplayer_side") do
		multiplayer_side.recruit = rc.upgrade_recruit(multiplayer_side.recruit)
		multiplayer_side.leader = rc.upgrade_leader(multiplayer_side.leader)
		multiplayer_side.random_leader = rc.upgrade_leader(multiplayer_side.random_leader)
	end
	upgrade_era.era_type = era_type
	return upgrade_era
end

function rc.upgrade_image(image)
	-- receives an image path
	-- returns an image path
	-- update image. assume xxxx.png (ie, lich.png)
	-- that xxxx is the name of a unit_type
	-- not practical or necessary now.
	-- a placehold if ever needed
	return image
end
	
function rc.upgrade_recruit(list)
	-- receives a string which is a comma separated list of recruits.
	-- returns a list with each unit's next level up added if present
	-- here, we want to take each unit on the list and add only the immediate level-up
	-- not future ones.
	-- add check to make sure function is sent a string
	local units = rc.split(list, ",")
	local additions = {}
	for u = 1, #units do
		if wesnoth.unit_types[units[u]] and wesnoth.unit_types[units[u]].__cfg.do_not_list == nil then
			if wesnoth.unit_types[units[u]].__cfg.advances_to ~= "null" and wesnoth.unit_types[units[u]].__cfg.advances_to then
				local advances = rc.split(wesnoth.unit_types[units[u]].__cfg.advances_to, ",")
				for a = 1, #advances do
					table.insert(additions, advances[a])
				end
			end
		end
	end
	
	-- compare each entry in additions to each in units, if not present, add it.
	for a = 1, #additions do
		local is_present = false
		for u = 1, #units do
			if additions[a] == units[u] then
				is_present = true; break
			end
		end
		if is_present == false then
			table.insert(units, additions[a])
		end
	end
	
	table.sort(units)
	local new_list = table.concat(units, ",")
	return new_list
end

function rc.upgrade_leader(list)
	-- receives a string which is a comma separated list of leaders.
	-- returns a list with the next higher level leaders
	-- here, we want to take each unit on the list and replace with the immediate level-up
	-- not future ones.
	-- if there are no level-ups, use the same list that was sent.
	-- add check to make sure function is sent a string
	if list == nil then
		return list
	end
	local units = rc.split(list, ",")
	local additions = {}
	for u = 1, #units do
		if wesnoth.unit_types[units[u]] and wesnoth.unit_types[units[u]].__cfg.do_not_list == nil then
			if wesnoth.unit_types[units[u]].__cfg.advances_to ~= "null" and wesnoth.unit_types[units[u]].__cfg.advances_to then
				local advances = rc.split(wesnoth.unit_types[units[u]].__cfg.advances_to, ",")
				for a = 1, #advances do
					table.insert(additions, advances[a])
				end
			end
		end
	end
	
	-- check if there's anything in additions
	if #additions >= 1 then
		table.sort(additions)
		local new_list = table.concat(additions, ",")
		return new_list
	else
		return list
	end
end
	
function rc.analyze_era(era)
	-- receives an era table
	-- returns what type of era it is. (small_fry, default, aoh, eol, or other)
	-- add check to make sure a table/wml table is received
	local leader_count, level_sum = 0, 0
	for multiplayer_side in helper.child_range(era, "multiplayer_side") do
		-- split a list, check level of each unit (random_leader list should be most reliable.)
		-- and average it out.
		local lt
		if multiplayer_side.random_leader then
			lt = rc.split(multiplayer_side.random_leader, ",")
		else
			lt = rc.split(multiplayer_side.leader, ",")
		end
		for i,v in ipairs(lt) do
			if wesnoth.unit_types[v] then
				level_sum = level_sum + wesnoth.unit_types[v].level
			end
		end
		leader_count = leader_count + #lt
	end
	local result = helper.round(level_sum / leader_count)
	local era_type
	if         result == 1 then era_type = "small_fry"
		elseif result == 2 then era_type = "default"
		elseif result == 3 then era_type = "heroes"
		elseif result == 4 then era_type = "legends"
		else					era_type = "unknown"
	end
	return era_type
end

function rc.format_era_data(era)
	-- receives an era table
	-- returns an era table with only real multiplayer_sides
	-- insert check that era is in fact a wml table
	local processed_era = rc.deep_copy(era)	
	for e = #processed_era, 1, -1 do
		if processed_era[e][2].recruit == nil or processed_era[e][2].leader == nil then
			table.remove(processed_era, e)
		else
			-- sort recruit, so it can be compared to the recruit string in [store_sides]
			local t = rc.split(processed_era[e][2].recruit, ",")
			table.sort(t)
			processed_era[e][2].recruit = table.concat(t, ",")
		end
	end
	processed_era.era_type = rc.analyze_era(processed_era)
	return processed_era
end

function rc.deep_copy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function rc.split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find( str, delimiter, from  )
    while delim_from do
        table.insert( result, string.sub( str, from , delim_from-1 ) )
        from  = delim_to + 1
        delim_from, delim_to = string.find( str, delimiter, from  )
    end
    table.insert( result, string.sub( str, from  ) )
    return result
end

function rc.endlevel()
	wml_actions.endlevel({ result="defeat", carryover_report="no",
		carryover_percentage=0, carryover_add="no", bonus="no",
		linger_mode="no", save="no", replay_save="no" })
end

-- derive aoh & eol eras from a default type era
-- hardcode for rc_default, era_default & era_khalifate
-- as deriving would miss the ogre & lieutenant in aoh loyalists
-- default & aoh is probably the only eras to engage in such craziness
local era, e1, e2, e3
local eras = {}

-- hard coded default type eras
if wesnoth.game_config.mp_settings.mp_era == "rc_default" then
	e1 = rc.format_era_data(wesnoth.get_era("rc_default"))
	e2 = rc.format_era_data(wesnoth.get_era("rc_heroes"))
	e3 = rc.format_era_data(wesnoth.get_era("era_khalifate_legends"))
elseif wesnoth.game_config.mp_settings.mp_era == "era_default" then
	e1 = rc.format_era_data(wesnoth.get_era("era_default"))
	e2 = rc.format_era_data(wesnoth.get_era("era_heroes"))
	e3 = rc.format_era_data(wesnoth.get_era("era_legends"))
elseif wesnoth.game_config.mp_settings.mp_era == "era_khalifate" then
	e1 = rc.format_era_data(wesnoth.get_era("era_khalifate"))
	e2 = rc.format_era_data(wesnoth.get_era("era_khalifate_heroes"))
	e3 = rc.format_era_data(wesnoth.get_era("era_khalifate_legends"))
-- hard coded aoh type eras
elseif wesnoth.game_config.mp_settings.mp_era == "rc_heroes" then
	e2 = rc.format_era_data(wesnoth.get_era("rc_heroes"))
	e3 = rc.format_era_data(wesnoth.get_era("era_khalifate_legends"))
	e1 = e2
elseif wesnoth.game_config.mp_settings.mp_era == "era_heroes" then
	e2 = rc.format_era_data(wesnoth.get_era("era_heroes"))
	e3 = rc.format_era_data(wesnoth.get_era("era_legends"))
	e1 = e2
elseif wesnoth.game_config.mp_settings.mp_era == "era_khalifate_heroes" then
	e2 = rc.format_era_data(wesnoth.get_era("era_khalifate_heroes"))
	e3 = rc.format_era_data(wesnoth.get_era("era_khalifate_legends"))
	e1 = e2
-- make an era table with 3 eras based on selected era
-- yes, the formatting of eras for selecting an aoh era is hacky,
-- but this is minimally intrusive for the rest of the add-on.
else
	era = rc.format_era_data(wesnoth.game_config.era)
	if era.era_type == "default" then
		e1 = era
		e2 = rc.upgrade_era(e1, "heroes")
		e3 = rc.upgrade_era(e2, "legends")
	elseif era.era_type == "heroes" then
		e1 = era
		e2 = era
		e3 = rc.upgrade_era(e1, "legends")
	end
end
table.insert(eras, e1)
table.insert(eras, e2)
table.insert(eras, e3)
helper.set_variable_array("era", eras)

