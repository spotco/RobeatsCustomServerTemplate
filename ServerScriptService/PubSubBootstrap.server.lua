--[[
    // Filename: BootStrap.lua
    // Version 1.0
    // Release 1
    // Written by: HuotChu/BluJagu/ScottBishop
    // Description: Enables the Server to create RemoteEvents requested by the Client
]]--

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PubSub = require(ReplicatedStorage:WaitForChild('PubSub'))

--  --  --  --  --
--  If PubSub let the Client create RemoteEvents, the Server would not know, so PubSub fails.
--  Allowing the Server to create all the RemoteEvents keeps everything working nicely.
--  --  --  --  --

local CreateRemoteEvent = PubSub:FindFirstChild('CreateRemoteEvent')

local onCreateRemoteEvent = function (player, t)
    return PubSub.createEvent(t)
end

CreateRemoteEvent.OnServerInvoke = onCreateRemoteEvent
