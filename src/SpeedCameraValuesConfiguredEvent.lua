SpeedCameraValuesConfiguredEvent = {}
SpeedCameraValuesConfiguredEvent_mt = Class(SpeedCameraValuesConfiguredEvent, Event)

InitEventClass(SpeedCameraValuesConfiguredEvent, "SpeedCameraValuesConfiguredEvent")

function SpeedCameraValuesConfiguredEvent.emptyNew()
	local self = Event.new(SpeedCameraValuesConfiguredEvent_mt)
	return self
end

function SpeedCameraValuesConfiguredEvent.new(id, speedLimit, ownerGetsMoney)
	local self = SpeedCameraValuesConfiguredEvent.emptyNew()
    self.id = id
	self.speedLimit = speedLimit
    self.ownerGetsMoney = ownerGetsMoney

	return self
end

function SpeedCameraValuesConfiguredEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, self.id)
    streamWriteInt32(streamId, self.speedLimit)
    streamWriteBool(streamId, self.ownerGetsMoney)
end

function SpeedCameraValuesConfiguredEvent:readStream(streamId, connection)
    self.id = NetworkUtil.readNodeObjectId(streamId)
	self.speedLimit = streamReadInt32(streamId)
	self.ownerGetsMoney = streamReadBool(streamId)
    self:run(connection)
end

function SpeedCameraValuesConfiguredEvent:run(connection)
    local object = NetworkUtil.getObject(self.id)

    if object == nil then
        Logging.error("Placeable object does not exist!")
        return
    end

    object:onSpeedCameraPlaced(self.speedLimit, self.ownerGetsMoney, nil, nil, true)

    if not connection:getIsServer() then
        g_server:broadcastEvent(SpeedCameraValuesConfiguredEvent.new(self.id, self.speedLimit, self.ownerGetsMoney))
    end
end


function SpeedCameraValuesConfiguredEvent.sendEvent(placeable, ...)
    local id = NetworkUtil.getObjectId(placeable)
	if g_server ~= nil then
		g_server:broadcastEvent(SpeedCameraValuesConfiguredEvent.new(id, ...))
	else
        g_client:getServerConnection():sendEvent(SpeedCameraValuesConfiguredEvent.new(id, ...))
	end
end