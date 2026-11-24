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
run("SealTwistVisual/SealTwistVisual.lua", "SealTwistVisual");
run("tests/seals.lua");
