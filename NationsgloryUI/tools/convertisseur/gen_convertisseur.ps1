# REMPLACE le 05/11 par tools/convertisseur/convertisseur.py (charte NG BE, sans la partie XP PASSE, retour de Leo).
# Garde pour memoire : ne plus le lancer, il reecrirait l'ancien ecran.
# Ecrit ui/Interface/convertisseur.json : l'ecran du Convertisseur (/atm et /afk), conteneur premium:converter_ui de
# PremiumMod (PremiumMod/Ui/ConverterUi.cs, cases dans PremiumMod/Ui/ConverterSlots.cs).
#
#   powershell -ExecutionPolicy Bypass -File tools\convertisseur\gen_convertisseur.ps1
#
# Les positions et les couleurs sont relevees sur la maquette (capture de 1034 x 743 px, fenetre interieure de 977 x 687 px
# a partir de (17, 45)) : 3 px de la maquette font une unite d'interface. Le solde en points boutique de la maquette n'est
# pas repris. Memes formes de liaison que la recompense quotidienne (ui/Interface/daily_reward.json) : texte d'une case lu
# dans #hover_text, etat d'un bouton lu dans le drapeau du debut de son texte (paragraphe 1 actif), clic par
# button.drop_all, croix par button.menu_exit, bouton Accueil sur la case 1 de PalaUiMod.
param([string]$Pack = (Join-Path $PSScriptRoot '..\..'))

$ErrorActionPreference = 'Stop'

# Origine et echelle de la maquette.
$OX = 17; $OY = 45; $K = 3.0
$SECTION = [string][char]0xA7

# Cases de PremiumMod/Ui/ConverterSlots.cs.
$HUB = 1
$TITLE, $BALANCE, $PLAYTIME_LABEL, $PLAYTIME = 10, 11, 12, 13
$MONEY_LABEL, $MONEY_RATE, $MONEY_AMOUNT, $MONEY_BUTTON, $MONEY_BUTTON_TEXT = 14, 15, 16, 17, 18
$XP_LABEL, $XP_NONE, $XP_BUTTON_TEXT = 19, 20, 21

function U([double]$px) { [Math]::Round($px / $K, 2) }
function PX([double]$x) { U ($x - $OX) }
function PY([double]$y) { U ($y - $OY) }
function Col([string]$hex) {
    @([Math]::Round([Convert]::ToInt32($hex.Substring(0, 2), 16) / 255, 3),
      [Math]::Round([Convert]::ToInt32($hex.Substring(2, 2), 16) / 255, 3),
      [Math]::Round([Convert]::ToInt32($hex.Substring(4, 2), 16) / 255, 3))
}

$script:n = 0
function Name([string]$prefix) { $script:n++; "{0}_{1}" -f $prefix, $script:n }
function Node([string]$name, $body) { $o = [ordered]@{}; $o[$name] = $body; $o }

$WHITE_TEX = 'textures/ui/background/background_white'

# Un rectangle de la maquette, bornes incluses.
function Rect([double]$x0, [double]$y0, [double]$x1, [double]$y1, [string]$hex, [int]$layer) {
    Node (Name 'r') ([ordered]@{
        type = 'image'; texture = $WHITE_TEX; color = (Col $hex)
        anchor_from = 'top_left'; anchor_to = 'top_left'
        offset = @((PX $x0), (PY $y0)); size = @((U ($x1 - $x0 + 1)), (U ($y1 - $y0 + 1))); layer = $layer
    })
}

function TextBinding() {
    , @([ordered]@{ binding_type = 'collection'; binding_collection_name = 'container_items'; binding_name = '#hover_text'; binding_name_override = '#text' })
}

function LabelBody([string]$hex, [string]$font, [double]$scale, [string]$anchor, [string]$align, $text) {
    $label = [ordered]@{
        type = 'label'; text = $text; size = @('default', 'default')
        anchor_from = $anchor; anchor_to = $anchor; text_alignment = $align
        color = (Col $hex); font_scale_factor = $scale; font_type = $font; shadow = $false; localize = $false
    }
    if ($text -eq '#text') { $label['bindings'] = TextBinding }
    $label
}

