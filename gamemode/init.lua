-- init.lua
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

util.AddNetworkString("CVSR_AbrirMenu")
util.AddNetworkString("CVSR_ReceberEscolha")
util.AddNetworkString("CVSR_StartMapVote")
util.AddNetworkString("CVSR_SubmitMapVote")
util.AddNetworkString("CVSR_MatchEnd")

-- REGISTRO DE ENTIDADES DO HAMMER
local dummy_spawn = {
    Type = "point",
    Base = "base_point"
}
scripted_ents.Register(dummy_spawn, "info_spawn_combine")
scripted_ents.Register(dummy_spawn, "info_spawn_rebel")

cvsr_Spawns = cvsr_Spawns or { [TEAM_COMBINE] = {}, [TEAM_REBELS] = {} }

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

SetGlobalString("CVSR_GameState", "WAITING")

function StartMatchTimer()
    team.SetScore(TEAM_COMBINE, 0)
    team.SetScore(TEAM_REBELS, 0)
    
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_COMBINE or ply:Team() == TEAM_REBELS then
            ply:Spawn()
        end
    end
    
    local tempoDePartida = 300 -- 300 segundos = 5 minutos para ambos (HUD e Servidor)
    
    SetGlobalFloat("CVSR_MatchEndTime", CurTime() + tempoDePartida) 
    timer.Create("CVSR_MatchEndTimer", tempoDePartida, 1, function() EndMatch() end)
end

function EndMatch()
    -- Evita que a função rode duas vezes (ex: se o tempo acabar exato no momento de um kill 100)
    if GetGlobalString("CVSR_GameState") == "ENDED" then return end 
    SetGlobalString("CVSR_GameState", "ENDED")

    -- Se a partida acabou por pontos, destrói o timer para ele não disparar de novo atoa
    if timer.Exists("CVSR_MatchEndTimer") then 
        timer.Remove("CVSR_MatchEndTimer") 
    end

    local scoreC = team.GetScore(TEAM_COMBINE)
    local scoreR = team.GetScore(TEAM_REBELS)
    local winner = 0 -- 0 será o código para Empate

    if scoreC > scoreR then
        winner = TEAM_COMBINE
    elseif scoreR > scoreC then
        winner = TEAM_REBELS
    end

    -- Avisa todos os clientes quem ganhou
    net.Start("CVSR_MatchEnd")
    net.WriteInt(winner, 4)
    net.Broadcast()

    -- Trava os jogadores e deixa eles imortais enquanto mostramos o placar
    for _, ply in ipairs(player.GetAll()) do
        ply:Lock()
        ply:GodEnable() 
    end

    -- Espera 10 segundos com a tela de vitória e então inicia a votação do mapa
    timer.Simple(10, function() StartMapVote() end)
end

-- ====================================================
-- COMANDO PARA DEBUG (Use quando estiver testando sozinho)
-- Digite "cvsr_forcestart" no console para ignorar a falta de jogadores
-- ====================================================
concommand.Add("cvsr_forcestart", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    SetGlobalString("CVSR_GameState", "PLAYING")
    StartMatchTimer()
    PrintMessage(HUD_PRINTCENTER, "PARTIDA FORÇADA A COMEÇAR!")
end)

function CheckMatchStart()
    -- Checa se o jogo está aguardando jogadores
    if GetGlobalString("CVSR_GameState", "WAITING") == "WAITING" then
        -- Inicia a partida se houver pelo menos 1 jogador de cada lado
        if team.NumPlayers(TEAM_COMBINE) >= 1 and team.NumPlayers(TEAM_REBELS) >= 1 then
            SetGlobalString("CVSR_GameState", "PLAYING")
            StartMatchTimer()
            PrintMessage(HUD_PRINTCENTER, "A PARTIDA COMEÇOU!")
        end
    end
end

hook.Add("InitPostEntity", "CVSR_LoadSpawnsOnInit", function()
    LoadSpawns()
    -- O timer agora só inicia através do CheckMatchStart()
end)

-- ====================================================
-- CONTROLE DE CONEXÃO E MENU
-- ====================================================
function GM:PlayerInitialSpawn(ply)
    ply:SetTeam(TEAM_UNASSIGNED)
    ply:Spectate(OBS_MODE_ROAMING)
    ply:SetNoDraw(true)
    
    timer.Simple(1.5, function() 
        if IsValid(ply) then 
            net.Start("CVSR_AbrirMenu") 
            net.Send(ply) 
        end 
    end)
end

function GM:ShowTeam(ply)
    net.Start("CVSR_AbrirMenu")
    net.Send(ply)
end

-- ====================================================
-- SISTEMA DE FILA DE CLASSE (TROCA E MATCHMAKING)
-- ====================================================
net.Receive("CVSR_ReceberEscolha", function(len, ply)
    local time = net.ReadInt(4)
    local classe = net.ReadString()
    local pri = net.ReadString()
    local sec = net.ReadString()
    local gad = net.ReadString()

    if not CVSR_CLASSES[classe] then return end

    -- MATCHMAKING: Auto-balanceamento
    local myCurrentTeam = ply:Team()
    if time ~= myCurrentTeam and (time == TEAM_COMBINE or time == TEAM_REBELS) then
        local targetPlayers = team.NumPlayers(time)
        local otherTeam = (time == TEAM_COMBINE) and TEAM_REBELS or TEAM_COMBINE
        local otherPlayers = team.NumPlayers(otherTeam)
        
        -- Impede a entrada se a equipe escolhida tiver vantagem numérica
        if targetPlayers >= otherPlayers + 1 then
            ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Equipes desbalanceadas! Escolha a outra equipe.")
            return 
        end
    end

    -- Salva as escolhas na "fila"
    ply.NextTeam = time
    ply.NextClasse = classe
    ply.NextPri = pri
    ply.NextSec = sec
    ply.NextGad = gad

    if myCurrentTeam == TEAM_UNASSIGNED or not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
        ply:Spawn()
    else
        ply:PrintMessage(HUD_PRINTTALK, "[CVSR] Sua nova classe será aplicada no próximo respawn!")
    end
end)

