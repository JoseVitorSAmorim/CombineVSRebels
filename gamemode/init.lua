AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

util.AddNetworkString("CVSR_OpenClassMenu")
util.AddNetworkString("CVSR_SelectLoadout")
util.AddNetworkString("CVSR_StartMapVote")
util.AddNetworkString("CVSR_SubmitMapVote")

cvsr_Spawns = cvsr_Spawns or {
    [TEAM_COMBINE] = {},
    [TEAM_REBELS]  = {}
}

local function GetSpawnFilePath()
    return "cvsr_spawns/" .. game.GetMap() .. ".json"
end

function SaveSpawns()
    if not file.Exists("cvsr_spawns", "DATA") then
        file.CreateDir("cvsr_spawns")
    end
    file.Write(GetSpawnFilePath(), util.TableToJSON(cvsr_Spawns, true))
    print("[CVSR] Spawns salvos em: " .. GetSpawnFilePath())
end

function LoadSpawns()
    local path = GetSpawnFilePath()
    if file.Exists(path, "DATA") then
        local rawTable = util.JSONToTable(file.Read(path, "DATA")) or {}
        cvsr_Spawns = { [TEAM_COMBINE] = {}, [TEAM_REBELS] = {} }
        for teamIDStr, spawnList in pairs(rawTable) do
            local teamID = tonumber(teamIDStr)
            if teamID and cvsr_Spawns[teamID] then
                cvsr_Spawns[teamID] = spawnList
            end
        end
        print("[CVSR] Spawns carregados para " .. game.GetMap())
    end
end

function StartMatchTimer()
    team.SetScore(TEAM_COMBINE, 0)
    team.SetScore(TEAM_REBELS, 0)
    SetGlobalFloat("CVSR_MatchEndTime", CurTime() + 600)
    timer.Create("CVSR_MatchEndTimer", 600, 1, function() StartMapVote() end)
end

hook.Add("InitPostEntity", "CVSR_LoadSpawnsOnInit", function()
    LoadSpawns()
    StartMatchTimer()
end)

function GM:PlayerInitialSpawn(ply)
    ply:SetTeam(math.random(TEAM_COMBINE, TEAM_REBELS))
end

function GM:ShowTeam(ply)
    net.Start("CVSR_OpenClassMenu")
    net.Send(ply)
end

function GM:PlayerSay(ply, text, teamonly)
    local msg = string.lower(string.Trim(text))
    if msg == "!rtv" or msg == "rtv" then
        TriggerRTV(ply)
        return ""
    end
    return self.BaseClass:PlayerSay(ply, text, teamonly) or text
end

concommand.Add("cvsr_rtv", function(ply) TriggerRTV(ply) end)

-- Comando para criar pontos de spawn para as equipes
concommand.Add("cvsr_addspawn", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local teamArg = string.lower(args[1] or "")
    local targetTeam = (teamArg == "combine" or teamArg == "1") and TEAM_COMBINE or ((teamArg == "rebel" or teamArg == "2") and TEAM_REBELS or nil)
    
    if not targetTeam then
        ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Uso: cvsr_addspawn combine OU cvsr_addspawn rebel")
        return
    end

    local pos, ang = ply:GetPos(), ply:EyeAngles()
    table.insert(cvsr_Spawns[targetTeam], { pos = { x = pos.x, y = pos.y, z = pos.z }, ang = { p = ang.p, y = ang.y, r = ang.r } })
    SaveSpawns()
    ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Spawn adicionado com sucesso!")
end)

net.Receive("CVSR_SelectLoadout", function(len, ply)
    ply.SelectedLoadout = {
        primary   = net.ReadString(),
        secondary = net.ReadString(),
        gadget    = net.ReadString(),
        model     = net.ReadString()
    }
    ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Loadout salvo! Aplicando na sua próxima vida.")
end)