# Le texte de la case $slot dans la zone [x0, x1] de la maquette ; $top : haut des lettres (ancre en haut), sinon
# $center : milieu des lettres (ancre au milieu, pour MinecraftTen).
function SlotText([int]$slot, [double]$x0, [double]$x1, [double]$y, [string]$hex, [string]$font, [double]$scale, [string]$align, [string]$mode, [int]$layer) {
    $h = 14
    $offsetY = if ($mode -eq 'top') { PY $y } else { (PY $y) - $h / 2 }
    $anchor = switch ($align) { 'left' { if ($mode -eq 'top') { 'top_left' } else { 'left_middle' } } 'right' { if ($mode -eq 'top') { 'top_right' } else { 'right_middle' } } default { 'center' } }
    Node (Name 't') ([ordered]@{
        type = 'collection_panel'; collection_name = 'container_items'; anchor_from = 'top_left'; anchor_to = 'top_left'
        offset = @((PX $x0), $offsetY); size = @((U ($x1 - $x0 + 1)), $h); layer = $layer
        controls = @(Node 'cell' ([ordered]@{
            type = 'panel'; size = @('100%', '100%'); collection_index = $slot
            controls = @(Node 'label' (LabelBody $hex $font $scale $anchor $align '#text'))
        }))
    })
}

# Un texte ecrit dans le pack (le signe dollar vert).
function StaticText([string]$text, [double]$x0, [double]$y, [string]$hex, [double]$scale, [int]$layer) {
    Node (Name 's') ([ordered]@{
        type = 'panel'; anchor_from = 'top_left'; anchor_to = 'top_left'; offset = @((PX $x0), (PY $y)); size = @(20, 14); layer = $layer
        controls = @(Node 'label' (LabelBody $hex 'default' $scale 'top_left' 'left' $text))
    })
}

function Face([string]$border, [string]$fill, [double]$inset) {
    [ordered]@{
        type = 'image'; texture = $WHITE_TEX; color = (Col $border); size = @('100%', '100%')
        controls = @(Node 'fill' ([ordered]@{ type = 'image'; texture = $WHITE_TEX; color = (Col $fill); size = @("100% - $(2 * $inset)px", "100% - $(2 * $inset)px"); layer = 1 }))
    }
}

function Mappings() {
    , @([ordered]@{ from_button_id = 'button.menu_select'; to_button_id = 'button.drop_all'; mapping_type = 'pressed'; consume_event = $true },
        [ordered]@{ from_button_id = 'button.menu_ok'; to_button_id = 'button.drop_all'; mapping_type = 'pressed'; consume_event = $true })
}

# Un bouton sur la case $slot (un clic est un button.drop_all sur la case), faces donnees.
function SlotButton([int]$slot, $default, $hover, $pressed, $extra) {
    $controls = @((Node 'default' $default), (Node 'hover' $hover), (Node 'pressed' $pressed))
    if ($extra) { $controls += $extra }
    [ordered]@{
        type = 'button'; collection_index = $slot; size = @('100%', '100%')
        default_control = 'default'; hover_control = 'hover'; pressed_control = 'pressed'
        focus_enabled = $true; focus_magnet_enabled = $true; sound_name = 'random.click'; sound_volume = 1.0; sound_pitch = 1.0
        bindings = @([ordered]@{ binding_type = 'collection_details'; binding_collection_name = 'container_items'; binding_condition = 'once' })
        button_mappings = (Mappings)
        controls = $controls
    }
}

function Box([double]$x0, [double]$y0, [double]$x1, [double]$y1, [int]$layer, $controls) {
    Node (Name 'b') ([ordered]@{
        type = 'collection_panel'; collection_name = 'container_items'; anchor_from = 'top_left'; anchor_to = 'top_left'
        offset = @((PX $x0), (PY $y0)); size = @((U ($x1 - $x0 + 1)), (U ($y1 - $y0 + 1))); layer = $layer; controls = $controls
    })
}

# Une zone visible selon le drapeau du texte de la case $slot : $lit vrai quand le texte porte le paragraphe 1.
function Flagged([int]$slot, [bool]$lit, [int]$layer, $controls) {
    $marker = $SECTION + '1'
    $condition = if ($lit) { "(not ((#hover_text - '$marker') = #hover_text))" } else { "((not ((#hover_text) = '')) and ((#hover_text - '$marker') = #hover_text))" }
    Node (Name 'w') ([ordered]@{
        type = 'collection_panel'; collection_name = 'container_items'; anchor_from = 'top_left'; anchor_to = 'top_left'
        offset = @(0, 0); size = @('100%', '100%'); layer = $layer
        controls = @(Node 'cell' ([ordered]@{
            type = 'collection_panel'; size = @('100%', '100%'); collection_index = $slot
            controls = @(Node 'on' ([ordered]@{
                type = 'panel'; size = @('100%', '100%')
                bindings = @(
                    [ordered]@{ binding_type = 'collection'; binding_collection_name = 'container_items'; binding_name = '#hover_text'; binding_name_override = '#hover_text' },
                    [ordered]@{ binding_type = 'view'; source_property_name = $condition; target_property_name = '#visible' })
                controls = $controls
            }))
        }))
    })
}

