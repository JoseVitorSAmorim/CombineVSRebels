-- cl_init.lua
include("shared.lua")

print("[CVSR] Cliente inicializado com sucesso!")

local hideElements = { ["CHudHealth"] = true, ["CHudBattery"] = true }
hook.Add("HUDShouldDraw", "CVSR_HideDefaultHUD", function(name)
    if hideElements[name] then return false end
end)

hook.Add("HUDPaint", "CVSR_DrawHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- 1. PLACAR E TIMER
    local combineScore = team.GetScore(TEAM_COMBINE)
    local rebelScore   = team.GetScore(TEAM_REBELS)
    local remaining    = math.max(0, GetGlobalFloat("CVSR_MatchEndTime", 0) - CurTime())
    local timeText     = string.ToMinutesSeconds(math.ceil(remaining))

    local scoreBoxW, timerBoxW, boxH = 70, 100, 38
    local startX = (ScrW() / 2) - ((scoreBoxW * 2 + timerBoxW) / 2)
    local startY = 20

    draw.RoundedBoxEx(8, startX, startY, scoreBoxW, boxH, Color(30, 144, 255, 220), true, false, true, false)
    draw.SimpleText(combineScore, "Trebuchet24", startX + (scoreBoxW / 2), startY + 6, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local timerX = startX + scoreBoxW
    draw.RoundedBox(0, timerX, startY, timerBoxW, boxH, Color(15, 15, 15, 230))
    local timerColor = (remaining <= 30) and Color(255, 60, 60) or Color(255, 255, 255)
    draw.SimpleText(timeText, "Trebuchet24", timerX + (timerBoxW / 2), startY + 6, timerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local rebelX = timerX + timerBoxW
    draw.RoundedBoxEx(8, rebelX, startY, scoreBoxW, boxH, Color(220, 20, 60, 220), false, true, false, true)
    draw.SimpleText(rebelScore, "Trebuchet24", rebelX + (scoreBoxW / 2), startY + 6, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- 2. HUD DE VIDA
    if not ply:Alive() then return end
    local hp = math.Clamp(ply:Health(), 0, 100)
    local teamID = ply:Team()
    local teamName = team.GetName(teamID) or "Sem Time"
    local teamColor = team.GetColor(teamID) or Color(255, 255, 255)

    local x, y, width, height = 30, ScrH() - 110, 240, 75
    draw.RoundedBox(8, x, y, width, height, Color(15, 15, 15, 220))
    draw.SimpleText(string.upper(teamName), "Trebuchet24", x + 15, y + 10, teamColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local barX, barY, barW, barH = x + 15, y + 42, width - 30, 18
    draw.RoundedBox(4, barX, barY, barW, barH, Color(40, 40, 40, 255))
    if (hp / 100) * barW > 0 then
        draw.RoundedBox(4, barX, barY, (hp / 100) * barW, barH, Color(200, 40, 40, 230))
    end
    draw.SimpleText(hp .. " / 100", "DermaDefaultBold", barX + (barW / 2), barY + 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)

----------------------------------------------------
-- INTERFACE DO MENU DE CLASSES (F2)
----------------------------------------------------
function OpenClassMenu()
    local ply = LocalPlayer()
    local teamID = ply:Team()
    local options = CVSR_Loadouts and CVSR_Loadouts[teamID]

    if not options then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(620, 420)
    frame:Center()
    frame:SetTitle("Seleção de Equipamento e Classe")
    frame:MakePopup()

    local modelPanel = vgui.Create("DModelPanel", frame)
    modelPanel:SetPos(330, 40)
    modelPanel:SetSize(270, 320)
    modelPanel:SetModel(options.models[1])
    modelPanel:SetCamPos(Vector(50, 0, 50))
    modelPanel:SetLookAt(Vector(0, 0, 40))
    modelPanel:SetFOV(50)

    local selPrimary   = options.primaries[1].class
    local selSecondary = options.secondaries[1].class
    local selGadget    = options.gadgets[1].class
    local selModel     = options.models[1]

    local function CreateSelector(labelText, yPos, dataTable, onSelect)
        local lbl = vgui.Create("DLabel", frame)
        lbl:SetPos(20, yPos)
        lbl:SetText(labelText)
        lbl:SetFont("DermaDefaultBold")
        lbl:SizeToContents()

        local combo = vgui.Create("DComboBox", frame)
        combo:SetPos(20, yPos + 18)
        combo:SetSize(280, 28)
        for _, item in ipairs(dataTable) do
            combo:AddChoice(type(item) == "table" and item.name or item, type(item) == "table" and item.class or item)
        end
        combo:ChooseOptionID(1)
        combo.OnSelect = function(s, idx, val, data) onSelect(data or val) end
    end

    CreateSelector("Arma Primária:", 40, options.primaries, function(d) selPrimary = d end)
    CreateSelector("Arma Secundária:", 100, options.secondaries, function(d) selSecondary = d end)
    CreateSelector("Equipamento / Explosivo:", 160, options.gadgets, function(d) selGadget = d end)
    CreateSelector("Modelo de Personagem:", 220, options.models, function(d) 
        selModel = d
        modelPanel:SetModel(d)
    end)

    local btn = vgui.Create("DButton", frame)
    btn:SetPos(20, 350)
    btn:SetSize(580, 45)
    btn:SetText("CONFIRMAR SELEÇÃO")
    btn:SetFont("Trebuchet24")
    btn.DoClick = function()
        net.Start("CVSR_SelectLoadout")
            net.WriteString(selPrimary)
            net.WriteString(selSecondary)
            net.WriteString(selGadget)
            net.WriteString(selModel)
        net.SendToServer()
        frame:Close()
    end
end

-- Recebe o sinal do servidor para abrir o menu quando F2 for pressionado
net.Receive("CVSR_OpenClassMenu", function()
    OpenClassMenu()
end)

concommand.Add("cvsr_menu", function() OpenClassMenu() end)

----------------------------------------------------
-- INTERFACE DE VOTAÇÃO DE MAPA (RTV)
----------------------------------------------------
net.Receive("CVSR_StartMapVote", function()
    local maps = net.ReadTable()
    local voteEndTime = net.ReadFloat()

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 320)
    frame:Center()
    frame:SetTitle("Votação de Próximo Mapa")
    frame:ShowCloseButton(false)
    frame:MakePopup()

    local label = vgui.Create("DLabel", frame)
    label:SetPos(10, 35)
    label:SetSize(380, 20)
    label:SetContentAlignment(5)

    frame.Think = function()
        local remaining = math.max(0, math.ceil(voteEndTime - CurTime()))
        label:SetText("Escolha o próximo mapa (Tempo restante: " .. remaining .. "s):")
        if remaining <= 0 and IsValid(frame) then frame:Close() end
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(20, 65)
    scroll:SetSize(360, 230)

    for idx, mapName in ipairs(maps) do
        local btn = scroll:Add("DButton")
        btn:SetText(mapName)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 8)
        btn:SetHeight(40)
        btn.DoClick = function()
            net.Start("CVSR_SubmitMapVote")
                net.WriteInt(idx, 8)
            net.SendToServer()
            for _, child in ipairs(scroll:GetCanvas():GetChildren()) do child:SetEnabled(false) end
            btn:SetText(mapName .. " (VOTADO)")
        end
    end
end)