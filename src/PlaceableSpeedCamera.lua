PlaceableSpeedCamera = {
    prerequisitesPresent = function(specializations)
        return true
    end,
    TRANSACTION_FEE = 0.9
}

function PlaceableSpeedCamera.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onSpeedCameraTriggerCallback",
        PlaceableSpeedCamera.onSpeedCameraTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "calculateCost", PlaceableSpeedCamera.calculateCost)
    SpecializationUtil.registerFunction(placeableType, "round", PlaceableSpeedCamera.round)
end

function PlaceableSpeedCamera.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSpeedCamera)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSpeedCamera)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableSpeedCamera)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSpeedCamera)
end

function PlaceableSpeedCamera.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("speedCamera")
    basePath = basePath .. ".speedCamera"
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#flashLightNode")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerMarkersNode")
    schema:setXMLSpecializationType()
end

function PlaceableSpeedCamera:onLoad(savegame)
    local spec = self["spec_FS22_SpeedCamera.placeableSpeedCamera"]
    local key = "placeable.speedCamera"
    spec.trigger = self.xmlFile:getValue(key .. "#triggerNode", nil, self.components, self.i3dMappings)

    if spec.trigger == nil then
        Logging.xmlError(self.xmlFile, "Missing vehicle triggerNode for speed camera")

        return
    end

    addTrigger(spec.trigger, "onSpeedCameraTriggerCallback", self)

    spec.flashLight = self.xmlFile:getValue(key .. "#flashLightNode", nil, self.components, self.i3dMappings)
    spec.triggerMarkers = self.xmlFile:getValue(key .. "#triggerMarkersNode", nil, self.components, self.i3dMappings)
    spec.speedLimit = self.xmlFile:getInt(key .. ".speedLimit", 50)
    -- free limit
    spec.speedLimit = spec.speedLimit + math.min(5, spec.speedLimit * 0.1)
    spec.costPerKMH = self.xmlFile:getInt(key .. ".costPerKMH", 50)
    spec.ownerGetsMoney = self.xmlFile:getBool(key .. ".ownerGetsMoney", false)
    spec.showBlinkingWarning = self.xmlFile:getBool(key .. "#showBlinkingWarning", false)
    spec.count = 0
    spec.timer = 0
    spec.flashed = false

    if spec.flashLight ~= nil then
        setVisibility(spec.flashLight, false)
    end

    if spec.triggerMarkers ~= nil then
        setVisibility(spec.triggerMarkers, true)
    end
end

function PlaceableSpeedCamera:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self["spec_FS22_SpeedCamera.placeableSpeedCamera"]
    local keyParts = string.split(key, ".")
    key = keyParts[1] .. "." .. keyParts[2] .. "." .. keyParts[4]

    xmlFile:setInt(key .. ".speedLimit", spec.speedLimit)
    xmlFile:setInt(key .. ".costPerKMH", spec.costPerKMH)
    xmlFile:setBool(key .. ".ownerGetsMoney", spec.ownerGetsMoney)
end

function PlaceableSpeedCamera:loadFromXMLFile(xmlFile, key)
    local spec = self["spec_FS22_SpeedCamera.placeableSpeedCamera"]
    local keyParts = string.split(key, ".")
    key = keyParts[1] .. "." .. keyParts[2] .. "." .. keyParts[4]

    spec.speedLimit = xmlFile:getInt(key .. ".speedLimit") or spec.speedLimit
    spec.costPerKMH = xmlFile:getInt(key .. ".costPerKMH") or spec.costPerKMH
    spec.ownerGetsMoney = xmlFile:getBool(key .. ".ownerGetsMoney") or spec.ownerGetsMoney
end

function PlaceableSpeedCamera:onDelete()
    local spec = self["spec_FS22_SpeedCamera.placeableSpeedCamera"]

    if spec.trigger ~= nil then
        removeTrigger(spec.trigger)

        spec.trigger = nil
    end
end