-- ====================================================
-- LÓGICA DE SPAWN NO MAPA CUSTOMIZADO (HAMMER)
-- ====================================================
function GM:PlayerSelectSpawn(ply)
    -- FIX DO GLITCH: Define o novo time do jogador ANTES da engine escolher o local
    if ply.NextTeam then 
        ply:SetTeam(ply.NextTeam) 
    end

    local spawnsValidos = {}
    local currentTeam = ply:Team()

    if currentTeam == TEAM_COMBINE then
        spawnsValidos = ents.FindByClass("info_spawn_combine")
    elseif currentTeam == TEAM_REBELS then
        spawnsValidos = ents.FindByClass("info_spawn_rebel")
    end

    if #spawnsValidos > 0 then
        return table.Random(spawnsValidos)
    end

    local spawnsPadrao = ents.FindByClass("info_player_start")
    if #spawnsPadrao > 0 then
        return table.Random(spawnsPadrao)
    end
end

-- Define o modelo 3D baseado na classe atual
function GM:PlayerSetModel(ply)
    local classe = ply.CVSR_ClasseSelecionada
    local time = ply:Team()

    if classe and CVSR_CLASSES[classe] and CVSR_CLASSES[classe].modelos[time] then
        local modelo = CVSR_CLASSES[classe].modelos[time]
        util.PrecacheModel(modelo)
        ply:SetModel(modelo)
        ply:SetupHands()
    else
        ply:SetModel("models/player/kleiner.mdl")
    end
end

-- Entrega as armas baseadas na classe atual
function GM:PlayerLoadout(ply)
    if not ply.CVSR_ClasseSelecionada then return true end

    ply:StripWeapons()
    ply:StripAmmo()
    ply:Give("weapon_crowbar")

    -- Detecta automaticamente o tipo de munição da arma primária (ARC9 compatível)
    if ply.CVSR_Pri and ply.CVSR_Pri ~= "" then 
        local wep = ply:Give(ply.CVSR_Pri)
        if IsValid(wep) and wep:GetPrimaryAmmoType() > 0 then
            ply:GiveAmmo(150, wep:GetPrimaryAmmoType(), true)
        end
    end

    -- Detecta munição da arma secundária
    if ply.CVSR_Sec and ply.CVSR_Sec ~= "" then 
        local wep = ply:Give(ply.CVSR_Sec)
        if IsValid(wep) and wep:GetPrimaryAmmoType() > 0 then
            ply:GiveAmmo(60, wep:GetPrimaryAmmoType(), true)
        end
    end

    -- Entrega o Gadget
    if ply.CVSR_Gad and ply.CVSR_Gad ~= "" then 
        ply:Give(ply.CVSR_Gad) 
    end

    return true
end

-- ====================================================
-- PROCESSO DE SPAWN (MODELO E ARMAS)
-- ====================================================
function GM:PlayerSpawn(ply)
    -- Apenas limpa a variável de time, pois ela já foi aplicada no SelectSpawn
    if ply.NextTeam then ply.NextTeam = nil end
    
    -- Aplica as armas e classes
    if ply.NextClasse then ply.CVSR_ClasseSelecionada = ply.NextClasse; ply.NextClasse = nil end
    if ply.NextPri then ply.CVSR_Pri = ply.NextPri; ply.NextPri = nil end
    if ply.NextSec then ply.CVSR_Sec = ply.NextSec; ply.NextSec = nil end
    if ply.NextGad then ply.CVSR_Gad = ply.NextGad; ply.NextGad = nil end

    local teamID = ply:Team()
    if teamID ~= TEAM_COMBINE and teamID ~= TEAM_REBELS then
        ply:Spectate(OBS_MODE_ROAMING)
        return
    else
        ply:UnSpectate()
        ply:SetNoDraw(false)
    end

    self.BaseClass:PlayerSpawn(ply)

    -- Verifica se já há jogadores suficientes para começar a partida
    CheckMatchStart()

    -- Teleporte manual por coordenadas JSON (se houver)
    if cvsr_Spawns[teamID] and #cvsr_Spawns[teamID] > 0 then
        local randomSpawn = table.Random(cvsr_Spawns[teamID])
        local p, a = randomSpawn.pos, randomSpawn.ang
        ply:SetPos(Vector(p.x, p.y, p.z))
        ply:SetEyeAngles(Angle(a.p, a.y, a.r))
    end
end

-- ====================================================
-- SISTEMA RTV E SCORE
-- ====================================================
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
    -- Só conta pontos se a partida estiver rolando
    if GetGlobalString("CVSR_GameState") ~= "PLAYING" then return end

    -- Verifica se quem matou é um jogador e se não foi fogo amigo (ou suicídio)
    if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() ~= victim:Team() then
        team.AddScore(attacker:Team(), 1)

        -- Checa se a equipe chegou no limite de vitórias
        if team.GetScore(attacker:Team()) >= 100 then
            PrintMessage(HUD_PRINTCENTER, "UMA EQUIPE ALCANÇOU 100 PONTOS!")
            EndMatch()
        end
    end
end)