PlacementDialog = {}

PlacementDialog_mt = Class(PlacementDialog, YesNoDialog)

PlacementDialog.CONTROLS = {
    DIALOG = "dialog",
    DIALOG_TITLE = "dialogTitle",
    SPEED_LIMIT_INPUT = "speedLimitInput",
    CHECKBOXES_BOX = "checkboxesBox",
    CHECKBOXES_ROW = "checkboxesRow",
    OWNER_GETS_MONEY_CHECKBOX = "ownerGetsMoneyCheckbox",
    NO_BUTTON = "noButton",
    SAVE_BUTTON = "saveButton"
}

PlacementDialog.translations = {
    errors = {
        invalidSpeedLimit = g_i18n:getText("dialog_error_invalidSpeedLimit"),
        notANumber = g_i18n:getText("dialog_error_notANumber")
    }
}

local function NO_CALLBACK() end

function PlacementDialog.new(target, custom_mt)
    local self = YesNoDialog.new(target, custom_mt or PlacementDialog_mt)

    self:registerControls(PlacementDialog.CONTROLS)

    self.onTextEntered = NO_CALLBACK
    self.extraInputDisableTime = 0

    return self
end

function PlacementDialog:onOpen()
    PlacementDialog:superClass().onOpen(self)

    self.extraInputDisableTime = 100
    self.speedLimitInput.blockTime = 0
    self:focusSpeedLimitInput()
    self:updateButtonVisibility()
end

function PlacementDialog:onClose()
    PlacementDialog:superClass().onClose(self)

    self.speedLimitInput:setForcePressed(false)

    self:updateButtonVisibility()
end

function PlacementDialog:setCallback(onTextEntered, target, callbackArgs, defaultSpeedLimitText, defaultOwnerGetsMoney, dialogPrompt)
    self.onTextEntered = onTextEntered or NO_CALLBACK
    self.target = target
    self.callbackArgs = callbackArgs

    self.speedLimitInput:setText(defaultSpeedLimitText or "50")
    self.ownerGetsMoneyCheckbox:setIsChecked(defaultOwnerGetsMoney or false)

    if dialogPrompt ~= nil then
        self.dialogTextElement:setText(dialogPrompt)
    end
end

function PlacementDialog:sendCallback(clickOk)
    local speedLimit = tonumber(self.speedLimitInput:getText())
    local ownerGetsMoney = self.ownerGetsMoneyCheckbox.isChecked

    if clickOk then
        local function enterSpeedLimit(self)
            self:focusSpeedLimitInput()
            self.speedLimitInput:setForcePressed(true)
        end
        if speedLimit <= 0 then
            g_gui:showInfoDialog({
                text = PlacementDialog.translations.errors.invalidSpeedLimit,
                dialogType = DialogElement.TYPE_WARNING,
                target = self,
                callback = enterSpeedLimit
            })
            return
        elseif speedLimit == nil then
            g_gui:showInfoDialog({
                text = PlacementDialog.translations.errors.notANumber,
                dialogType = DialogElement.TYPE_WARNING,
                target = self,
                callback = enterSpeedLimit
            })
            return
        end
    end

    self:close()

    if self.target ~= nil then
        self.onTextEntered(self.target, speedLimit, ownerGetsMoney, clickOk, self.callbackArgs)
    end
end

function PlacementDialog:isInputDisabled()
    return self.extraInputDisableTime > 0
end

function PlacementDialog:updateButtonVisibility()
    local showButtons = not self.speedLimitInput.imeActive

    if self.saveButton ~= nil then
        self.saveButton:setVisibility(showButtons)
    end

    if self.noButton ~= nil then
        self.noButton:setVisibility(showButtons)
    end
end

function PlacementDialog:update(dt)
    PlacementDialog:superClass().update(self, dt)

    if self.extraInputDisableTime > 0 then
        self.extraInputDisableTime = self.extraInputDisableTime - dt
    end
end

function PlacementDialog:onSpeedLimitEnterPressed()
    --self:focusOwnerGetsMoneyCheckbox()
    --TODO: transfer focus on checkbox of ownerGetsMoney
end

function PlacementDialog:onEscPressed()
    return self:onClickBack()
end

function PlacementDialog:onClickSave()
    if not self:isInputDisabled() then
        self:sendCallback(true)

        return false
    else
        return true
    end
end

function PlacementDialog:onClickBack()
    if not self:isInputDisabled() then
        self:sendCallback(false)

        return false
    else
        return true
    end
end

function PlacementDialog:focusSpeedLimitInput()
    FocusManager:setFocus(self.speedLimitInput)
    self.speedLimitInput:onFocusActivate()
end