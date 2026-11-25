send("ADDON_LOADED","RapiTwist")
local root, panel, mini, db = RapiTwistFrame, RapiTwistOptions, RapiTwistMinimapButton, RapiTwistDB
local live, handle=root.children[1],root.children[2]
assert(#containers==5 and db.x==0 and db.y==-55 and db.layoutVersion==3 and db.locked==nil)
assert(root.w==180 and root.h==132 and not root.mouse and not live.mouse)
assert(not visible(handle) and not visible(panel) and visible(mini))
local outer,ord,ordAlert,right,rightAlert=unpack(containers)
assert(not ord.slots.lamp2.bar:IsShown() and not ord.slots.lamp3.bar:IsShown())
assert(ord.slots.lamp2.options.minApplications==2 and ordAlert.slots.alert.options.minApplications==3)
local function probe(aurasNow,ordOn,rightOn)
    auras(aurasNow)
    assert(visible(outer.slots.firstSeal)==ordOn and visible(outer.slots.secondSeal)==rightOn)
end
probe({},false,false)
assert(#live.children==1 and live.children[1]==outer,"idle HUD draws elements")
for n=0,3 do
    probe({[20375]=0,[1311703]=n>0 and n or nil},true,false)
    for i=1,3 do
        local slot=ord.slots["lamp"..i]
        assert(visible(slot.children[1])==(n>=i))
    end
    assert(visible(ordAlert.slots.alert.children[1])==(n==3))
    local cue=ordAlert.slots.alert.children[1]
    assert(visible(withText(ord.parent,"HIT"))==(n<3))
    assert(visible(withText(cue,"SWAP"))==(n==3))
    for _,region in ipairs(cue.children) do assert(not region.color, "Solid swap backdrop") end
    local hit,swap=withText(ord.parent,"HIT"),withText(cue,"SWAP")
    assert(math.abs(hit.point[5]-swap.point[5])>=18, "Cue baselines overlap")
    for _,region in ipairs(ord.parent.children) do
        if region.tint then assert(region.tint[3]>region.tint[1] and region.tint[4]<.4, "Warm or bright empty arc") end
    end
    local pulse=cue.children[1]
    assert(pulse.template=="RapiTwistArcPulseTemplate" and visible(pulse)==(n==3))
    local left,right=false,false
    for _,tex in ipairs(pulse.children) do
        left=left or tex.point[4]<30
        right=right or tex.point[4]>100
        assert(tex.tint[1]==1 and tex.tint[2]==.53 and tex.blend=="ADD", "Expected coral swap pulse")
    end
    assert(left and right)
end
for _,n in ipairs({0,1,1,2,3,1,1}) do
    probe({[20375]=0,[1311703]=n},true,false)
    assert(visible(ord.slots.lamp1.children[1]))
    assert(visible(ord.slots.lamp2.bar)==(n>=2))
    assert(visible(ordAlert.slots.alert.bar)==(n>=3))
end
-- Swap from three stored echoes. A missed hit leaves the aura snapshot unchanged.
for attempt=1,2 do
    probe({[21084]=0,[1311703]=3},false,true)
    assert(visible(withText(right.parent,"HIT")))
    assert(not visible(withText(rightAlert.slots.alert.children[1],"SWAP")))
end
assert(not visible(right.slots.lamp1) and not visible(rightAlert.slots.alert.children[1]))
probe({[21084]=0,[1311704]=0},false,true)
assert(visible(rightAlert.slots.alert.children[1]) and visible(right.slots.lamp1))
local cue=rightAlert.slots.alert.children[1]
assert(visible(cue.children[1]) and cue.children[1].children[1].tint[1]==1)
probe({[20920]=0,[1311703]=1,[1311704]=1},true,false)
assert(visible(ord.slots.lamp1) and not visible(ordAlert.slots.alert.children[1]))
assert(visible(withText(ord.parent,"HIT")))
probe({},false,false)
probe({[20375]=0},true,false)
assert(visible(withText(ord.parent,"HIT")) and not visible(ordAlert.slots.alert.bar))
probe({},false,false)
click(mini)
assert(visible(panel))
mini.scripts.OnEnter(mini)
send("PLAYER_TARGET_CHANGED")
mini.scripts.OnLeave(mini)
assert(TargetFrame:IsShown() and GameTooltip:IsShown() and not RapiTwistMinimapTip:IsShown())
local pluses={}
for _,child in ipairs(panel.children) do if child.text=="+" then table.insert(pluses,child) end end
click(pluses[1]); assert(math.abs(db.scale-1.1)<.001)
click(withText(panel,"-")); assert(math.abs(db.scale-1)<.001)
local minuses={}
for _,child in ipairs(panel.children) do if child.text=="-" then table.insert(minuses,child) end end
click(minuses[2]); assert(math.abs(live.alpha-.9)<.001)
click(withText(panel,"Move tracker"))
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
assert(not withText(panel,"Move tracker").enabled)
combat=false; send("PLAYER_REGEN_ENABLED")
click(withText(panel,"Show with an active seal")); assert(not root.shown)
click(withText(panel,"Move tracker")); assert(visible(handle)); click(handle,"RightButton")
assert(not root.shown)
combat=true; send("PLAYER_REGEN_DISABLED"); assert(root.shown)
local cmd=SlashCmdList.RAPITWIST
cmd("ocultar"); assert(not root.shown and visible(mini))
cmd("siempre"); assert(root.shown)
cmd("escala 100"); assert(db.scale==1)
mini.scripts.OnMouseDown(); mini.scripts.OnDragStart(mini); mini.scripts.OnUpdate()
assert(math.abs(db.angle-90)<.001)
mini.scripts.OnDragStop(mini); assert(not mini.scripts.OnUpdate)
click(mini); assert(not panel.shown)
mini.scripts.OnMouseDown(); click(mini); assert(panel.shown)
click(withText(panel,"Reset position")); assert(db.x==0 and db.y==-55)
cmd("reset"); assert(db.angle==220 and db.alpha==1 and db.scale==1)
combat=false; send("PLAYER_REGEN_ENABLED")
click(withText(panel,"Command"))
assert(db.firstSeal=="Command" and db.secondSeal=="Righteousness")
click(withText(panel,"3 / 3"))
local reloads=0
function ReloadUI() reloads=reloads+1 end
local apply=withText(panel,"Apply and reload UI")
combat=true; send("PLAYER_REGEN_DISABLED"); click(apply)
assert(not apply.enabled and reloads==0)
combat=false; send("PLAYER_REGEN_ENABLED"); click(apply)
assert(reloads==1 and db.firstSeal=="Righteousness" and db.secondSeal=="Command" and db.firstCount==1)
print("PASS: native seals, thresholds, 0-stack first echo, expiry, idle, settings, migration, pointer, drag/save, minimap orbit and combat transitions")
