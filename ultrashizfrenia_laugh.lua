local script = {}

-- Variables
local config_interval = 16.0 
local last_laugh_time = 0

-- Toggle reference
script.enable_laugh = nil

function script.OnInitialize()
    -- Create menu
    script.menu = Menu.Create("Miscellaneous", "In Game", "ULTRASHIZOFRENIA laugh")
    script.menu:Icon("\u{e1a7}") 
    
    script.menu_main = script.menu:Create("Main")
    script.menu_general = script.menu_main:Create("General")
    
    -- Only one toggle for laugh
    script.enable_laugh = script.menu_general:Switch("  Auto Laugh (/laugh)", true, "KD 16")
end

function script.OnUpdate()
    -- Exit if not in game or menu is not initialized yet
    if not Engine.IsInGame() or not script.enable_laugh then 
        return 
    end

    -- Exit if laugh is disabled in menu
    if not script.enable_laugh:Get() then
        return
    end

    local me = Heroes.GetLocal()
    if not me or not Entity.IsAlive(me) then return end

    local now = os.clock()

    -- Laugh logic
    if now > last_laugh_time + config_interval then
        Engine.ExecuteCommand("say /laugh")
        last_laugh_time = now
        print("[ULTRASHIZOFRENIA] Ha-ha! (Laugh sent)")
    end
end

-- Initialization
script.OnInitialize()

return script