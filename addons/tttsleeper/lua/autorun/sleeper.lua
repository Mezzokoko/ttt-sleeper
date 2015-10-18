CreateConVar("ttt_sleeper_chance", 33)
CreateConVar("ttt_sleeper_warning", 0)
CreateConVar("ttt_sleeper_minplayers", 8)

local sleeper_active = false

local function sleeper()
    local alive_t = {}
    for _, v in pairs(player.GetAll()) do
        if v:Alive() and v:IsTraitor() then table.insert(alive_t, v) end
    end

    if #alive_t == 0 and !sleeper_active then
        local target_pool = {}
        for _, ply in pairs(player.GetAll()) do
            if not ply:IsTraitor() and not ply:IsDetective() and ply:Alive() and not ply:IsSpec() then table.insert(target_pool, ply) end
        end
        if #target_pool > 1 then
            local ply = table.Random(target_pool)
            ply:SetRole(ROLE_TRAITOR)

            ply:ChatPrint("You're the Sleeper Traitor! Go finish the job!")

            net.Start("TTT_Role")
            net.WriteUInt(ply:GetRole(), 2)
            net.Send(ply)

            -- Hitman compatibility hook
            hook.Call("SleeperHitman", GAMEMODE, ply)

            if GetConVar("ttt_sleeper_warning"):GetBool() then --imo warning the players of the sleeper traitor defeats the point of it, which is why it is disabled by default
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
   if GetConVar("ttt_debug_preventwin"):GetBool() then return WIN_NONE end

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
hook.Add("PostPlayerDeath", "onPlayerDeath", function(vic,inf,atk) sleeper() end)
hook.Add("PlayerDisconnected", "onPlayerDisconnect", function(ply) sleeper() end)
hook.Add("TTTBeginRound", "ResetSleeper", function() sleeper_active = #player.GetAll() < GetConVar("ttt_sleeper_minplayers"):GetInt() or math.random(100) > GetConVar("ttt_sleeper_chance"):GetInt() end)
