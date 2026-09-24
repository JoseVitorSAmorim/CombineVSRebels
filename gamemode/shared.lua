-- shared.lua
GM.Name = "Combine vs Rebels"
GM.Author = "Posterghost"

TEAM_COMBINE = 1
TEAM_REBELS  = 2
TEAM_UNASSIGNED = 1001

function GM:CreateTeams()
    team.SetUp(TEAM_COMBINE, "Combines", Color(192, 135, 25))
    team.SetSpawnPoint(TEAM_COMBINE, "info_player_start")

    team.SetUp(TEAM_REBELS, "Rebels", Color(252, 109, 2))
    team.SetSpawnPoint(TEAM_REBELS, "info_player_start")
end

-- CVSR_TEAM_MODELS foi removido. Os modelos agora ficam dentro de cada classe!

-- Tabela de Classes com equipamentos divididos por facção e modelos únicos
CVSR_CLASSES = {
    ["assault"] = {
        nome = "Assalto",
        modelos = {
            [TEAM_COMBINE] = "models/player/combine_soldier.mdl",
            [TEAM_REBELS]  = "models/player/Group03/male_07.mdl"
        },
        equipamentos = {
            [TEAM_COMBINE] = { -- OTAN
                primarias = { { nome = "M4A1", class = "arc9_fas_m4a1" }, { nome = "M16A2", class = "arc9_fas_m16a2" }, { nome = "M14", class = "arc9_fas_m14" } },
                secundarias = { { nome = "M1911", class = "arc9_fas_m1911" }, { nome = "Glock 20", class = "arc9_fas_g20" } },
                gadgets = { { nome = "M67", class = "arc9_eft_m67" }, { nome = "F1", class = "arc9_fas_f1" }, { nome = "V40", class = "arc9_eft_v40" }, { nome = "M18", class = "arc9_fas_m18" } }
            },
            [TEAM_REBELS] = { -- Pacto de Varsóvia
                primarias = { { nome = "AK-47", class = "arc9_fas_ak47" }, { nome = "AKS-74", class = "arc9_fas_ak74" }, { nome = "RK 95", class = "arc9_fas_rk95" }, { nome = "SKS", class = "arc9_fas_sks" } },
                secundarias = { { nome = "MP-443", class = "arc9_fas_grach" }, { nome = "OTs-33", class = "arc9_fas_ots33" } },
                gadgets = { { nome = "RGD-5", class = "arc9_eft_rgd5" }, { nome = "RGN", class = "arc9_eft_rgn" }, { nome = "V40", class = "arc9_eft_v40" }, { nome = "RGO", class = "arc9_eft_rgo" }, { nome = "M18", class = "arc9_fas_m18" } }
            }
        }
    },
    ["support"] = {
        nome = "Suporte",
        modelos = {
            [TEAM_COMBINE] = "models/player/combine_super_soldier.mdl",
            [TEAM_REBELS]  = "models/player/Group03/male_03.mdl"
        },
        equipamentos = {
            [TEAM_COMBINE] = {
                primarias = { { nome = "M249 SAW", class = "arc9_fas_m249" }, { nome = "M60", class = "arc9_fas_m60" }, { nome = "M3 Super", class = "arc9_fas_m3super90" }, { nome = "Remington 870", class = "arc9_fas_870" } },
                secundarias = { { nome = "M1911", class = "arc9_fas_m1911" }, { nome = "Glock 20", class = "arc9_fas_g20" } },
                gadgets = { { nome = "Ammobox (Caixa de Munição)", class = "weapon_cvsr_ammobox" }, { nome = "GL-40", class = "arc9_eft_fn40gl" }, { nome = "SLAM", class = "weapon_slam" } }
            },
            [TEAM_REBELS] = {
                primarias = { { nome = "RPK", class = "arc9_fas_rpk" }, { nome = "KS-23", class = "arc9_fas_ks23" }, { nome = "Saiga 12K", class = "arc9_fas_saiga" } },
                secundarias = { { nome = "MP-443", class = "arc9_fas_grach" }, { nome = "OTs-33", class = "arc9_fas_ots33" } },
                gadgets = { { nome = "Ammobox (Caixa de Munição)", class = "weapon_cvsr_ammobox" }, { nome = "M79 Thunder", class = "arc9_fas_m79" }, { nome = "RShG-12", class = "arc9_eft_rshg2" } }
            }
        }
    },
    ["medic"] = {
        nome = "Médico",
        modelos = {
            [TEAM_COMBINE] = "models/player/police.mdl", 
            [TEAM_REBELS]  = "models/player/Group03m/male_02.mdl" 
        },
        equipamentos = {
            [TEAM_COMBINE] = {
                primarias = { { nome = "MP5", class = "arc9_fas_mp5" }, { nome = "Uzi", class = "arc9_fas_uzi" } },
                secundarias = { { nome = "M1911", class = "arc9_fas_m1911" }, { nome = "Glock 20", class = "arc9_fas_g20" } },
                gadgets = { { nome = "Kit Médico", class = "weapon_medkit" }, { nome = "M84 Stun", class = "arc9_fas_m84" } }
            },
            [TEAM_REBELS] = {
                primarias = { { nome = "PP-19 Bizon", class = "arc9_ur_bizon" }, { nome = "Sterling", class = "arc9_fas_sterling" } },
                secundarias = { { nome = "MP-443", class = "arc9_fas_grach" }, { nome = "OTs-33", class = "arc9_fas_ots33" } },
                gadgets = { { nome = "Kit Médico", class = "weapon_medkit" }, { nome = "M84 Stun", class = "arc9_fas_m84" } }
            }
        }
    },
    ["sniper"] = {
        nome = "Sniper",
        modelos = {
            [TEAM_COMBINE] = "models/player/combine_soldier_prisonguard.mdl",
            [TEAM_REBELS]  = "models/player/Group03/male_09.mdl"
        },
        equipamentos = {
            [TEAM_COMBINE] = {
                primarias = { { nome = "M24", class = "arc9_fas_m24" }, { nome = "SR-25", class = "arc9_fas_sr25" } },
                secundarias = { { nome = "M1911", class = "arc9_fas_m1911" }, { nome = "Glock 20", class = "arc9_fas_g20" } },
                gadgets = { { nome = "M18", class = "arc9_fas_m18" }, { nome = "Signal Flare", class = "arc9_fas_flare" } }
            },
            [TEAM_REBELS] = {
                primarias = { { nome = "SVD Dragunov", class = "arc9_fas_svd" } },
                secundarias = { { nome = "MP-443", class = "arc9_fas_grach" }, { nome = "OTs-33", class = "arc9_fas_ots33" } },
                gadgets = { { nome = "M18", class = "arc9_fas_m18" }, { nome = "Signal Flare", class = "arc9_fas_flare" } }
            }
        }
    }
}