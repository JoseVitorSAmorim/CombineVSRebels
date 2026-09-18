-- cl_init.lua
include("shared.lua")
print("[CVSR] Cliente inicializado com sucesso!")

-- ====================================================
-- 1. HUD DA TELA
-- ====================================================
local hideElements = { ["CHudHealth"] = true, ["CHudBattery"] = true }
hook.Add("HUDShouldDraw", "CVSR_HideDefaultHUD", function(name)
    if hideElements[name] then return false end
end)

hook.Add("HUDPaint", "CVSR_DrawHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local combineScore = team.GetScore(TEAM_COMBINE)
    local rebelScore   = team.GetScore(TEAM_REBELS)
    local remaining    = math.max(0, GetGlobalFloat("CVSR_MatchEndTime", 0) - CurTime())
    local timeText     = string.ToMinutesSeconds(math.ceil(remaining))

    local scoreBoxW, timerBoxW, boxH = 70, 100, 38
    local startX = (ScrW() / 2) - ((scoreBoxW * 2 + timerBoxW) / 2)
    local startY = 20

    draw.RoundedBoxEx(8, startX, startY, scoreBoxW, boxH, Color(30, 144, 255, 220), true, false, true, false)
    draw.SimpleText(combineScore, "Trebuchet24", startX + (scoreBoxW / 2), startY + 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local timerX = startX + scoreBoxW
    draw.RoundedBox(0, timerX, startY, timerBoxW, boxH, Color(15, 15, 15, 230))
    local timerColor = (remaining <= 30) and Color(255, 60, 60) or color_white
    draw.SimpleText(timeText, "Trebuchet24", timerX + (timerBoxW / 2), startY + 6, timerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    local rebelX = timerX + timerBoxW
    draw.RoundedBoxEx(8, rebelX, startY, scoreBoxW, boxH, Color(220, 20, 60, 220), false, true, false, true)
    draw.SimpleText(rebelScore, "Trebuchet24", rebelX + (scoreBoxW / 2), startY + 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    if not ply:Alive() or (ply:Team() ~= TEAM_COMBINE and ply:Team() ~= TEAM_REBELS) then return end
    local hp = math.Clamp(ply:Health(), 0, 100)
    local teamID = ply:Team()
    local teamName = team.GetName(teamID) or "Sem Time"
    local teamColor = team.GetColor(teamID) or color_white

    local x, y, width, height = 30, ScrH() - 110, 240, 75
    draw.RoundedBox(8, x, y, width, height, Color(15, 15, 15, 220))
    draw.SimpleText(string.upper(teamName), "Trebuchet24", x + 15, y + 10, teamColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local barX, barY, barW, barH = x + 15, y + 42, width - 30, 18
    draw.RoundedBox(4, barX, barY, barW, barH, Color(40, 40, 40, 255))
    if (hp / 100) * barW > 0 then
        draw.RoundedBox(4, barX, barY, (hp / 100) * barW, barH, Color(200, 40, 40, 230))
    end
    draw.SimpleText(hp .. " / 100", "DermaDefaultBold", barX + (barW / 2), barY + 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
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
    local btnCombine = vgui.Create("DButton", pnlTimes)
    btnCombine:SetSize(250, 330)
    btnCombine:SetPos(30, 20)
    btnCombine:SetText("COMBINE")
    btnCombine:SetFont("Trebuchet24")
    btnCombine:SetTextColor(color_white)
    btnCombine.Paint = function(self, w, h)
        local corBg = self:IsHovered() and Color(70, 170, 255) or Color(30, 144, 255)
        draw.RoundedBox(8, 0, 0, w, h, corBg)
    end
    btnCombine.DoClick = function()
        timeSelecionado = TEAM_COMBINE
        pnlTimes:SetVisible(false)
        pnlClasses:SetVisible(true)
    end

    local btnRebelde = vgui.Create("DButton", pnlTimes)
    btnRebelde:SetSize(250, 330)
    btnRebelde:SetPos(320, 20)
    btnRebelde:SetText("REBELDES")
    btnRebelde:SetFont("Trebuchet24")
    btnRebelde:SetTextColor(color_white)
    btnRebelde.Paint = function(self, w, h)
        local corBg = self:IsHovered() and Color(255, 70, 70) or Color(220, 20, 60)
        draw.RoundedBox(8, 0, 0, w, h, corBg)
    end
    btnRebelde.DoClick = function()
        timeSelecionado = TEAM_REBELS
        pnlTimes:SetVisible(false)
        pnlClasses:SetVisible(true)
    end

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

            -- Busca os equipamentos baseados no time escolhido na Tela 1
            local equipDoTime = dadosClasse.equipamentos[timeSelecionado]

            -- ================= TELA 3: EQUIPAMENTOS =================
            local lblTitle = vgui.Create("DLabel", pnlEquip)
            lblTitle:SetText("EQUIPAMENTO: " .. string.upper(dadosClasse.nome))
            lblTitle:SetFont("Trebuchet24")
            lblTitle:SizeToContents()
            lblTitle:SetPos(100, 10)

            -- Variáveis padrão pegando as armas específicas do time
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

            -- Passa a tabela de armas do time específico
            CriarCombo("Arma Primária:", 50, equipDoTime.primarias, function(d) selPri = d end)
            CriarCombo("Arma Secundária:", 120, equipDoTime.secundarias, function(d) selSec = d end)
            CriarCombo("Gadgets / Explosivos:", 190, equipDoTime.gadgets, function(d) selGad = d end)

            -- Botão Confirmar continua igual...
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
-- 3. INTERFACE DE VOTAÇÃO DE MAPA
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