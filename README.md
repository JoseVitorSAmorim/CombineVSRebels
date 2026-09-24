# ⚔️ Combine vs Rebels (CVSR) - Garry's Mod Gamemode

Um gamemode de **Team Deathmatch (TDM)** para Garry's Mod, focado no confronto clássico entre a aliança **Combine** e a **Resistência Rebelde**.

O projeto conta com menu de classes interativo em 3D, sistema de spawn customizado por mapa, HUD própria, tempo de partida e votação de mapa automática com suporte a RTV (*Rock The Vote*).

---

## 📋 Sumário
- [Sobre o Gamemode](#-sobre-o-gamemode)
- [Funcionalidades](#-funcionalidades)
- [Como Funciona](#-como-funciona)
- [Comandos e Atalhos](#-comandos-e-atalhos)
- [Regras do Gamemode](#-regras-do-gamemode)
- [Instalação e Estrutura de Arquivos](#-instalação-e-estrutura-de-arquivos)
- [Configuração de Spawns para Admins](#-configuração-de-spawns-para-admins)

---

## 🎮 Sobre o Gamemode

Em **Combine vs Rebels (CVSR)**, os jogadores são divididos aleatoriamente entre dois times ao entrar no servidor. O objetivo principal é eliminar jogadores do time adversário para acumular pontos para a sua equipe antes que o tempo da partida termine.

---

## ✨ Funcionalidades

- **HUD Customizada:** Exibe a vida atual do jogador, placar de eliminações dos dois times e o cronômetro da partida no topo da tela.
- **Menu de Equipamentos e Classes (F2):** Interface Derma com visualização do modelo 3D em tempo real para escolha de armas primárias, secundárias, utilitários e skins do personagem.
- **Sistema Persistente de Spawns:** Permite que administradores definam pontos de nascimento customizados para cada time por mapa, salvos automaticamente em formato JSON.
- **Votação de Mapa & RTV:** Sistema automático de votação de mapa ao fim da partida ou quando a maioria dos jogadores solicita via `!rtv`.
- **Atribuição Automática de Loadout:** Equipamentos selecionados no menu são aplicados automaticamente a cada respawn.

---

## ⚙️ Como Funciona

1. **Início da Partida:** 
   - Ao entrar, o jogador é atribuído aleatoriamente aos **Combines** ou **Rebeldes**.
   - O tempo padrão de cada partida é de **10 minutos** (600 segundos).

2. **Seleção de Loadout:**
   - Pressionando `F2`, o jogador abre o menu de seleção de classe/arma.
   - O jogador escolhe sua Arma Primária, Secundária, Equipamento e Modelo de Personagem.
   - As alterações são aplicadas a partir do próximo respawn.

3. **Pontuação:**
   - Cada eliminação (*kill*) de um inimigo concede **1 ponto** no placar global do time.
   - *Fogo amigo* não soma pontos ao placar.

4. **Fim de Partida & Votação:**
   - Quando o tempo expira ou o RTV atinge a meta de 50% dos jogadores, o jogo congela e abre uma interface de votação de mapa por 20 segundos.
   - Após a contagem, o servidor muda automaticamente para o mapa mais votado.

---

## ⌨️ Comandos e Atalhos

### 🎯 Para Jogadores

| Atalho / Comando | Onde Usar | Descrição |
| :--- | :--- | :--- |
| `F2` | Teclado | Abre o menu de Seleção de Classes e Equipamentos. |
| `!rtv` / `rtv` | Chat do Jogo | Solicita a votação antecipada para troca de mapa (Rock The Vote). |
| `cvsr_menu` | Console (`~`) | Abre o menu de classes via console. |
| `cvsr_rtv` | Console (`~`) | Envia solicitação de RTV via console. |

### 🛠️ Para Administradores

| Comando Console | Parâmetros | Descrição |
| :--- | :--- | :--- |
| `cvsr_addspawn` | `combine` ou `rebel` | Salva a posição e ângulo atual do jogador como ponto de spawn para o time especificado no mapa atual. |

> **Exemplo de Uso:** `cvsr_addspawn combine` ou `cvsr_addspawn rebel`

---

## 📜 Regras do Gamemode

1. **Objetivo em Equipe:** O trabalho em equipe é essencial para garantir vitórias nas rodadas.
2. **Spawns Customizados:** Se um mapa não possuir pontos salvos criados via `cvsr_addspawn`, os jogadores nascerão nos pontos padrão do mapa (ou sobrepostos). Recomenda-se configurar os spawns ao adicionar um mapa novo ao servidor.
3. **Mudar de Classe:** Mudanças efetuadas durante a vida atual só terão efeito quando o jogador morrer e renascer.

---

## 📂 Instalação e Estrutura de Arquivos

Coloque a pasta do gamemode no diretório `garrysmod/gamemodes/cvsr/`.

### Estrutura de Pastas:
```text
garrysmod/
└── gamemodes/
    └── cvsr/
        ├── entities/
        |   ├── weapons/
        |       ├── weapon_cvsr_ammobox.lua  -- Arquivo da AmmoBox
        ├── gamemode/
        │   ├── shared.lua    -- Definição de times, variáveis globais e loadouts
        │   ├── init.lua      -- Lógica do servidor, spawns, regras de partida e RTV
        │   └── cl_init.lua   -- Interface visual (HUD), menus Derma e recepção de pacotes
        └── cvsr.txt          -- Arquivo de manifesto do Gamemode
```

### Addons requeridos:
| Addon | Autor(es) | Link |
| :--- | :--- | :--- |
| ARC9 Weapon Base | Arctic, Darsu, Feslug, maladesov, Midawek, Moka, Sepnny Tommy / M541, Twilight Sparkle, 8Z | https://steamcommunity.com/sharedfiles/filedetails/?id=2910505837 |
| [ARC9] Gunsmith Arms: Source | Arctic | https://steamcommunity.com/sharedfiles/filedetails/?id=2910527565 |
| [ARC9] Escape from Tarkov SHARED | Darsu, Mal0, Moka | https://steamcommunity.com/sharedfiles/filedetails/?id=2917343547 |
| [ARC9] EFT Explosives | Darsu | https://steamcommunity.com/sharedfiles/filedetails/?id=3010049092 |
