local ADDON_NAME, namespace = ...;

local event_frame, events = CreateFrame("Frame"), {};
event_frame:Hide();

namespace.presets = {
    off = {
        ["test_cameraDynamicPitch"] = 0,
        ["test_cameraOverShoulder"] = 0,
        ["test_cameraTargetFocusEnemyEnable"] = 0,
        ["test_cameraTargetFocusInteractEnable"] = 0,
        ["test_cameraHeadMovementStrength"] = 0,
    },
    basic = {
        ["test_cameraDynamicPitch"] = 1,
        ["test_cameraOverShoulder"] = 0,
        ["test_cameraTargetFocusEnemyEnable"] = 0,
        ["test_cameraTargetFocusInteractEnable"] = 0,
        ["test_cameraHeadMovementStrength"] = 0,
    },
    on = {
        ["test_cameraDynamicPitch"] = 1,
        ["test_cameraOverShoulder"] = 1,
        ["test_cameraTargetFocusEnemyEnable"] = 1,
        ["test_cameraTargetFocusInteractEnable"] = 0,
        ["test_cameraHeadMovementStrength"] = 1,
    },
    full = {
        ["test_cameraDynamicPitch"] = 1,
        ["test_cameraOverShoulder"] = 1,
        ["test_cameraTargetFocusEnemyEnable"] = 1,
        ["test_cameraTargetFocusInteractEnable"] = 1,
        ["test_cameraHeadMovementStrength"] = 1,
    },
}

-- Event callbacks
function events:ADDON_LOADED(addon)
    if addon ~= ADDON_NAME then
        return;
    else
        event_frame:UnregisterEvent("ADDON_LOADED");
    end

    -- register slash
    SLASH_ACTIONCAM1 = "/actioncam";
    SLASH_ACTIONCAM2 = "/ac";
    SlashCmdList["ACTIONCAM"] = namespace.slash_handler

    -- disable silly experimental camera features
    UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED");

    local reset = false;
    if type(action_cam_saved) ~= "table" then
        action_cam_saved = {
            settings = namespace.copy_preset(namespace.presets.off),
            blacklisted_toons = {}
        }
        namespace.write_line("Action Cam is installed and enabled! To get started apply a preset using /ac preset <preset name>. For a list of presets and configurable options type /ac");
    elseif type(action_cam_saved.settings)  ~= "table" then
        namespace.write_error("Your settings were reset due to corrupt or missing saved data! Please reconfigure your action cam settings.");
        action_cam_saved = {
            settings = namespace.copy_preset(namespace.presets.off);
            blacklisted_toons = {}
        }
    end
end
function events:PLAYER_LOGIN(...)
    if namespace.is_blacklisted() then
        return;
    end

    -- todo: give useful error message 
    if namespace.apply_preset(action_cam_saved.settings) then

    end
end

-- Event handler
event_frame:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...);
end)
for k, v in pairs(events) do
    event_frame:RegisterEvent(k);
end

-- utils
function namespace.debug_error(msg, ...)
    error("Action Cam: ".. msg:format(...));
    namespace.write_error(msg:format(...));
    
end
function namespace.write_error(msg, ...)
    local info = ChatTypeInfo["RESTRICTED"];
    DEFAULT_CHAT_FRAME:AddMessage("Action Cam: ".. msg:format(...), info.r, info.g, info.b, info.id);
end
function namespace.cvar_failed(cvar, value)
    namespace.debug_error("Failed to modify the internal cvar %s! If this occured after a major patch then blizzard may have tweaked"..
        "the action camera configuration variables and you'll likely have to wait for an addon update before this addon works again. Otherwise it could"..
        "be a sign of game client corruption. Please report the following values to Minty: CVar: %s Value: %s", cvar, cvar, value);
end
function namespace.write_line(msg, ...)
    local info = ChatTypeInfo["SYSTEM"];
    DEFAULT_CHAT_FRAME:AddMessage(msg:format(...), info.r, info.g, info.b, info.id);
end
function namespace.is_blacklisted()
    if action_cam_saved.blacklisted_toons[UnitGUID("player")] == nil then
        return false;
    else
        return true;
    end
end
function namespace.compare_presets(preset1, preset2)
    local is_same = true;
    for k, v in pairs(preset1) do
        if preset2[k] ~= v then
            is_same = false;
            break;
        end
    end
    return is_same;
end