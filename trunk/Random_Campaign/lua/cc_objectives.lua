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
wesnoth.wml_actions.store_turns( { variable="custom_campaign.turn_limit" } )
objectives[c] = { "objective", { condition="lose", show_turn_counter="yes", description=_"Turns run out",
	{ "show_if", { { "variable", { name="custom_campaign.turn_limit", not_equals="-1" } } } }   } }
wesnoth.wml_actions.objectives(objectives)
