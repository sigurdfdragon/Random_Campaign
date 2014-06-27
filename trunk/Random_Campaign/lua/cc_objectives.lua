-- #textdomain wesnoth-Random_Campaign

_ = wesnoth.textdomain "wesnoth-Random_Campaign"
local side = 1
-- set objectives
local objectives = { side=side }
local c = 1
objectives[c] = { "objective", { condition="win", description=_"Defeat enemy leader" } }
c = c + 1
local units = wesnoth.get_units({ side=side })
for u = 1, #units do
	if units[u].id == "Commander" and units[u].role == "Leader" then
		objectives[c] = { "objective", { condition="lose", description=_"Death of " .. units[u].name } }
		c = c + 1
	end
end
for u = 1, #units do
	if units[u].role == "Leader" and units[u].id ~= "Commander" then
		objectives[c] = { "objective", { condition="lose", description=_"Death of " .. units[u].name } }
		c = c + 1
	end
end
if c == 2 then -- All leaders are expendable, therefore use this objective
	objectives[c] = { "objective", { condition="lose", description=_"Death of your leader(s)" } }
	c = c + 1
end
for u = 1, #units do
	if units[u].role == "Hero" then
		objectives[c] = { "objective", { condition="lose", description=_"Death of " .. units[u].name } }
		c = c + 1
	end
end
local level = wesnoth.get_variable("level")
if level == 7 then
    objectives[c] = { "note", { red=0, blue=255, green=255,
		description="<b>" .. _"This is the last scenario." .. "</b>" } }
else
	local turns = wesnoth.get_variable("random_campaign.turn_limit")
	wesnoth.wml_actions.modify_turns( { value=turns } )
	objectives[c] = { "objective", { condition="lose", show_turn_counter="yes", description=_"Turns run out",
		{ "show_if", { { "variable", { name="random_campaign.turn_limit", not_equals="-1" } } } }   } }
	c = c + 1
	objectives[c] = { "gold_carryover", { bonus=false, carryover_percentage=0 } }
end
wesnoth.wml_actions.objectives(objectives)
