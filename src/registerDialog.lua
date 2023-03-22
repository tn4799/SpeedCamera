RegisterDialog = {}

RegisterDialog_mt = Class(RegisterDialog)

function RegisterDialog.new(custom_mt)
    local self = setmetatable({}, custom_mt or RegisterDialog_mt)

    return self
end

function RegisterDialog:loadMap()
    self:setupDialogs()
end

function RegisterDialog:setupDialogs()
    local dialog = PlacementDialog.new()
    g_gui:loadGui(Utils.getFilename("src/gui/PlacementDialog.xml", g_currentModDirectory), "PlacementDialog", dialog, false)
end

addModEventListener(g_challengeMod)