function GM:PlayerSpawn(ply)
    self.BaseClass:PlayerSpawn(ply)

    local teamID = ply:Team()
    if teamID ~= TEAM_COMBINE and teamID ~= TEAM_REBELS then
        teamID = TEAM_COMBINE
        ply:SetTeam(teamID)
    end

    ply:StripWeapons()
    ply:RemoveAllAmmo()

    if not CVSR_Loadouts or not CVSR_Loadouts[teamID] then
        print("[CVSR ERROR] CVSR_Loadouts não foi encontrado para o time: " .. tostring(teamID))
        ply:Give("weapon_pistol")
        return
    end

    local defaultLoadout = CVSR_Loadouts[teamID]
    local loadout = ply.SelectedLoadout or {
        primary   = defaultLoadout.primaries[1].class,
        secondary = defaultLoadout.secondaries[1].class,
        gadget    = defaultLoadout.gadgets[1].class,
        model     = defaultLoadout.models[1]
    }

    ply:SetModel(loadout.model)
    local weaponsToGive = { loadout.primary, loadout.secondary, loadout.gadget, "weapon_physcannon" }
    for _, wepClass in ipairs(weaponsToGive) do
        if wepClass and wepClass ~= "" then
            local wep = ply:Give(wepClass)
            if IsValid(wep) and wep:GetPrimaryAmmoType() > 0 then
                ply:GiveAmmo(150, wep:GetPrimaryAmmoType(), true)
            end
        end
    end

    ply:SetupHands()

    if cvsr_Spawns[teamID] and #cvsr_Spawns[teamID] > 0 then
        local randomSpawn = table.Random(cvsr_Spawns[teamID])
        local p, a = randomSpawn.pos, randomSpawn.ang
        ply:SetPos(Vector(p.x, p.y, p.z))
        ply:SetEyeAngles(Angle(a.p, a.y, a.r))
    end
end

----------------------------------------------------
-- RTV E VOTAÇÃO DE MAPA
----------------------------------------------------
local candidateMaps = { "gm_genesis", "gm_construct", "gm_flatgrass" }
local rtvVotes = {}
local isVoting = false
local mapVotes = {}

function TriggerRTV(ply)
    if isVoting then
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Votação já em andamento!") end
        return
    end

    local id = IsValid(ply) and (ply:SteamID() ~= "" and ply:SteamID() or ply:EntIndex()) or "CONSOLE"
    if rtvVotes[id] then
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Você já pediu RTV.") end
        return
    end

    rtvVotes[id] = true
    local totalVoted = table.Count(rtvVotes)
    local needed = math.ceil(#player.GetAll() * 0.5)

    PrintMessage(HUD_PRINTTALK, "[CVSR] Pedido de RTV recebido! (" .. totalVoted .. "/" .. needed .. ")")

    if totalVoted >= needed then
        StartMapVote()
    end
end

function StartMapVote()
    if isVoting then return end
    isVoting = true
    mapVotes = {}
    for i = 1, #candidateMaps do mapVotes[i] = 0 end

    for _, p in ipairs(player.GetAll()) do p:Lock() end

    net.Start("CVSR_StartMapVote")
        net.WriteTable(candidateMaps)
        net.WriteFloat(CurTime() + 20)
    net.Broadcast()

    timer.Simple(20, function() FinishMapVote() end)
end

function FinishMapVote()
    local winningIndex, maxVotes = 1, -1
    for idx, count in pairs(mapVotes) do
        if count > maxVotes then maxVotes = count; winningIndex = idx end
    end
    local winningMap = candidateMaps[winningIndex] or "gm_genesis"
    PrintMessage(HUD_PRINTTALK, "[CVSR] Mapa vencedor: " .. winningMap .. "! Trocando em 5 segundos...")
    timer.Simple(5, function() RunConsoleCommand("changelevel", winningMap) end)
end

net.Receive("CVSR_SubmitMapVote", function(len, ply)
    if not isVoting or ply.HasVotedMap then return end
    local mapIdx = net.ReadInt(8)
    if candidateMaps[mapIdx] then
        ply.HasVotedMap = true
        mapVotes[mapIdx] = (mapVotes[mapIdx] or 0) + 1
        ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Voto confirmado no mapa: " .. candidateMaps[mapIdx])
    end
end)

hook.Add("PlayerDeath", "CVSR_TrackTeamKills", function(victim, inflictor, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() ~= victim:Team() then
        team.AddScore(attacker:Team(), 1)
    end
end)