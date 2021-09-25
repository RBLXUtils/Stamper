--[[
	Stamper:

	Stamper is a hyper-efficient library made for handling functions
	that should run every x amount of seconds,
	Stamper handles it all in one connection / thread at a time,
	with custom scheduling!
]]

local RunService = game:GetService("RunService")

type CallbackFunction = (deltaTime: number) -> ()

type EventNode = {
	TimeOfLastUpdate: number,
	Seconds: number,
	Callback: CallbackFunction,

	Next: EventNode?,
	Previous: EventNode?
}

local TimePassed: number = 0
local NextEvent: EventNode? = nil

local Connection = {}
Connection.Connected = true
Connection.__index = Connection

function Connection:Disconnect()
	if self.Connected == false then
		return
	end

	self.Connected = false

	local _node: EventNode = self._node
	local _next: EventNode? = _node.Next
	local _prev: EventNode? = _node.Previous

	if _next then
		_next.Previous = _prev
	end

	if _prev then
		_prev.Next = _next
	else -- _node is 'NextEvent'
		NextEvent = _next
	end

	self._node = nil
end

export type Connection = typeof(
	setmetatable({}, Connection)
)

RunService.Heartbeat:Connect(function(frameDeltaTime: number)
	TimePassed += frameDeltaTime

	local node: EventNode? = NextEvent
	while node ~= nil do
		local deltaTime: number = TimePassed - node.TimeOfLastUpdate

		if deltaTime >= node.Seconds then
			node.TimeOfLastUpdate = TimePassed

			task.defer(
				node.Callback,
				deltaTime
			)
		end

		node = node.Next
	end
end)

return function(
	seconds: number,
	callback: CallbackFunction
): Connection

	assert(
		typeof(seconds) == 'number',
		"Seconds must be a number"
	)

	assert(
		typeof(callback) == 'function',
		"Handler must be a function"
	)

	local thisEvent: EventNode = {
		TimeOfLastUpdate = TimePassed,
		Seconds = seconds,
		Callback = callback,

		Next = NextEvent,
		Previous = nil
	}

	if NextEvent then
		NextEvent.Previous = thisEvent
	end
	NextEvent = thisEvent

	return setmetatable({
		Connected = true,
		_node = thisEvent
	}, Connection)
end
