local ADDON_NAME, namespace = ...;

-- indexed upvals
set_cvar, get_cvar = C_CVar.SetCVar, C_CVar.GetCVar;

-- must provide either cvar or apply and print for non cvar based settings
local settings_keys = {
    ["dynamicPitch"] = {
        cvar = "test_cameraDynamicPitch",
        type = "int_bool",
        help_text = "Basic action camera pitch adjustments"
    },
    ["headBobStrength"] = {
        cvar = "test_cameraHeadMovementStrength",
        type = "number",
        min = 0,
        max = 2,
        defined_aliases = {
            none = 0,
            low = 0.5,
            normal = 1,
            full = 2
        },
        help_text = "The strength of the head bob effect"
    },
    ["overShoulder"] = {
        cvar = "test_cameraOverShoulder",
        type = "custom",
        defined_aliases = {
            left = -1,
            right = 1,
            off = 0
        },
        help_text = "Over the shoulder camera mode"
    },
    ["focusInteractTarget"] = {
        cvar = "test_cameraTargetFocusInteractEnable",
        type = "int_bool",
        help_text = "Should focus any interactable targets"
    },
    ["focusEnemyTarget"] = {
        cvar = "test_cameraTargetFocusEnemyEnable",
        type = "int_bool",
        help_text = "Should focus enemy targets"
    },
    ["blacklist"] = {
        apply = function(value)
            if args == 0 then
                namespace.apply_preset(action_cam_saved.settings);
                action_cam_saved.blacklisted_toons[UnitGUID("player")] = nil;
                namespace.write_line("Action Camera is now |cAA00FF00enabled|r on this character.");
                
            else
                namespace.apply_preset(namespace.presets.off);
                action_cam_saved.blacklisted_toons[UnitGUID("player")] = UnitName("player");
                namespace.write_line("Action Camera is now |cAAFF0000disabled|r on this character.");
            end
        end,
        print = namespace.is_blacklisted,
        type = "int_bool",
        help_text = "Should action camera be enabled for this character"
    },
    ["preset"] = {
        apply = function(value)
            namespace.apply_preset(value);

            action_cam_saved.settings = namespace.copy_preset(value);
        end,
        print = function()
            for k, v in pairs(namespace.presets) do
                if namespace.compare_presets(action_cam_saved.settings, v) then
                    return k;
                end
            end
            return "custom";
        end,
        type = "custom",
        defined_aliases = namespace.presets,
        help_text = "Override config with an Action Cam preset"
    }
} -- todo: add the more obscure configuration options if she wants them

function namespace.slash_handler(msg)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

    if cmd == nil or string.lower(cmd) == "help" then
        namespace.print_help();
        return;
    end

    if settings_keys[cmd] == nil then
        namespace.write_error(string.format("\"%s\" is not a valid option or command.", cmd));
        return;
    end

    -- no args passed so print values
    if args == "" then
        local current_value;

        if settings_keys[cmd].cvar ~= nil then
            current_value = get_cvar(settings_keys[cmd].cvar);
        else
            current_value = settings_keys[cmd].print();
        end

        if settings_keys[cmd].type == "int_bool" then
            if current_value == 1 then
                namespace.write_line(string.format("%s is |cAA00FF00enabled|r", cmd));
            else
                namespace.write_line(string.format("%s is |cAAFF0000disabled|r", cmd));
            end
        elseif settings_keys[cmd].type == "number" then
            if settings_keys[cmd].defined_aliases ~= nil then
                for k, v in pairs(settings_keys[cmd].defined_aliases) do
                    if v == tonumber(current_value) then
                        current_value = k;
                        break;
                    end
                end
            end
            namespace.write_line(string.format("%s is set to |cAA00FF00%s|r", cmd, current_value));
        elseif settings_keys[cmd].type == "custom" then
            for k, v in pairs(settings_keys[cmd].defined_aliases) do
                if v == tonumber(current_value) then
                    current_value = k;
                    break;
                end
            end
            namespace.write_line(string.format("%s is set to |cAA00FF00%s|r", cmd, current_value));
        end
        return;
    end
    
    namespace.apply_setting(cmd, args);
end

