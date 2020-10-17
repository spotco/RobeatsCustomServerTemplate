local RunService = game:GetService("RunService")

local Networking = {}
Networking.Server = {}
Networking.Client = {}

--// CLIENT METHODS:

function Networking.Client:Execute(name, ...)
		local r = script:WaitForChild(name, 5)
		if r ~= nil then
				return r:InvokeServer(...)
		end
		return nil
end

function Networking.Client:Listen(name, callback)
		local r = script:WaitForChild(name)
		if r ~= nil then
				r.OnClientInvoke = callback
		end
		return nil
end

--// SERVER METHODS:

function Networking.Server:Register(name, callback)
		local rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.OnServerInvoke = callback or (function()end)
		rf.Parent = script
end

function Networking.Server:Execute(name, plr, ...)
		local r = script:WaitForChild(name, 5)
		if r ~= nil then
				return r:InvokeClient(plr, ...)
		end
		return nil
end

return Networking