$W = U 977; $H = U 687
$c = New-Object System.Collections.ArrayList

# Fenetre : bord, bandeau, corps.
[void]$c.Add((Node 'border' ([ordered]@{ type = 'image'; texture = $WHITE_TEX; color = (Col '0C0C13'); anchor_from = 'top_left'; anchor_to = 'top_left'; offset = @(-1.5, -1.5); size = @(($W + 3), ($H + 3)); layer = 1 })))
[void]$c.Add((Rect 17 45 993 123 '27272A' 2))
[void]$c.Add((Rect 17 124 993 731 '18181B' 2))

# Bandeau : titre, solde, bouton Accueil et croix.
[void]$c.Add((SlotText $TITLE 59 500 85 '71717B' 'MinecraftTen' 1.3 'left' 'center' 10))
[void]$c.Add((Rect 516 55 669 114 '101019' 3))
[void]$c.Add((Rect 521 60 664 109 '13131A' 4))
[void]$c.Add((SlotText $BALANCE 521 618 77 'D4D4D8' 'default' 0.8 'right' 'top' 10))
[void]$c.Add((StaticText '$' 627 76 '88F064' 0.8 10))
[void]$c.Add((Rect 850 50 988 118 '18181B' 3))
$homeIcon = Node 'icon' ([ordered]@{ type = 'image'; texture = 'textures/ui/icon/icon_06'; color = (Col '27272A'); size = @(7, 7); layer = 3 })
[void]$c.Add((Box 855 55 913 114 6 @(Node 'button' (SlotButton $HUB (Face '787882' '71717B' 1.67) (Face '787882' '787882' 1.67) (Face '787882' '787882' 1.67) $homeIcon))))
[void]$c.Add((Node 'close@common.button' ([ordered]@{
    '$pressed_button_name' = 'button.menu_exit'
    anchor_from = 'top_left'; anchor_to = 'top_left'; offset = @((PX 924), (PY 55)); size = @((U 60), (U 60)); layer = 6
    controls = @((Node 'default' (Face '494950' '3F3F47' 1.67)), (Node 'hover' (Face '494950' '494950' 1.67)), (Node 'pressed' (Face '494950' '494950' 1.67)),
                 (Node 'icon' ([ordered]@{ type = 'image'; texture = 'textures/ui/icon/icon_01'; color = (Col '71717B'); size = @(8, 8); layer = 3 })))
})))

# Temps de jeu.
[void]$c.Add((Rect 57 164 953 353 '101019' 3))
[void]$c.Add((Rect 62 169 948 348 '09090B' 4))
[void]$c.Add((SlotText $PLAYTIME_LABEL 97 600 207 '71717B' 'default' 0.75 'left' 'top' 10))
[void]$c.Add((SlotText $PLAYTIME 101 940 275 'FAFAFA' 'MinecraftTen' 2.6 'left' 'center' 10))

# Carte ARGENT.
[void]$c.Add((Rect 57 394 495 692 '323235' 3))
[void]$c.Add((Rect 62 399 490 687 '27272A' 4))
[void]$c.Add((SlotText $MONEY_LABEL 103 300 443.5 'FAFAFA' 'MinecraftTen' 0.72 'left' 'center' 10))
[void]$c.Add((SlotText $MONEY_RATE 300 421 438 '71717B' 'default' 0.55 'right' 'top' 10))
[void]$c.Add((Node 'grade' ([ordered]@{ type = 'image'; texture = 'textures/ui/convertisseur/grade'; anchor_from = 'top_left'; anchor_to = 'top_left'; offset = @((PX 431), (PY 433)); size = @((U 19), (U 19)); layer = 10 })))
[void]$c.Add((Rect 97 468 455 472 '3F3F47' 5))
[void]$c.Add((StaticText '$' 104 500 '88F064' 1.2 10))
[void]$c.Add((SlotText $MONEY_AMOUNT 134 480 502 'FAFAFA' 'default' 1.2 'left' 'top' 10))

