CreateConVar("ttt_sleeper_chance", 33)
CreateConVar("ttt_sleeper_warning", 0)
CreateConVar("ttt_sleeper_minplayers", 8)

local sleeper_active = false

local function ResetSleeper()
    --sleeper_active says whether or not there has been a sleeper already, it'll double to check whether there will be one at all in this round. Setting it to true will prevent one from being selected.
    sleeper_active = #player.GetAll() < GetConVar("ttt_sleeper_minplayers"):GetInt() or math.random(100) >= GetConVar("ttt_sleeper_chance"):GetInt()
end
hook.Add("TTTBeginRound", "ResetSleeper", ResetSleeper)

local function sleeper()
    local alive_t = {}
    for _, v in pairs(player.GetAll()) do
        if v:Alive() and v:IsTraitor() then table.insert(alive_t, v) end
    end
    
    if #alive_t == 0 and !sleeper_active then
        local target_pool = {}
        for _, ply in pairs(player.GetAll()) do
            if not ply:IsTraitor() and not ply:IsDetective() and ply:Alive() and not ply:IsSpec() then table.insert(target_pool, ply)    end
        end
        if #target_pool > 1 then 
            local ply = table.Random(target_pool)
            ply:SetRole(ROLE_TRAITOR)
            
            ply:ChatPrint("You're the Sleeper Traitor! Go finish the job!")
                       
            net.Start("TTT_Role")
            net.WriteUInt(ply:GetRole(), 2)
            net.Send(ply)
            
            -- Hitman support or something
            hook.Call("SleeperHitman", GAMEMODE, ply)
            if GetConVar("ttt_sleeper_warning"):GetBool() then
                for _, v in pairs( player.GetAll() ) do
                    if v != ply then
                        v:ChatPrint("The Sleeper Traitor has awoken!")
                    end
                end
            end
        end
        sleeper_active = true
    end
end

local function WinHook()
   --if ttt_dbgwin:GetBool() then return WIN_NONE end
   -- The Preventwin cvar wont work for now, will try n find a way to fix asap

   if GAMEMODE.MapWin == WIN_TRAITOR or GAMEMODE.MapWin == WIN_INNOCENT then
      local mw = GAMEMODE.MapWin
      GAMEMODE.MapWin = WIN_NONE
      return mw
   end

   local traitor_alive = false
   local innocent_alive = false
   for k,v in pairs(player.GetAll()) do
      if v:Alive() and v:IsTerror() then
         if v:GetTraitor() then
            traitor_alive = true
         else
            innocent_alive = true
         end
      end

      if traitor_alive and innocent_alive then
         return WIN_NONE --early out
      end
   end

   if traitor_alive and not innocent_alive then
      return WIN_TRAITOR
   elseif not traitor_alive and innocent_alive and sleeper_active then
      return WIN_INNOCENT
   elseif not innocent_alive then
      -- ultimately if no one is alive, traitors win
      return WIN_TRAITOR
   end

   return WIN_NONE
end
hook.Add("TTTCheckForWin", "WinHook", WinHook)

local function onPlayerDeath(vic, inf, att)
    sleeper()
end
hook.Add("PostPlayerDeath", "onPlayerDeath", onPlayerDeath)

local function onPlayerDisconnect(ply)
    sleeper()
end
hook.Add("PlayerDisconnected", "onPlayerDisconnect", onPlayerDisconnect)
