PlaceableSpeedCamera = {
    prerequisitesPresent = function (specializations)
        return true
    end
}

function PlaceableSpeedCamera.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onWeighingTriggerCallback", PlaceableSpeedCamera.onSpeedCameraTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "calculateCost", PlaceableSpeedCamera.calculateCost)
end

function PlaceableSpeedCamera.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSpeedCamera.onLoad)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSpeedCamera.onDelete)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableSpeedCamera.onUpdate)
end

function PlaceableSpeedCamera:onLoad(savegame)
    local spec = self.spec_speedCamera
    local key = "placeable.speedCamera"
    spec.trigger = self.xmlFile:getValue(key .. "#triggerNode", nil, self.components, self.i3dMappings)

    if spec.trigger == nil then
		Logging.xmlError(self.xmlFile, "Missing vehicle triggerNode for speed camera")

		return
	end

    addTrigger(spec.trigger, "onSpeedCameraTriggerCallback", self)
    spec.flashLight = self.xmlFile:getValue(key .. "#flashLightNode", nil, self.components, self.i3dMappings)
    spec.speedLimit = self.xmlFile:getInt(key .. ".speedLimit", 50)
    -- free limit
    spec.speedLimit =  spec.speedLimit + math.min(5, spec.speedLimit * 0.1)
    spec.costPerKMH = self.xmlFile:getInt(key .. ".costPerKMH", 50)
    spec.count = 0
    spec.timer = 0
    spec.flashed = false

    if spec.flashLight ~= nil then
        setVisibility(spec.flashLight, false)
    end
end

function PlaceableSpeedCamera:onDelete()
    local spec = self.spec_speedCamera

    if spec.trigger ~= nil then
        removeTrigger(spec.trigger)

        spec.trigger = nil
    end
end

function PlaceableSpeedCamera:onUpdate(dt)
    local spec = self.spec_speedCamera

    if spec.flashed then
        spec.timer = spec.timer + dt
    end

    if spec.timer > 100 then
        spec.flashed = false

        if spec.flashLightNode ~= nil then
            --TODO: set flashlight visible = false
            setVisibility(spec.flashLightNode, false)
        end
    end
end

function PlaceableSpeedCamera:calculateCost(spec, speed)
    local cost = 0
    speed = speed - g_i18n.getSpeed(spec.speedLimit)

    if(speed > 20) then
        cost=(speed*4-40)*spec.costPerKMH
    else
        cost=(((-37625*math.pow(10,-10))*math.pow(speed,6))+((1609262*math.pow(10,-10))*math.pow(speed,5))+((-23444736*math.pow(10,-10))*math.pow(speed,4))+((144011223*math.pow(10,-10))*math.pow(speed,3))+((135190505*math.pow(10,-10))*math.pow(speed,2))+((4792206974*math.pow(10,-10))*speed)+(-5611455*math.pow(10,-10)))*spec.costPerKMH + 1;
    end

    return math.ceil(cost);
end

function PlaceableSpeedCamera:onSpeedCameraTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if onEnter or onLeave then
        local spec = self.spec_speedCamera
        local vehicle = g_currentMission:getNodeObject(otherId)

        if vehicle ~= nil and vehicle.spec_drivable ~= nil and vehicle.spec_enterable ~= nil then
            if onEnter then
                spec.count = spec.count + 1
                local vehicleSpeed = math.round(vehicle:getLastSpeed())

                if vehicleSpeed > g_i18n.getSpeed(spec.speedLimit) and spec.count == 1 then
                    spec.flashed = true
                    local money = g_i18n:getCurrency(self.calculateCost(spec, vehicleSpeed))
                    local notificationText = g_i18n:getText("SPEED_CAMERA_NOTIFICATION")
                    
                    if spec.flashLightNode ~= nil then
                        --TODO: set flashlight visible = true
                        setVisibility(spec.flashLightNode, true)
                    end

                    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, notificationText:format(-money, g_i18n:getCurrencySymbol(true)))
                    if g_currentMission:getIsServer() then
                        g_currentMission:addMoney(-money, vehicle:getActiveFarm(), MoneyType.OTHER)
                    else
                        g_client:getServerConnection():sendEvent(SC_PayFineEvent.new(-money, vehicle:getActiveFarm()))
                    end
                end
            end

            if onLeave then
                spec.count = spec.count - 1
            end
        end
    end
end