function PlaceableSpeedCamera:onFinalizePlacement()
    local spec = self["spec_FS22_SpeedCamera.placeableSpeedCamera"]

    if spec.triggerMarkers ~= nil then
        setVisibility(spec.triggerMarkers, false)
    end

    if spec.flashLight ~= nil then
        setVisibility(spec.flashLight, false)
    end
end

function PlaceableSpeedCamera:onUpdate(dt)
    local spec = self["spec_FS22_SpeedCamera.placeableSpeedCamera"]

    if spec.flashed then
        spec.timer = spec.timer + dt
        self:raiseActive()
    end

    if spec.timer >= 125 then
        spec.flashed = false
        spec.timer = 0

        if spec.flashLight ~= nil then
            setVisibility(spec.flashLight, false)
        end
    end
end

function PlaceableSpeedCamera:calculateCost(spec, speed)
    local cost = 0
    speed = speed - g_i18n:getSpeed(spec.speedLimit)

    if (speed > 20) then
        cost = (speed * 4 - 40) * spec.costPerKMH
    else
        cost = (
            ((-37625 * math.pow(10, -10)) * math.pow(speed, 6)) + ((1609262 * math.pow(10, -10)) * math.pow(speed, 5)) +
                ((-23444736 * math.pow(10, -10)) * math.pow(speed, 4)) + ((144011223 * math.pow(10, -10)) *
                    math.pow(speed, 3)) + ((135190505 * math.pow(10, -10)) * math.pow(speed, 2)) +
                ((4792206974 * math.pow(10, -10)) * speed) + (-5611455 * math.pow(10, -10))) * spec.costPerKMH + 1
    end

    return math.ceil(cost)
end

function PlaceableSpeedCamera:round(number)
    local decimal = math.abs(number - math.floor(number))

    if decimal >= 0.5 then
        return math.ceil(number)
    else
        return math.floor(number)
    end
end

function PlaceableSpeedCamera:onSpeedCameraTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if onEnter or onLeave then
        local spec = self["spec_FS22_SpeedCamera.placeableSpeedCamera"]
        local vehicle = g_currentMission:getNodeObject(otherId)

        if vehicle ~= nil and vehicle.spec_drivable ~= nil and vehicle.spec_enterable ~= nil then
            if onEnter then
                spec.count = spec.count + 1
                local vehicleSpeed = self:round(vehicle:getLastSpeed())

                if vehicleSpeed > g_i18n:getSpeed(spec.speedLimit) and spec.count == 1 then
                    spec.flashed = true
                    local money = g_i18n:getCurrency(self:calculateCost(spec, vehicleSpeed))
                    local notificationText = g_i18n:getText("Notification_speedCamera")

                    if spec.flashLight ~= nil then
                        setVisibility(spec.flashLight, true)
                        self:raiseActive()
                    end

                    if spec.showBlinkingWarning and g_i18n:hasText("warning_speedCamera") ~= nil then
                        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_speedCamera"):format(vehicleSpeed -
                            g_i18n:getSpeed(spec.speedLimit)))
                    end

                    if g_currentMission:getIsServer() then
                        g_currentMission:addMoney(-money, vehicle:getActiveFarm(), MoneyType.OTHER)
                        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
                            notificationText:format(-money, g_i18n:getCurrencySymbol(true)))

                        if spec.ownerGetsMoney then
                            g_currentMission:addMoney(money * PlaceableSpeedCamera.TRANSACTION_FEE, self.ownerFarmId,
                                MoneyType.OTHER, true, true)
                        end
                    else
                        g_client:getServerConnection():sendEvent(SC_PayFineEvent.new(-money, vehicle:getActiveFarm()))

                        if spec.ownerGetsMoney then
                            g_client:getServerConnection():sendEvent(SC_PayFineEvent.new(money *
                                PlaceableSpeedCamera.TRANSACTION_FEE, vehicle:getActiveFarm()))
                        end
                    end
                end
            end

            if onLeave then
                spec.count = spec.count - 1
            end
        end
    end
end
