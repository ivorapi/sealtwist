send("ADDON_LOADED","SealTwistVisual")
local root, panel, mini, db = SealTwistVisualFrame, SealTwistVisualOptions, SealTwistVisualMinimapButton, SealTwistVisualDB
local live, handle=root.children[1],root.children[2]
assert(#containers==3 and db.x==190 and db.layoutVersion==2 and db.locked==nil)
assert(root.w==144 and root.h==40 and not root.mouse and not live.mouse)
assert(not visible(handle) and not visible(panel) and visible(mini))
local outer,ord,right=containers[1],containers[2],containers[3]
assert(not ord.slots.lamp2.bar:IsShown() and not ord.slots.lamp3.bar:IsShown())
assert(ord.slots.lamp2.options.minApplications==2 and ord.slots.alert.options.minApplications==3)
local function probe(aurasNow,ordOn,rightOn)
    auras(aurasNow)
    assert(visible(outer.slots.commandSeal)==ordOn and visible(outer.slots.rightSeal)==rightOn)
end
probe({},false,false)
assert(#live.children==1 and live.children[1]==outer,"idle HUD draws elements")
for n=0,3 do
    probe({[20375]=0,[1311703]=n>0 and n or nil},true,false)
    for i=1,3 do
        local slot=ord.slots["lamp"..i]
        assert(visible(slot.children[1])==(n>=i))
    end
    assert(visible(ord.slots.alert.children[1])==(n==3))
    local cue=ord.slots.alert.children[1]
    assert(#cue.children==4 and cue.children[4].kind=="Font")
    for i=1,3 do assert(cue.children[i].blend=="ADD" and visible(cue.children[i])==(n==3)) end
end
for _,n in ipairs({0,1,1,2,3,1,1}) do
    probe({[20375]=0,[1311703]=n},true,false)
    assert(visible(ord.slots.lamp1.children[1]))
    assert(visible(ord.slots.lamp2.bar)==(n>=2))
    assert(visible(ord.slots.alert.bar)==(n>=3))
end
probe({[21084]=0,[1311703]=3},false,true)
assert(not visible(right.slots.lamp1) and not visible(right.slots.alert.children[1]))
probe({[21084]=0,[1311704]=0},false,true)
assert(visible(right.slots.alert.children[1]) and visible(right.slots.lamp1))
local cue=right.slots.alert.children[1]
assert(#cue.children==2 and cue.children[1].blend=="ADD" and visible(cue.children[1]))
probe({[20920]=0,[1311703]=1,[1311704]=1},true,false)
assert(visible(ord.slots.lamp1) and not visible(ord.slots.alert.children[1]))
probe({},false,false)
click(mini)
assert(visible(panel))
mini.scripts.OnEnter(mini)
send("PLAYER_TARGET_CHANGED")
mini.scripts.OnLeave(mini)
assert(TargetFrame:IsShown() and GameTooltip:IsShown() and not SealTwistVisualMinimapTip:IsShown())
local pluses={}
for _,child in ipairs(panel.children) do if child.text=="+" then table.insert(pluses,child) end end
click(pluses[1]); assert(math.abs(db.scale-1.1)<.001)
click(withText(panel,"-")); assert(math.abs(db.scale-1)<.001)
local minuses={}
for _,child in ipairs(panel.children) do if child.text=="-" then table.insert(minuses,child) end end
click(minuses[2]); assert(math.abs(live.alpha-.9)<.001)
click(withText(panel,"Mover indicador"))
assert(not visible(panel) and visible(handle) and not visible(live))
handle.scripts.OnDragStart(handle); assert(root.moving)
root.cx,root.cy=1110,390
handle.scripts.OnDragStop(handle)
assert(db.x==150 and db.y==-150 and not root.moving and not visible(handle))
click(mini,"RightButton"); assert(visible(handle))
combat=true; send("PLAYER_REGEN_DISABLED")
assert(not visible(handle))
click(mini,"RightButton"); assert(not visible(handle))
click(mini)
assert(not withText(panel,"Mover indicador").enabled)
combat=false; send("PLAYER_REGEN_ENABLED")
click(withText(panel,"Cuándo mostrar · Con sello activo")); assert(not root.shown)
click(withText(panel,"Mover indicador")); assert(visible(handle)); click(handle,"RightButton")
assert(not root.shown)
combat=true; send("PLAYER_REGEN_DISABLED"); assert(root.shown)
local cmd=SlashCmdList.SEALTWISTVISUAL
cmd("ocultar"); assert(not root.shown and visible(mini))
cmd("siempre"); assert(root.shown)
cmd("escala 100"); assert(db.scale==1)
mini.scripts.OnMouseDown(); mini.scripts.OnDragStart(mini); mini.scripts.OnUpdate()
assert(math.abs(db.angle-90)<.001)
mini.scripts.OnDragStop(mini); assert(not mini.scripts.OnUpdate)
click(mini); assert(not panel.shown)
mini.scripts.OnMouseDown(); click(mini); assert(panel.shown)
click(withText(panel,"Reubicar")); assert(db.x==190 and db.y==-160)
cmd("reset"); assert(db.angle==220 and db.alpha==1 and db.scale==1)
print("PASS: native seals, thresholds, 0-stack first echo, expiry, idle, settings, migration, pointer, drag/save, minimap orbit and combat transitions")