function namespace.apply_setting(setting, value)
    -- todo: probably should clean this up a bit, readability kind of sucks
    if settings_keys[setting].type == "int_bool" then
        if value == "true" or value == "on" or value == 1 then
            if settings_keys[setting].cvar == nil then
                settings_keys[setting].apply(1);
            else
                if namespace.apply_cvar(setting, settings_keys[setting].cvar, 1, value) then
                    action_cam_saved.settings[settings_keys[setting].cvar] = 1;
                end
            end
        elseif value == "false" or value == "off" or value == 0 then
            if settings_keys[setting].cvar == nil then
                settings_keys[setting].apply(0);
            else
                if namespace.apply_cvar(setting, settings_keys[setting].cvar, 0, value) then
                    action_cam_saved.settings[settings_keys[setting].cvar] = 0;
                end
            end
        end
    elseif settings_keys[setting].type == "number" then
        local min, max = settings_keys[setting].min, settings_keys[setting].max;
        local raw_value;
        if tonumber(value) ~= nil then
            raw_value = tonumber(value);
        else
            if settings_keys[setting].defined_aliases ~= nil and settings_keys[setting].defined_aliases[value] ~= nil then
                raw_value = tonumber(settings_keys[setting].defined_aliases[value]);
            else
                namespace.write_error("%s is not a valid option. Please use /help to see valid inputs.", value);
                return;
            end
        end

        if raw_value < min or raw_value > max then
            namespace.write_error("Number provided is out of the allowed range of %s-%s", min, max);
        elseif settings_keys[setting].defined_aliases ~= nil and settings_keys[setting].defined_aliases[value] ~= nil then
            if settings_keys[setting].cvar == nil then
                settings_keys[setting].apply(settings_keys[setting].defined_aliases[value]);
            else
                if namespace.apply_cvar(setting, settings_keys[setting].cvar, settings_keys[setting].defined_aliases[value], value) then
                    action_cam_saved.settings[settings_keys[setting].cvar] = settings_keys[setting].defined_aliases[value];
                end
            end
        else
            if settings_keys[setting].cvar == nil then
                settings_keys[setting].apply(value);
            else
                if namespace.apply_cvar(setting, settings_keys[setting].cvar, value) then
                    action_cam_saved.settings[settings_keys[setting].cvar] = value;
                end
            end
        end
    elseif settings_keys[setting].type == "custom" then
        if settings_keys[setting].defined_aliases[value] == nil then
            namespace.write_error("%s is not a valid option. Please use /help to see valid inputs.", value);
        else
            if settings_keys[setting].cvar == nil then
                settings_keys[setting].apply(settings_keys[setting].defined_aliases[value]);
            else
                if namespace.apply_cvar(setting, settings_keys[setting].cvar, settings_keys[setting].defined_aliases[value], value) then
                    action_cam_saved.settings[settings_keys[setting].cvar] = settings_keys[setting].defined_aliases[value];
                end
            end
        end
    end 
end

function namespace.apply_cvar(setting, cvar, value, named_value)
    if namespace.is_blacklisted() then
        namespace.write_line("%s has been set to |cAA00FF00%s|r for non blacklisted characters.", setting, named_value or value);
        -- also return true if blacklisted, false is to indicate an error
        return true;
    else
        if set_cvar(cvar, value) then
            namespace.write_line("%s has been successfully to |cAA00FF00%s|r", setting, named_value or value);
            return true;
        else
            named_value.cvar_failed(cvar, value);
            return false;
        end
    end
end

function namespace.apply_preset(preset)
    local succeeded = true;
    for k, v in pairs(preset) do
        if not set_cvar(k, v) then
            succeeded = false;
        end
    end
    if not succeeded then
        namespace.write_error("TEMP: couldn't apply preset");
    end
    return succeeded;
end

function namespace.copy_preset(preset)
    local return_table = {};

    for k, v in pairs(preset) do
        return_table[k] = v
    end
    return return_table;
end

-- print logic
local function get_indent_string(indents)
    return ("    "):rep(indents or 1);
end
function namespace.print_help()
    namespace.write_line("Action Cam Usage:\n");
    namespace.write_line("/actioncam <option> <input or preset> - Returns the current value of a setting")
    namespace.write_line("Options:");
    for k, v in pairs(settings_keys) do
        namespace.write_line(get_indent_string() .. string.format("\n%s - %s", k, v.help_text));

        if v.type == "int_bool" then
            namespace.write_line(get_indent_string(2) .. "Valid inputs: true/false or yes/no");
        elseif v.type == "number" then
            namespace.write_line(get_indent_string(2) .. string.format("Valid inputs: number between %s and %s", v.min, v.max));
            if v.defined_aliases ~= nil then
                local all_presets = "";
                for k, v in pairs(v.defined_aliases) do
                    if all_presets == "" then
                        all_presets = k;
                    else
                        all_presets = all_presets.. "/".. k;
                    end
                end 
                namespace.write_line(get_indent_string(2) .. string.format("Presets: %s", all_presets));
            end
        elseif v.type == "custom" then
            local all_presets = "";
            for k, v in pairs(v.defined_aliases) do 
                if all_presets == "" then
                    all_presets = k;
                else
                    all_presets = all_presets.. "/".. k;
                end
            end
            namespace.write_line(get_indent_string(2).. string.format("Presets: %s", all_presets));
        end
    end
end