local autosearch = {}

local JSON = require("assets.JSON");
local protobuf = require("protobuf");

local Timers = {}; do
    local Queue = {};

    function Timers.ExecuteAfter(delay, func, ...)
        local Info = {
            Delay = delay,
            Func = func,
            Args = { ... }
        };

        Queue[#Queue + 1] = Info;
    end

    function Timers.Listener()
        local DeltaTime = GlobalVars.GetAbsFrameTime();

        for Index = #Queue, 1, -1 do
            local Info = Queue[Index];
            Info.Delay = Info.Delay - DeltaTime;

            if Info.Delay <= 0 then
                Info.Func(table.unpack(Info.Args));
                table.remove(Queue, Index);
            end
        end
    end
end

local function saveMessage(tbl)
    local file = io.open("scripts/modules/GCstartmsg.txt", "w")
    if not file then
        return
    end
    local encoded = JSON:encode(tbl) 
    file:write(encoded)
    file:close()
end

local function loadMessage()
    local file = io.open("scripts/modules/GCstartmsg.txt", "r")
    if not file then return nil end
    local data = file:read("*a")
    file:close()
    return JSON:decode(data)
end


function autosearch.gcmessace(startmsg)
    saveMessage(startmsg)                  

end
function autosearch.ui_init(maintab)
    local start_button, stop_button = nil, nil;
    local state = Config.ReadInt("autosearch", "search-state", 0)

    start_button = maintab:Button("Start Search", function()
        if autosearch.search_match() then 
            Config.WriteInt("autosearch", "search-state", 1);
            start_button:Disabled(true);
            stop_button:Disabled(false);
        else 
            maintab:Label("Pls start search first time manual")
        end
    end, false)

    stop_button = maintab:Button("Stop Search",  function()
        autosearch.stop_search()
        Config.WriteInt("autosearch", "search-state", 0);
        start_button:Disabled(false);
        stop_button:Disabled(true);

    end)

    stop_button:Disabled(true);
    if state ~= 0 then 
        start_button:Disabled(true);
        stop_button:Disabled(false);
    end
    
end
function autosearch.stop_search()
    local request = protobuf.encodeFromJSON('CMsgStopFindingMatch', JSON:encode({
        accept_cooldown = true 
    }))
    
    GC.SendMessage(request.binary, 7036, request.size)
end


function autosearch.search_match()

    if Players.GetLocal() ~= nil or Heroes.GetLocal() ~= nil then
        return
    end
    local asd = loadMessage()

    if asd then
        local enc_message = protobuf.encodeFromJSON('CMsgStartFindingMatch', JSON:encode(asd))
        GC.SendMessage( enc_message.binary, 7033, enc_message.size )
        return true
    end
end 

function autosearch.OnGameEnd()
    local state = Config.ReadInt("autosearch", "search-state", 0)
    if state == 0 then return end

    local map = Engine.GetLevelNameShort()
    --if not map == "dota" then return end -- test after demo
    Timers.ExecuteAfter(2, autosearch.search_match);
end
function autosearch.OnFrame()
    Timers.Listener()
end

return autosearch