-- shared.lua
GM.Name = "Combine vs Rebels"
GM.Author = "Posterghost"

TEAM_COMBINE = 1
TEAM_REBELS  = 2

function GM:CreateTeams()
    team.SetUp(TEAM_COMBINE, "Combines", Color(30, 144, 255))
    team.SetSpawnPoint(TEAM_COMBINE, "info_player_start")

    team.SetUp(TEAM_REBELS, "Rebels", Color(220, 20, 60))
    team.SetSpawnPoint(TEAM_REBELS, "info_player_start")
end

-- Tabela de modelos por time (personagem escolhido aleatoriamente)
CVSR_TEAM_MODELS = {
    [TEAM_COMBINE] = {
        "models/player/combine_soldier.mdl",
        "models/player/combine_soldier_prisonguard.mdl",
        "models/player/combine_super_soldier.mdl",
        "models/player/police.mdl"
    },
    [TEAM_REBELS] = {
        "models/player/group01/male_01.mdl",
        "models/player/group01/male_07.mdl",
        "models/player/group03/female_01.mdl",
        "models/player/group03/male_04.mdl"
    }
}

-- Tabela de Classes com opções de equipamento
CVSR_CLASSES = {
    ["assault"] = {
        nome = "Assalto",
        primarias = {
            { nome = "SMG1", class = "weapon_smg1" },
            { nome = "Shotgun", class = "weapon_shotgun" }
        },
        secundarias = {
            { nome = "Pistola 9mm", class = "weapon_pistol" }
        },
        gadgets = {
            { nome = "Granada Frag", class = "weapon_frag" }
        }
    },
    ["support"] = {
        nome = "Suporte",
        primarias = {
            { nome = "AR2 (Pulse Rifle)", class = "weapon_ar2" },
            { nome = "Shotgun", class = "weapon_shotgun" }
        },
        secundarias = {
            { nome = "Revolver .357", class = "weapon_357" },
            { nome = "Pistola 9mm", class = "weapon_pistol" }
        },
        gadgets = {
            { nome = "SLAM", class = "weapon_slam" }
        }
    },
    ["medic"]   = {
        nome = "Médico",
        primarias = {
            { nome = "SMG1", class = "weapon_smg1" }
        },
        secundarias = {
            { nome = "Pistola 9mm", class = "weapon_pistol" }
        },
        gadgets = {
            { nome = "Stunstick (Kit Médico)", class = "weapon_stunstick" }
        }
    },
    ["sniper"]  = {
        nome = "Sniper",
        primarias = {
            { nome = "Crossbow", class = "weapon_crossbow" }
        },
        secundarias = {
            { nome = "Revolver .357", class = "weapon_357" },
            { nome = "Pistola 9mm", class = "weapon_pistol" }
        },
        gadgets = {
            { nome = "Granada Frag", class = "weapon_frag" },
            { nome = "SLAM", class = "weapon_slam" }
        }
    }
}