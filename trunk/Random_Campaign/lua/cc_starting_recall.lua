-- #textdomain wesnoth-Random_Campaign

local starting_recall = wesnoth.get_variable("cc_chosen_army.starting_recall")
-- recall any leaders, expendable leaders, and heroes
local loc = wesnoth.get_starting_location(1)
local recall_list = wesnoth.get_recall_units({ side=1 })
for u = 1, #recall_list do
	if recall_list[u].canrecruit == true or recall_list[u].role == "Hero" then
		local id = recall_list[u].id
		wesnoth.wml_actions.recall({ x=loc[1], y=loc[2], id=id, show="no", fire_event="no" })
	end
end
-- additional recalls
if starting_recall == -1 then
	-- recall all loyal units
	local recall_list = wesnoth.get_recall_units({ side=side })
	for i = 1, #recall_list do
		wesnoth.wml_actions.recall({ x=loc[1], y=loc[2], { "filter_wml", { upkeep="loyal" }}, show="no", fire_event="no" })
	end
elseif starting_recall > 0 then
	-- sort units by value and recall the specified number
	-- sort order: loyal, level, least XP to levelup
	local recall_list = wesnoth.get_recall_units({ side=side })
	local function unit_value_sort(u1, u2)				
		if u1.__cfg.upkeep == u2.__cfg.upkeep then
			if u1.__cfg.level == u2.__cfg.level then
				return u1.max_experience - u1.experience < u2.max_experience - u2.experience
			else
				return u1.__cfg.level > u2.__cfg.level
			end
		else
			return u1.__cfg.upkeep > u2.__cfg.upkeep
		end
	end
	table.sort(recall_list, unit_value_sort)
	for u = 1, starting_recall do
		local id = recall_list[u].id
		wesnoth.wml_actions.recall({ x=loc[1], y=loc[2], id=id, show="no", fire_event="no" })
	end
end
