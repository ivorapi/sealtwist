# RapiTwist

A visual seal-twisting tracker for paladins in **WoW Forever (interface 16001)**. Choose two seals and an echo goal for each. Each echo fills a matching segment on the left and right of the character. At the goal, both arcs pulse briefly in the destination seal’s color and the swap cue appears below the character. Right-click the minimap button to position both arcs together.

## Set up your pair

1. Open the minimap button or type `/rapitwist`.
2. Click the seal name in **First** or **Second** to cycle through choices. Picking the other slot's seal exchanges the pair. Click **Echo goal** in each row to cycle through one, two or three stacks.
3. Choose **Apply and reload UI** outside combat. Closing the panel discards pending seal edits.

Command, Righteousness, Fury, Justice, Light and Wisdom use the player's native echo auras. Crusader and Martyrdom display their active state with **Manual** timing. Gold identifies the first slot and blue identifies the second. Upgrading to the side-arc layout centers the tracker once. The default pair is Command at three echoes and Righteousness at one.

## Installation

Download [RapiTwist-1.5.1.zip](https://github.com/ivorapi/sealtwist/releases/download/v1.5.1/RapiTwist-1.5.1.zip). Extract the `RapiTwist` folder into `World of Warcraft/_forever_/Interface/AddOns/`. Enable RapiTwist in the addon list. Use `/reload` after updating from 1.3.0.

When upgrading from SealTwist Visual 1.2.x, close WoW and move the old `SealTwistVisual` addon folder out of `Interface/AddOns`. To keep its settings, copy `WTF/Account/<account>/SavedVariables/SealTwistVisual.lua` to `RapiTwist.lua` in the same directory and rename the initial variable from `SealTwistVisualDB` to `RapiTwistDB`. Keep your existing RapiTwist settings file if present.

## Controls

Right-click the minimap button to move the tracker outside combat. Drag the minimap button to reposition it. The settings panel includes size, opacity and visibility controls. [All commands](RapiTwist/README.txt)

## Development

The addon uses Blizzard's native aura containers. The Lua tests simulate the client and exercise seal selection, stack thresholds, alerts and positioning. From the repository root, using Node.js 22, npm and PowerShell 7:

```sh
npm ci
npm test
pwsh -File scripts/package.ps1
```

The installable ZIP is written to `dist/`. [Changelog](CHANGELOG.md) · [MIT license](LICENSE)