# Bouton Retirer l'argent : actif (paragraphe 1 au debut du texte de sa case) ou eteint, comme celui de l'XP.
$clear = [ordered]@{ type = 'panel'; size = @('100%', '100%') }
$lighter = [ordered]@{ type = 'image'; texture = $WHITE_TEX; color = @(1, 1, 1); alpha = 0.08; size = @('100%', '100%') }
$darker = [ordered]@{ type = 'image'; texture = $WHITE_TEX; color = @(0, 0, 0); alpha = 0.12; size = @('100%', '100%') }
$moneyClick = Node 'button' (SlotButton $MONEY_BUTTON $clear $lighter $darker $null)
$moneyOn = @(
    (Rect 77 593 475 672 '191922' 1),
    (Rect 82 598 470 667 '787882' 2),
    (Rect 87 603 465 662 '71717B' 3),
    (Box 77 593 475 672 4 @($moneyClick)),
    (SlotText $MONEY_BUTTON_TEXT 77 475 632.5 'D4D4D8' 'default' 0.75 'center' 'center' 5))
[void]$c.Add((Flagged $MONEY_BUTTON_TEXT $true 20 $moneyOn))
$moneyOff = @(
    (Rect 77 593 475 672 '27272A' 1),
    (Rect 82 598 470 667 '18181B' 2),
    (SlotText $MONEY_BUTTON_TEXT 77 475 632.5 '3F3F47' 'default' 0.75 'center' 'center' 5))
[void]$c.Add((Flagged $MONEY_BUTTON_TEXT $false 20 $moneyOff))

# Carte XP PASSE.
[void]$c.Add((Rect 516 394 953 692 '3F3F47' 3))
[void]$c.Add((Rect 521 399 948 687 '18181B' 4))
[void]$c.Add((SlotText $XP_LABEL 562 900 448.5 '71717B' 'MinecraftTen' 0.72 'left' 'center' 10))
[void]$c.Add((Rect 556 473 913 477 '27272A' 5))
[void]$c.Add((SlotText $XP_NONE 561 940 506 '71717B' 'default' 0.85 'left' 'top' 10))
[void]$c.Add((Rect 536 593 933 672 '27272A' 6))
[void]$c.Add((Rect 541 598 928 667 '18181B' 7))
[void]$c.Add((SlotText $XP_BUTTON_TEXT 536 933 632.5 '3F3F47' 'default' 0.75 'center' 'center' 10))

$root = [ordered]@{
    namespace = 'ng_convertisseur'
    main_panel = [ordered]@{
        type = 'panel'; size = @('100%', '100%'); anchor_from = 'center'; anchor_to = 'center'
        controls = @(
            (Node 'veil' ([ordered]@{ type = 'image'; texture = $WHITE_TEX; color = @(0.051, 0.051, 0.071); alpha = 0.8; size = @(4096, 4096); layer = 1 })),
            (Node 'stage' ([ordered]@{ type = 'panel'; size = @($W, $H); anchor_from = 'center'; anchor_to = 'center'; offset = @(0, 0); layer = 2; controls = $c.ToArray() })))
    }
}

$header = @(
    "// Convertisseur (/atm et /afk), conteneur premium:converter_ui ouvert par PremiumMod (Ui/ConverterUi.cs). Fichier produit",
    "// par tools/convertisseur/gen_convertisseur.ps1 : chaque texte vient du serveur, dans la case indiquee par",
    "// collection_index (Ui/ConverterSlots.cs). Le bouton Retirer l'argent est actif quand le texte de sa case commence",
    "// par le drapeau paragraphe 1. Seuls les deux signes dollar verts et l'icone du taux sont dans le pack.")
# Compact (l'indentation de Windows PowerShell triple la taille), une commande de premier niveau par ligne ; les
# apostrophes et le paragraphe remis en clair, comme dans les autres fichiers du pack.
$json = $root | ConvertTo-Json -Depth 100 -Compress
$escape = [string][char]92 + 'u'
foreach ($pair in @(@('0027', "'"), @('00a7', $SECTION), @('003c', '<'), @('003e', '>'), @('0026', '&'))) {
    $json = $json.Replace($escape + $pair[0], $pair[1])
}
$json = $json.Replace('[{"border"', "[`n{" + '"border"')
foreach ($prefix in @('r_', 't_', 's_', 'b_', 'w_', 'close', 'grade')) {
    $json = $json.Replace('},{"' + $prefix, "},`n{" + '"' + $prefix)
}
$out = Join-Path $Pack 'ui\Interface\convertisseur.json'
[IO.File]::WriteAllText($out, (($header -join "`n") + "`n" + $json + "`n"), (New-Object Text.UTF8Encoding $false))
Write-Host "Ecrit : $out"
