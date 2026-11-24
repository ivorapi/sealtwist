const fs = require("node:fs");
const path = require("node:path");
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require("fengari");

const state = lauxlib.luaL_newstate();
lualib.luaL_openlibs(state);

function run(relativePath, ...args) {
    const file = path.join(__dirname, "..", relativePath);
    const source = to_luastring(fs.readFileSync(file, "utf8"));
    let status = lauxlib.luaL_loadbuffer(state, source, source.length, to_luastring("@" + relativePath));
    if (status === lua.LUA_OK) {
        for (const arg of args) lua.lua_pushstring(state, to_luastring(arg));
        status = lua.lua_pcall(state, args.length, 0, 0);
    }
    if (status !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(state, -1)));
}

run("tests/client.lua");
run("RapiTwist/RapiTwist.lua", "RapiTwist");
run("tests/seals.lua");
for (const pair of [
    ["Wisdom", "Light", "20357", "1328206", "20349", "1328198"],
    ["Fury", "Justice", "20423", "1311701", "20164", "1311705"],
    ["Crusader", "Command", "20308", "manual", "20920", "1311703"],
    ["Righteousness", "Martyrdom", "20154", "1311704", "407798", "manual"],
]) {
    run("tests/client.lua");
    run("tests/pair-settings.lua", ...pair);
    run("RapiTwist/RapiTwist.lua", "RapiTwist");
    run("tests/pair-checks.lua", ...pair);
}
console.log("PASS: selected pairs, rank filters, manual seals and per-slot swap cues");
