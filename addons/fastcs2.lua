--[[
* FastCS port for Ashita v4.
* Original Windower plugin by Cairthenn.
* Ashita v4 Port by Spike2D.
]]--

addon.name = 'FastCS2'
addon.author = 'War3zlod3r (Original: Cairthenn)'
addon.version = '2.1.6'
addon.desc = 'Automatically disables the frame rate cap strictly during active cutscenes and transitional events.'
addon.link = 'https://ashitaxi.com/'

require('common')
local settings = require('settings')

-- Default configuration
local default_settings = {
    fps = 1, -- Default: 60 FPS (0 = uncapped, 1 = 60 FPS, 2 = 30 FPS)
    exclusions = {
        ['home point'] = true,
        ['survival guide'] = true,
        ['waypoint'] = true,
    }
}

addon.settings = default_settings
local is_speedup_active = false
local is_zoning = false

local help_text = [[FastCS - Command Menu:
/fastcs fps [30|60|uncapped] - Changes default FPS after exiting events.
/fastcs frameratedivisor [2|1|0] - Alternately changes your default frame divisor.
/fastcs exclusion [add|remove] "target name" - Toggles exclusion targets (case insensitive).]]

-- Helper function to push FPS updates down to Ashita
local function set_fps_divisor(divisor)
    local chat = AshitaCore:GetChatManager()
    if chat then
        chat:QueueCommand(-1, '/fps ' .. tostring(divisor))
    end
end

-- Lifecyle Callbacks
ashita.events.register('load', 'load_cb', function()
    addon.settings = settings.load(default_settings)
end)

ashita.events.register('unload', 'unload_cb', function()
    -- Ensure frame rate resets back to default setting if the addon is reloaded/unloaded
    if is_speedup_active then
        set_fps_divisor(addon.settings.fps)
    end
end)

-- Command Handler
ashita.events.register('command', 'command_cb', function(e)
    local args = e.command:args()
    if #args == 0 or args[1]:lower() ~= '/fastcs' then
        return false
    end
    
    e.blocked = true
    
    if #args < 2 or args[2]:lower() == 'help' then
        print(help_text)
        return true
    end
    
    local command = args[2]:lower()
    
    if command == 'fps' or command == 'frameratedivisor' then
        if #args < 3 then return true end
        local val = args[3]:lower()
        local div = 1
        
        if val == '30' or val == '2' then
            div = 2
        elseif val == '60' or val == '1' then
            div = 1
        elseif val == 'uncapped' or val == '0' then
            div = 0
        else
            return true
        end
        
        addon.settings.fps = div
        settings.save(addon.settings)
        print(('FastCS: Default FrameRateDivisor set to %d.'):format(div))
        
        if not is_speedup_active then
            set_fps_divisor(div)
        end
        
    elseif command == 'exclusion' then
        if #args < 4 then return true end
        local action = args[3]:lower()
        local name_table = {}
        
        for i = 4, #args do
            table.insert(name_table, args[i])
        end
        local name = string.lower(table.concat(name_table, ' '))
        
        if action == 'add' then
            addon.settings.exclusions[name] = true
            settings.save(addon.settings)
            print(('FastCS: Added "%s" to exclusions.'):format(name))
        elseif action == 'remove' then
            addon.settings.exclusions[name] = nil
            settings.save(addon.settings)
            print(('FastCS: Removed "%s" from exclusions.'):format(name))
        end
    end
    
    return true
end)

-- Packet Interceptor Loop
ashita.events.register('packet_in', 'packet_in_cb', function(e)
    -- 0x00A: Map Initialization / Landed in New Zone
    if e.id == 0x00A then
        is_speedup_active = true
        is_zoning = true
        set_fps_divisor(0) -- Force uncap immediately during the zone loading sequence
        return false
    end

    -- If we are actively zoning, look for character stability before processing anything else
    if is_zoning then
        local party = AshitaCore:GetMemoryManager():GetParty()
        if party and party:GetMemberName(0) ~= nil then
            is_zoning = false
            is_speedup_active = false
            set_fps_divisor(addon.settings.fps)
        end
        -- Block further evaluation of this packet while the loading lock is active
        if is_zoning then return false end
    end
        
    -- 0x032 / 0x034: Cutscene/Event Initialization Packets
    if e.id == 0x032 or e.id == 0x034 then
        if not is_speedup_active then
            local is_excluded = false
            pcall(function()
                local memMgr = AshitaCore:GetMemoryManager()
                if memMgr then
                    local target = memMgr:GetTarget()
                    if target and target.ActiveTargetIndex ~= 0 then
                        local target_name = string.lower(target.Name or '')
                        if addon.settings.exclusions[target_name] then
                            is_excluded = true
                        end
                    end
                end
            end)
            
            if not is_excluded then
                is_speedup_active = true
                set_fps_divisor(0)
            end
        end
        
    -- 0x037: User Update Packet (Fires heavily during map/cutscene transitions)
    elseif e.id == 0x037 then
        local status_mask = struct.unpack('B', e.data, 0x30 + 1)
        
        -- Normal NPC dialogue loop / Action processing outside of zone lines
        -- 0 = Idle/Normal, 2 = Mounted (Chocobo fallback)
        if is_speedup_active and (status_mask == 0 or status_mask == 2) then
            is_speedup_active = false
            set_fps_divisor(addon.settings.fps)
        end
        
    -- 0x052: Explicit Event Finish packet (Dialogue closed or transport cuts finish)
    elseif e.id == 0x052 then
        is_zoning = false
        if is_speedup_active then
            is_speedup_active = false
            set_fps_divisor(addon.settings.fps)
        end
    end
    
    return false
end)
