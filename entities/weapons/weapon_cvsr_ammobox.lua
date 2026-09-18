AddCSLuaFile()

SWEP.PrintName = "Caixa de Munição"
SWEP.Author = "Posterghost"
SWEP.Instructions = "Botão ESQUERDO: Dar munição a um aliado próximo.\nBotão DIREITO: Reabastecer a própria munição."
SWEP.Category = "CVSR Gadgets"
SWEP.Spawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true

-- Dar munição para o aliado
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 2)
    if CLIENT then return end
    
    local tr = self.Owner:GetEyeTrace()
    -- Verifica se atingiu um player do mesmo time, perto o suficiente (distância 150)
    if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:Team() == self.Owner:Team() and tr.HitPos:Distance(self.Owner:GetPos()) < 150 then
        local target = tr.Entity
        local deuMunicao = false

        -- Varre todas as armas do aliado e dá munição correta (funciona com o ARC9)
        for _, w in ipairs(target:GetWeapons()) do
            if IsValid(w) and w:GetPrimaryAmmoType() > 0 then
                target:GiveAmmo(90, w:GetPrimaryAmmoType())
                deuMunicao = true
            end
        end

        if deuMunicao then
            target:EmitSound("items/ammo_pickup.wav")
            self.Owner:ChatPrint("Você reabasteceu " .. target:Nick() .. "!")
            target:ChatPrint(self.Owner:Nick() .. " reabasteceu sua munição!")
            self.Owner:SetAnimation(PLAYER_ATTACK1)
        end
    end
end

-- Dar munição para si mesmo
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 5)
    if CLIENT then return end
    
    local deuMunicao = false
    
    for _, w in ipairs(self.Owner:GetWeapons()) do
        if IsValid(w) and w:GetPrimaryAmmoType() > 0 then
            self.Owner:GiveAmmo(60, w:GetPrimaryAmmoType())
            deuMunicao = true
        end
    end

    if deuMunicao then
        self.Owner:EmitSound("items/ammo_pickup.wav")
        self.Owner:ChatPrint("Você reabasteceu sua própria munição.")
        self.Owner:SetAnimation(PLAYER_ATTACK1)
    end
end