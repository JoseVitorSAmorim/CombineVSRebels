-- init.lua
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

util.AddNetworkString("CVSR_AbrirMenu")
util.AddNetworkString("CVSR_ReceberEscolha")
util.AddNetworkString("CVSR_StartMapVote")
util.AddNetworkString("CVSR_SubmitMapVote")

cvsr_Spawns = cvsr_Spawns or { [TEAM_COMBINE] = {}, [TEAM_REBELS]  = {} }

local function GetSpawnFilePath() return "cvsr_spawns/" .. game.GetMap() .. ".json" end

function SaveSpawns()
    if not file.Exists("cvsr_spawns", "DATA") then file.CreateDir("cvsr_spawns") end
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
            if teamID and cvsr_Spawns[teamID] then cvsr_Spawns[teamID] = spawnList end
        end
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
    ply:SetTeam(TEAM_UNASSIGNED)
    timer.Simple(1.5, function() if IsValid(ply) then net.Start("CVSR_AbrirMenu") net.Send(ply) end end)
end

function GM:ShowTeam(ply)
    net.Start("CVSR_AbrirMenu")
    net.Send(ply)
end

-- Recebe a escolha do menu do cliente e aplica a REGRA DO RESPAWN
net.Receive("CVSR_ReceberEscolha", function(len, ply)
    local timeEscolhido = net.ReadInt(4)
    local classeEscolhida = net.ReadString()
    local armaPri = net.ReadString()
    local armaSec = net.ReadString()
    local armaGad = net.ReadString()

    if timeEscolhido == TEAM_COMBINE or timeEscolhido == TEAM_REBELS then
        -- Salva as escolhas na "fila de espera" do jogador
        ply.NextTeam = timeEscolhido
        ply.NextClasse = classeEscolhida
        ply.NextLoadout = { armaPri, armaSec, armaGad }
        
        -- Se estiver sem time ou estiver morto, spawna instantaneamente
        if ply:Team() == TEAM_UNASSIGNED or not ply:Alive() then
            ply:SetTeam(timeEscolhido)
            ply:Spawn()
            ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Você entrou de " .. CVSR_CLASSES[classeEscolhida].nome .. "!")
        else
            -- Se estiver vivo, avisa que vai mudar quando morrer
            ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Alterações salvas! Sua nova classe/arma será aplicada quando você renascer.")
        end
    end
end)

-- Processo de spawn
function GM:PlayerSpawn(ply)
    -- Aplica as mudanças da "Fila de espera" se houver
    if ply.NextTeam then ply:SetTeam(ply.NextTeam); ply.NextTeam = nil end

    local teamID = ply:Team()
    if teamID ~= TEAM_COMBINE and teamID ~= TEAM_REBELS then
        ply:Spectate(OBS_MODE_ROAMING)
        return
    else
        ply:UnSpectate()
    end

    self.BaseClass:PlayerSpawn(ply)
    ply:StripWeapons()
    ply:RemoveAllAmmo()

    if CVSR_TEAM_MODELS[teamID] then ply:SetModel(table.Random(CVSR_TEAM_MODELS[teamID])) end
    ply:SetupHands()

    -- Pega a classe/loadout da fila de espera, ou mantém a atual
    local classe = ply.NextClasse or ply.ClasseAtual
    local loadout = ply.NextLoadout or ply.LoadoutAtual

    if classe and CVSR_CLASSES[classe] and loadout then
        ply.ClasseAtual = classe
        ply.LoadoutAtual = loadout
        ply.NextClasse = nil
        ply.NextLoadout = nil

        for _, wepClass in ipairs(loadout) do
            if wepClass and wepClass ~= "" then
                local wep = ply:Give(wepClass)
                if IsValid(wep) and wep:GetPrimaryAmmoType() > 0 then
                    ply:GiveAmmo(150, wep:GetPrimaryAmmoType(), true)
                end
            end
        end
        ply:Give("weapon_crowbar")
        ply:Give("weapon_physcannon")
    else
        ply:Give("weapon_pistol")
    end

    if cvsr_Spawns[teamID] and #cvsr_Spawns[teamID] > 0 then
        local randomSpawn = table.Random(cvsr_Spawns[teamID])
        local p, a = randomSpawn.pos, randomSpawn.ang
        ply:SetPos(Vector(p.x, p.y, p.z))
        ply:SetEyeAngles(Angle(a.p, a.y, a.r))
    end
