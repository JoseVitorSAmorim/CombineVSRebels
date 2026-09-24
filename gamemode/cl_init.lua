-- cl_init.lua
include("shared.lua")
print("[CVSR] Cliente inicializado com sucesso!")

-- ====================================================
-- 1. HUD DA TELA
-- ====================================================
RunConsoleCommand("arc9_hud_arc9", "0")
local matCombine = Material("cvsr/combine_logo.png", "noclamp smooth")
local matRebel = Material("cvsr/rebel_logo.png", "noclamp smooth")

local hideElements = { ["CHudHealth"] = true, ["CHudBattery"] = true, ["CHudAmmo"] = true, ["CHudSecondaryAmmo"] = true }

surface.CreateFont("CVSR_FontHUD", { font = "Trebuchet MS", size = 24, weight = 800 })
surface.CreateFont("CVSR_FontMini", { font = "Trebuchet MS", size = 18, weight = 600 })
surface.CreateFont("CVSR_FontPlacar", { font = "Trebuchet MS", size = 32, weight = 800 })

hook.Add("HUDShouldDraw", "CVSR_HideDefaultHUD", function(name)
    if hideElements[name] then return false end
end)

hook.Add("HUDPaint", "CVSR_CustomHUD", function()
    local ply = LocalPlayer()
    
    -- Se estiver morto, no menu ou espectador, não desenha o HUD
    if not IsValid(ply) or not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then return end

    local scrW, scrH = ScrW(), ScrH()

    -- ==========================================
    -- LOGO DO TIME DO JOGADOR
    -- ==========================================
    local meuTimeID = ply:Team()
    if meuTimeID == TEAM_UNASSIGNED or not meuTimeID then return end 

    surface.SetDrawColor(255, 255, 255, 255)

    if meuTimeID == TEAM_COMBINE then
        surface.SetMaterial(matCombine)
        surface.DrawTexturedRect(20, scrH - 150, 64, 64) 
    elseif meuTimeID == TEAM_REBELS then
        surface.SetMaterial(matRebel)
        surface.DrawTexturedRect(20, scrH - 150, 64, 64)
    end

    -- ==========================================
    -- VIDA DO JOGADOR
    -- ==========================================
    local hp = ply:Health()
    draw.RoundedBox(8, 20, scrH - 80, 200, 60, Color(0, 0, 0, 200))
    draw.SimpleText("VIDA: " .. hp, "CVSR_FontHUD", 40, scrH - 50, Color(255, 60, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- ==========================================
    -- PLACAR E TIMER (Sincronizado com init.lua)
    -- ==========================================
    local matchEndTime = GetGlobalFloat("CVSR_MatchEndTime", 0)
    local tempoRestante = 0
    
    if matchEndTime > 0 then
        tempoRestante = math.max(0, math.ceil(matchEndTime - CurTime()))
    end

    local min = math.floor(tempoRestante / 60)
    local sec = tempoRestante % 60
    local tempoFormatado = string.format("%02d:%02d", min, sec)

    local ptsCombine = team.GetScore(TEAM_COMBINE) or 0
    local ptsRebel = team.GetScore(TEAM_REBELS) or 0

    draw.RoundedBox(8, scrW / 2 - 150, 10, 300, 50, Color(0, 0, 0, 200))
    draw.SimpleText(ptsCombine, "CVSR_FontPlacar", scrW / 2 - 100, 35, team.GetColor(TEAM_COMBINE), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(tempoFormatado, "CVSR_FontHUD", scrW / 2, 35, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(ptsRebel, "CVSR_FontPlacar", scrW / 2 + 100, 35, team.GetColor(TEAM_REBELS), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- ==========================================
    -- MUNIÇÃO E ARMA (Integração ARC9)
    -- ==========================================
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        local clip = wep:Clip1()
        local ammo = ply:GetAmmoCount(wep:GetPrimaryAmmoType())

        if clip >= 0 then
            draw.RoundedBox(8, scrW - 250, scrH - 80, 230, 60, Color(0, 0, 0, 200))
            draw.SimpleText("MUNIÇÃO", "CVSR_FontMini", scrW - 135, scrH - 65, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(clip .. " / " .. ammo, "CVSR_FontHUD", scrW - 135, scrH - 40, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Tradutor de modos de disparo do ARC9
            local modoDisparo = "AUTO"
            if wep.ARC9 then
                local rawMode = nil
                if wep.GetCurrentFiremodeTable then
                    local fmTable = wep:GetCurrentFiremodeTable()
                    if fmTable then
                        rawMode = fmTable.PrintName or fmTable.Mode
                    end
                end
                if not rawMode and wep.GetFiremodeText then
                    rawMode = wep:GetFiremodeText()
                end

                local strMode = tostring(rawMode or ""):lower()

                if strMode == "-1" or strMode == "auto" or strMode == "automatic" then
                    modoDisparo = "AUTO"
                elseif strMode == "1" or strMode == "semi" or strMode == "single" then
                    modoDisparo = "SEMI"
                elseif strMode == "0" or strMode == "safe" then
                    modoDisparo = "SAFE"
                elseif strMode == "2" or strMode == "2-burst" then
                    modoDisparo = "2-BURST"
                elseif strMode == "3" or strMode == "3-burst" or strMode == "burst" then
                    modoDisparo = "BURST"
                elseif tonumber(strMode) and tonumber(strMode) > 1 then
                    modoDisparo = strMode .. "-BURST"
                elseif rawMode then
                    modoDisparo = string.upper(tostring(rawMode))
                end
            end

            draw.RoundedBox(8, scrW - 250, scrH - 120, 100, 30, Color(0, 0, 0, 200))
            draw.SimpleText(modoDisparo, "CVSR_FontMini", scrW - 200, scrH - 105, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end)

-- ====================================================
-- 2. MENU DE SELEÇÃO: TIME -> CLASSE -> EQUIPAMENTO
-- ====================================================
local menuAberto = nil

function AbrirMenuSelecao()
    if IsValid(menuAberto) then menuAberto:Remove() end

    menuAberto = vgui.Create("DFrame")
    menuAberto:SetSize(600, 450)
    menuAberto:Center()
    menuAberto:SetTitle("")
    menuAberto:MakePopup()
    menuAberto:ShowCloseButton(true)
    menuAberto.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 240))
        draw.SimpleText("ESCOLHA SUA FACÇÃO E CLASSE", "Trebuchet24", w/2, 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    local pnlTimes = vgui.Create("DPanel", menuAberto)
    pnlTimes:Dock(FILL)
    pnlTimes:DockMargin(0, 40, 0, 0)
    pnlTimes.Paint = function() end

    local pnlClasses = vgui.Create("DPanel", menuAberto)
    pnlClasses:Dock(FILL)
    pnlClasses:DockMargin(0, 40, 0, 0)
    pnlClasses:SetVisible(false)
    pnlClasses.Paint = function() end

    local pnlEquip = vgui.Create("DPanel", menuAberto)
    pnlEquip:Dock(FILL)
    pnlEquip:DockMargin(0, 40, 0, 0)
    pnlEquip:SetVisible(false)
    pnlEquip.Paint = function() end

    local timeSelecionado = nil

    -- ================= TELA 1: TIMES =================
    
    -- Botão Combine
    local btnCombine = vgui.Create("DButton", pnlTimes)
    btnCombine:SetSize(250, 330)
    btnCombine:SetPos(30, 20)
    btnCombine:SetText("COMBINE")
    btnCombine:SetFont("Trebuchet24")
    btnCombine:SetTextColor(color_white)
    btnCombine.Paint = function(self, w, h)
        local corBg = self:IsHovered() and Color(0, 0, 0) or Color(192, 135, 25)
        draw.RoundedBox(8, 0, 0, w, h, corBg)
    end
    btnCombine.DoClick = function()
        timeSelecionado = TEAM_COMBINE
        pnlTimes:SetVisible(false)
        pnlClasses:SetVisible(true)
    end

    -- Logo Combine atrelada ao botão Combine (centralizada matematicamente)
    local iconCombine = vgui.Create("DImage", btnCombine)
    iconCombine:SetSize(80, 80)
    iconCombine:SetPos((250 - 80) / 2, 40)
    iconCombine:SetMaterial("cvsr/combine_logo.png")
    iconCombine:SetImageColor(Color(255, 255, 255, 255))

    -- Botão Rebelde
    local btnRebelde = vgui.Create("DButton", pnlTimes)
    btnRebelde:SetSize(250, 330)
    btnRebelde:SetPos(320, 20)
    btnRebelde:SetText("REBELDES")
    btnRebelde:SetFont("Trebuchet24")
    btnRebelde:SetTextColor(color_white)
    btnRebelde.Paint = function(self, w, h)
        local corBg = self:IsHovered() and Color(0, 0, 0) or Color(255, 168, 0)
        draw.RoundedBox(8, 0, 0, w, h, corBg)
    end
    btnRebelde.DoClick = function()
        timeSelecionado = TEAM_REBELS
        pnlTimes:SetVisible(false)
        pnlClasses:SetVisible(true)
    end

    -- Logo Rebelde atrelada ao botão Rebelde (centralizada matematicamente)
    local iconRebel = vgui.Create("DImage", btnRebelde)
    iconRebel:SetSize(80, 80)
    iconRebel:SetPos((250 - 80) / 2, 40)
    iconRebel:SetMaterial("cvsr/rebel_logo.png")
    iconRebel:SetImageColor(Color(255, 255, 255, 255))

    -- ================= TELA 2: CLASSES =================
    local listaClasses = {"assault", "support", "medic", "sniper"}
    local yPos = 20

    for _, idClasse in ipairs(listaClasses) do
        local dadosClasse = CVSR_CLASSES[idClasse]
        
        local btnClasse = vgui.Create("DButton", pnlClasses)
        btnClasse:SetSize(400, 60)
        btnClasse:SetPos(100, yPos)
        btnClasse:SetText(dadosClasse.nome)
        btnClasse:SetFont("Trebuchet24")
        btnClasse:SetTextColor(color_white)
        btnClasse.Paint = function(self, w, h)
            local corBg = self:IsHovered() and Color(100, 100, 100) or Color(50, 50, 50)
            draw.RoundedBox(8, 0, 0, w, h, corBg)
        end
        btnClasse.DoClick = function()
            pnlClasses:SetVisible(false)
            pnlEquip:Clear()
            pnlEquip:SetVisible(true)

            local equipDoTime = dadosClasse.equipamentos[timeSelecionado]

            -- ================= TELA 3: EQUIPAMENTOS =================
            local lblTitle = vgui.Create("DLabel", pnlEquip)
            lblTitle:SetText("EQUIPAMENTO: " .. string.upper(dadosClasse.nome))
            lblTitle:SetFont("Trebuchet24")
            lblTitle:SizeToContents()
            lblTitle:SetPos(100, 10)

            local selPri = equipDoTime.primarias[1] and equipDoTime.primarias[1].class or ""
            local selSec = equipDoTime.secundarias[1] and equipDoTime.secundarias[1].class or ""
            local selGad = equipDoTime.gadgets[1] and equipDoTime.gadgets[1].class or ""

            local function CriarCombo(texto, pos_Y, tabela, callback)
                if not tabela or #tabela == 0 then return end
                local l = vgui.Create("DLabel", pnlEquip)
                l:SetText(texto)
                l:SetPos(100, pos_Y)
                l:SetSize(400, 20)
                
                local c = vgui.Create("DComboBox", pnlEquip)
                c:SetPos(100, pos_Y + 20)
                c:SetSize(400, 30)
                for _, item in ipairs(tabela) do
                    c:AddChoice(item.nome, item.class)
                end
                c:ChooseOptionID(1)
                c.OnSelect = function(_, _, _, data) callback(data) end
            end

            CriarCombo("Arma Primária:", 50, equipDoTime.primarias, function(d) selPri = d end)
            CriarCombo("Arma Secundária:", 120, equipDoTime.secundarias, function(d) selSec = d end)
            CriarCombo("Gadgets / Explosivos:", 190, equipDoTime.gadgets, function(d) selGad = d end)

            local btnConfirm = vgui.Create("DButton", pnlEquip)
            btnConfirm:SetPos(100, 270)
            btnConfirm:SetSize(400, 50)
            btnConfirm:SetText("CONFIRMAR E JOGAR")
            btnConfirm:SetFont("Trebuchet24")
            btnConfirm:SetTextColor(color_white)
            btnConfirm.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, self:IsHovered() and Color(0, 180, 80) or Color(0, 150, 50))
            end
            btnConfirm.DoClick = function()
                net.Start("CVSR_ReceberEscolha")
                    net.WriteInt(timeSelecionado, 4)
                    net.WriteString(idClasse)
                    net.WriteString(selPri)
                    net.WriteString(selSec)
                    net.WriteString(selGad)
                net.SendToServer()
                menuAberto:Close()
            end
            
            local btnVoltar = vgui.Create("DButton", pnlEquip)
            btnVoltar:SetPos(100, 330)
            btnVoltar:SetSize(400, 30)
            btnVoltar:SetText("VOLTAR")
            btnVoltar.DoClick = function()
                pnlEquip:SetVisible(false)
                pnlClasses:SetVisible(true)
            end
        end
        yPos = yPos + 75
    end
end

net.Receive("CVSR_AbrirMenu", function() AbrirMenuSelecao() end)
concommand.Add("cvsr_menu", function() AbrirMenuSelecao() end)

-- ====================================================
-- 3. INTERFACE DE VOTAÇÃO DE MAPA E MATCH END
-- ====================================================
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

net.Receive("CVSR_MatchEnd", function()
    local winner = net.ReadInt(4)
    local myTeam = LocalPlayer():Team()

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 200)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()

    local statusLabel = vgui.Create("DLabel", frame)
    statusLabel:SetFont("DermaLarge")
    statusLabel:SetSize(400, 50)
    statusLabel:SetPos(0, 60)
    statusLabel:SetContentAlignment(5)

    local descLabel = vgui.Create("DLabel", frame)
    descLabel:SetFont("Trebuchet24")
    descLabel:SetSize(400, 40)
    descLabel:SetPos(0, 110)
    descLabel:SetContentAlignment(5)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 240))
        draw.RoundedBoxEx(8, 0, 0, w, 40, Color(15, 15, 15, 255), true, true, false, false)
        draw.SimpleText("FIM DE PARTIDA", "Trebuchet24", w/2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if winner == 0 then
        statusLabel:SetText("EMPATE!")
        statusLabel:SetTextColor(Color(200, 200, 200))
        descLabel:SetText("Nenhuma equipe obteve vantagem.")
        surface.PlaySound("vo/coast/odessa/male01/nlo_cheer01.wav") 
        
    elseif winner == myTeam then
        statusLabel:SetText("VITÓRIA!")
        statusLabel:SetTextColor(Color(50, 255, 50))
        descLabel:SetText("Sua equipe venceu o combate.")
        surface.PlaySound("ui/cyoa_objective_panel_anim_temp.wav") 
        
    else
        statusLabel:SetText("DERROTA!")
        statusLabel:SetTextColor(Color(255, 50, 50))
        local enemyName = (winner == TEAM_COMBINE) and "Combine" or "Rebels"
        descLabel:SetText("Os " .. enemyName .. " venceram.")
        surface.PlaySound("npc/overwatch/cityvoice/fcitadel_30secwarning.wav") 
    end

    timer.Simple(9, function()
        if IsValid(frame) then frame:Remove() end
    end)
end)