RegisterDialog = {
    BASE_DIRECTORY = g_currentModDirectory,
}

RegisterDialog_mt = Class(RegisterDialog)

function RegisterDialog.new(custom_mt)
    local self = setmetatable({}, custom_mt or RegisterDialog_mt)

    return self
end

function RegisterDialog:loadMap()
    g_gui:loadProfiles(Utils.getFilename("src/gui/guiProfiles.xml", RegisterDialog.BASE_DIRECTORY))
    self:setupDialogs()
end

function RegisterDialog:setupDialogs()
    local dialog = PlacementDialog.new()
    local filename = Utils.getFilename("src/gui/PlacementDialog.xml", RegisterDialog.BASE_DIRECTORY)
    g_gui:loadGui(filename, "PlacementDialog", dialog, false)
end

addModEventListener(RegisterDialog.new())