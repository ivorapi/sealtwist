local first, second, rank, echo, secondRank, secondEcho = ...
send("ADDON_LOADED", "RapiTwist")
local firstSlot, secondSlot = containers[1].slots.firstSeal, containers[1].slots.secondSeal
assert(firstSlot.filter[tonumber(rank)] and secondSlot.filter[tonumber(secondRank)])
local function check(slot, rankID, echoID, active, destination, goal)
    local values = {[tonumber(rankID)] = 0}
    auras(values)
    assert(visible(slot))
    if echoID == "manual" then
        assert(visible(withText(slot, active .. " (manual)")))
        return
    end
    local tracker
    for _, child in ipairs(slot.children) do
        if child.kind == "AuraContainer" then tracker = child end
    end
    local cue = tracker.slots.alert.children[1]
    for n = 1, 3 do
        values[tonumber(echoID)] = n
        auras(values)
        assert(visible(withText(cue, "Swap to " .. destination)) == (n >= goal))
    end
end
check(firstSlot, rank, echo, first, second, 2)
check(secondSlot, secondRank, secondEcho, second, first, 3)
