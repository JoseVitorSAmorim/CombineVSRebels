GM.Name = "Combine vs Rebels"
GM.Author = "Posterghost"

TEAM_COMBINE = 1
TEAM_REBELS  = 2

CVSR_Loadouts = {
    [TEAM_COMBINE] = {
        models = {
            "models/player/combine_soldier.mdl",
            "models/player/combine_soldier_prisonguard.mdl",
            "models/player/combine_super_soldier.mdl",
            "models/player/police.mdl"
        },
        primaries = {
            { name = "AR2 (Pulse Rifle)", class = "weapon_ar2" },
            { name = "SMG1", class = "weapon_smg1" },
            { name = "Shotgun", class = "weapon_shotgun" }
        },
        secondaries = {
            { name = "Pistola 9mm", class = "weapon_pistol" },
            { name = "Revolver .357", class = "weapon_357" }
        },
        gadgets = {
            { name = "Granada Frag", class = "weapon_frag" },
            { name = "SLAM", class = "weapon_slam" }
        }
    },
    [TEAM_REBELS] = {
        models = {
            "models/player/group01/male_01.mdl",
            "models/player/group01/male_07.mdl",
            "models/player/group03/female_01.mdl",
            "models/player/group03/male_04.mdl"
        },
        primaries = {
            { name = "SMG1", class = "weapon_smg1" },
            { name = "Shotgun", class = "weapon_shotgun" },
            { name = "Crossbow", class = "weapon_crossbow" }
        },
        secondaries = {
            { name = "Revolver .357", class = "weapon_357" },
            { name = "Pistola 9mm", class = "weapon_pistol" }
        },
        gadgets = {
            { name = "Granada Frag", class = "weapon_frag" },
            { name = "RPG", class = "weapon_rpg" }
        }
    }
}

function GM:CreateTeams()
    team.SetUp(TEAM_COMBINE, "Combines", Color(30, 144, 255))
    team.SetSpawnPoint(TEAM_COMBINE, "info_player_start")

    team.SetUp(TEAM_REBELS, "Rebels", Color(220, 20, 60))
    team.SetSpawnPoint(TEAM_REBELS, "info_player_start")
end