end

----------------------------------------------------
-- COMANDOS E VOTAÇÃO DE MAPA
----------------------------------------------------
function GM:PlayerSay(ply, text, teamonly)
    local msg = string.lower(string.Trim(text))
    if msg == "!rtv" or msg == "rtv" then TriggerRTV(ply); return "" end
    return self.BaseClass:PlayerSay(ply, text, teamonly) or text
end

concommand.Add("cvsr_addspawn", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local teamArg = string.lower(args[1] or "")
    local targetTeam = (teamArg == "combine" or teamArg == "1") and TEAM_COMBINE or ((teamArg == "rebel" or teamArg == "2") and TEAM_REBELS or nil)
    if not targetTeam then ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Uso: cvsr_addspawn combine OU cvsr_addspawn rebel"); return end

    local pos, ang = ply:GetPos(), ply:EyeAngles()
    table.insert(cvsr_Spawns[targetTeam], { pos = { x = pos.x, y = pos.y, z = pos.z }, ang = { p = ang.p, y = ang.y, r = ang.r } })
    SaveSpawns()
    ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Spawn adicionado com sucesso!")
end)

concommand.Add("cvsr_rtv", function(ply) TriggerRTV(ply) end)

local candidateMaps = { "gm_genesis", "gm_construct", "gm_flatgrass" }
local rtvVotes, isVoting, mapVotes = {}, false, {}

function TriggerRTV(ply)
    if isVoting then if IsValid(ply) then ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Votação em andamento!") end return end
    local id = IsValid(ply) and (ply:SteamID() ~= "" and ply:SteamID() or ply:EntIndex()) or "CONSOLE"
    if rtvVotes[id] then if IsValid(ply) then ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Você já votou.") end return end

    rtvVotes[id] = true
    local totalVoted, needed = table.Count(rtvVotes), math.ceil(#player.GetAll() * 0.5)
    PrintMessage(HUD_PRINTTALK, "[CVSR] Pedido de RTV recebido! (" .. totalVoted .. "/" .. needed .. ")")
    if totalVoted >= needed then StartMapVote() end
end

function StartMapVote()
    if isVoting then return end
    isVoting = true; mapVotes = {}
    for i = 1, #candidateMaps do mapVotes[i] = 0 end
    for _, p in ipairs(player.GetAll()) do p:Lock() end

    net.Start("CVSR_StartMapVote") net.WriteTable(candidateMaps) net.WriteFloat(CurTime() + 20) net.Broadcast()
    timer.Simple(20, function() FinishMapVote() end)
end

function FinishMapVote()
    local winningIndex, maxVotes = 1, -1
    for idx, count in pairs(mapVotes) do if count > maxVotes then maxVotes = count; winningIndex = idx end end
    local winningMap = candidateMaps[winningIndex] or "gm_genesis"
    PrintMessage(HUD_PRINTTALK, "[CVSR] Mapa vencedor: " .. winningMap .. "! Trocando...")
    timer.Simple(5, function() RunConsoleCommand("changelevel", winningMap) end)
end

net.Receive("CVSR_SubmitMapVote", function(len, ply)
    if not isVoting or ply.HasVotedMap then return end
    local mapIdx = net.ReadInt(8)
    if candidateMaps[mapIdx] then
        ply.HasVotedMap = true
        mapVotes[mapIdx] = (mapVotes[mapIdx] or 0) + 1
        ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Voto no mapa: " .. candidateMaps[mapIdx])
    end
end)

hook.Add("PlayerDeath", "CVSR_TrackTeamKills", function(victim, inflictor, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() ~= victim:Team() then
        team.AddScore(attacker:Team(), 1)
    end
end)