--[[
    // Filename: PubSub.lua
    // Version 1.1
    // Written by: HuotChu/BluJagu/ScottBishop
    // Description: Handles in game event management compatible with FilteringEnabled
]]--

--https://github.com/HuotChu/roblox-pubsub << SOURCE

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PubSubEventFolder = ReplicatedStorage:FindFirstChild('PubSubEventFolder')

if not PubSubEventFolder then
    PubSubEventFolder = Instance.new('Folder', ReplicatedStorage)
    PubSubEventFolder.Name = 'PubSubEventFolder'
end

local RemoteFunction = PubSubEventFolder:FindFirstChild('CreateRemoteEvent')

if not RemoteFunction then
    RemoteFunction = Instance.new('RemoteFunction', PubSubEventFolder)
    RemoteFunction.Name = 'CreateRemoteEvent'
end

local context = function ()
    if game.Players.LocalPlayer then return 'Client' end
    return 'Server'
end

local createEvent = function (eventName)
    local RemoteEvent = PubSubEventFolder:FindFirstChild(eventName)

    if not RemoteEvent then
        RemoteEvent = Instance.new('RemoteEvent', PubSubEventFolder)
        RemoteEvent.Name = eventName
    end

    return RemoteEvent
end

local Topics = {}

local subscribe = function (topic, callBack, handle, shouldCreateRemote)
    local context = context()
    local native = 'On'..context..'Event'
    local nativeHandle, subscription
    local t, e

    if not handle then return false end

    if not Topics[topic] then Topics[topic] = {} end

    t = Topics[topic]

    if shouldCreateRemote ~= 'noRemote' then
        e = PubSubEventFolder:FindFirstChild(topic)
        if not e then
            if context == 'Client' then
                e = RemoteFunction:InvokeServer(topic)
            else
                e = createEvent(topic)
            end
        end
    end

    subscription = {callBack = callBack}

    if e then
        nativeHandle = e[native]:Connect(callBack)
        subscription.nativeHandle = nativeHandle
    end

    if context == 'Client' then handle = game.Players.LocalPlayer.Name..'_'..handle end

    Topics[topic][handle] = subscription

    return handle
end

local s = function (topic, callBack, handle, shouldCreateRemote)
    local co = coroutine.create(subscribe)
    coroutine.resume(co, topic, callBack, handle, shouldCreateRemote)
end

local unsubscribe = function (topic, handle)
    local t = Topics[topic]

    if not t or not handle then return end

    local target = t[handle]
    local nativeHandle

    if t and target then
        nativeHandle = target.nativeHandle
        if nativeHandle then
            nativeHandle:Disconnect()
        end
        t[handle] = nil
    end
end

local removePlayer = function (playerName)
    local children = PubSubEventFolder:GetChildren()
    local found = 0
    local e, child, childName

    for i = 1, #children do
        child = children[i]
        childName = child.Name
        found = string.find(childName, playerName..'_')
        if found == 1 then
            Topics[childName] = nil
            child:Destroy()
        end
    end
end

local publish = function (topic, ...)
    local handles, e

    if not Topics[topic] then Topics[topic] = {} end

    handles = Topics[topic]

    for handle, f in pairs(handles) do
        if type(f.callBack) == 'function' then
            pcall(f.callBack, ...)
        end
    end

    e = PubSubEventFolder:FindFirstChild(topic)

    if not e then return end

    if context() == 'Server' then
        e:FireAllClients(...)
    else
        e:FireServer(...)
    end
end

local p = function (topic, ...)
    local co = coroutine.create(publish)
    coroutine.resume(co, topic, ...)
end

local FindFirstChild = function (this, name)
    return PubSubEventFolder:FindFirstChild(name)
end

return {
    createEvent = createEvent,
    publish = p,
    subscribe = s,
    unsubscribe = unsubscribe,
    removePlayer = removePlayer,
    FindFirstChild = FindFirstChild
}