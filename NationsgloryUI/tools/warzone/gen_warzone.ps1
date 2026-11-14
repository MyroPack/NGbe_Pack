# Ecrit ui/Interface/warzone.json : l'ecran de la warzone (/warzone), conteneur ng:warzone de NGCountryMod
# (NGCountryMod/Warzone/WarzoneUi.cs, cases dans NGCountryMod/Warzone/WarzoneSlots.cs).
#
#   powershell -ExecutionPolicy Bypass -File tools\warzone\gen_warzone.ps1
#
# Contenu et disposition de l'ecran warzone de NationsGlory Java : une zone en grand a gauche (image, pays qui la
# tient, description, bouton S'Y TELEPORTER), les deux autres dessous (description, pays, bouton fleche), a droite la
# carte du pays du joueur (drapeau, nom, rang, pastilles argent, power et skill) puis le classement des pays a onglets
# JOURNALIER et HEBDOMADAIRE (10 lignes : rang, drapeau, nom, score). Dans le bandeau, entre le titre et les boutons
# Accueil et croix, la ligue du pays du joueur (icone et nom) et l'etat du keep inventory de la warzone.
#
# Les cases des zones sont trois emplacements (grand, petit gauche, petit droit) que le serveur remplit selon l'ordre
# courant (bateau en grand a l'ouverture) : un clic sur une petite carte (toute la carte ou sa fleche) met sa zone en
# grand et la zone du grand a sa place ; S'Y TELEPORTER envoie vers la zone en grand. L'image du grand suit sa zone,
# lue dans le marqueur du titre de l'emplacement.
#
# Habillage des ecrans NG et memes formes de liaison que le Punisher (tools/punisher/gen_punisher_ng.py, dont les
# fonctions image, text, cell, label_cell, click, grey_button et window sont reprises telles quelles) : texte d'une case
# lu dans #hover_text, zone cachee quand sa case est vide (de l'air), marqueur cherche par retrait d'une sous-chaine,
# clic par button.drop_all. Les drapeaux sont les glyphes du tchat (page de police glyph_E8.png de
# NGPremiumResourcePack), ecrits par le serveur dans le texte de leur case et dessines dans la police par defaut.
#
# En PowerShell (Windows PowerShell 5.1 suffit, pas de Python sur les postes de dev) ; meme sortie que les scripts
# Python du pack : les commentaires d'en-tete, puis le JSON sur une ligne, sans echappement des caracteres non ASCII.
# Script en ASCII (PowerShell 5.1 lit en ANSI un script sans BOM) : le paragraphe des codes de formatage est [char]0xA7.
param([string]$Pack = (Join-Path $PSScriptRoot '..\..'))

$ErrorActionPreference = 'Stop'
$S = [string][char]0xA7

# ---------------------------------------------------------------- cases (NGCountryMod/Warzone/WarzoneSlots.cs)

$TITLE, $TAB_DAILY, $TAB_WEEKLY = 10, 11, 12
# Les emplacements des zones : 6 cases chacun, grand (13 a 18), petit gauche (19 a 24), petit droit (25 a 30).
$PLACE_FIRST, $PLACE_SLOTS = 13, 6
$P_TITLE, $P_TEXT, $P_FLAG, $P_HOLDER, $P_CONTROL, $P_BUTTON = 0, 1, 2, 3, 4, 5
$BIG, $LEFT, $RIGHT = 0, 1, 2
# La carte du pays du joueur.
$COUNTRY_FLAG, $COUNTRY_NAME, $COUNTRY_RANK, $COUNTRY_MONEY, $COUNTRY_POWER, $COUNTRY_SKILL = 31, 32, 33, 34, 35, 36
$RANKING_EMPTY = 37
# Le classement : 10 lignes de 4 cases (38 a 77).
$ROW_FIRST, $ROW_COUNT, $ROW_SLOTS = 38, 10, 4
$R_RANK, $R_FLAG, $R_NAME, $R_SCORE = 0, 1, 2, 3
# Le bandeau, ajoute apres les autres cases : nom de la ligue, chemin de son icone (apres 90 octets), keep inventory.
$LEAGUE_NAME, $LEAGUE_ICON, $KEEP_INVENTORY = 78, 79, 80
$LAST = 80

function Place([int]$p, [int]$part) { $PLACE_FIRST + $p * $PLACE_SLOTS + $part }
function Row([int]$i, [int]$part) { $ROW_FIRST + $i * $ROW_SLOTS + $part }

if ((Place $RIGHT $P_BUTTON) + 1 -ne $COUNTRY_FLAG -or $RANKING_EMPTY + 1 -ne $ROW_FIRST -or
    (Row ($ROW_COUNT - 1) $R_SCORE) + 1 -ne $LEAGUE_NAME -or $KEEP_INVENTORY -ne $LAST -or $LAST -ge 200) {
    throw 'cases incoherentes avec WarzoneSlots.cs'
}

# Marqueurs (paragraphe, code, paragraphe r) : $OFF l'onglet montre, la zone sans pays et le keep inventory eteint ; $ON
# l'onglet cliquable, la ligne du pays du joueur et le keep inventory allume.
$OFF = $S + '0' + $S + 'r'
$ON = $S + '1' + $S + 'r'

# Le marqueur de chaque zone dans le titre de son emplacement (WarzoneSlots.ZoneMarker) et son image dans le grand : son
# chemin (sans .png) quand elle sera dans le pack (textures/ui/warzone/), sinon une icone du pack (epees croisees pour le
# bateau, chevalet de pompage pour le petrole, montagne pour la mine). Pour mettre une image : son chemin ici, puis
# relancer le script.
$ZONES = @(
    [ordered]@{ name = 'boat'; marker = ($S + '4' + $S + 'r'); picture = ''; icon = 'textures/ui/icon/icon_14' },
    [ordered]@{ name = 'oil'; marker = ($S + '5' + $S + 'r'); picture = ''; icon = 'textures/ui/icon/icon_31' },
    [ordered]@{ name = 'mine'; marker = ($S + '6' + $S + 'r'); picture = ''; icon = 'textures/ui/icon/icon_23' })

# ---------------------------------------------------------------- palette (celle du Punisher)

$WHITE = @(0.98, 0.98, 0.98)
$GREY_TEXT = @(0.631, 0.631, 0.667)
$BORDER = @(0.094, 0.094, 0.106)
$PANEL = @(0.122, 0.122, 0.133)
$HEADER = @(0.153, 0.153, 0.165)
$LINE = @(0.247, 0.247, 0.275)
$ROSE = @(1.0, 0.122, 0.424)
$OUTLINE = @(0.443, 0.443, 0.482)
$BUTTON = @(0.322, 0.322, 0.361)
$PURE = @(1, 1, 1)
# Le keep inventory : vert allume, rouge eteint (green-600 et red-600, texte blanc lisible dessus).
$GREEN = @(0.086, 0.639, 0.29)
$RED = @(0.863, 0.149, 0.149)

# Fenetre de 420 x 236, comme l'ecran de la lootbox.
$WIDTH, $HEIGHT = 420, 236

# ---------------------------------------------------------------- JSON (comme json.dumps(separators=(",", ":"), ensure_ascii=False))

function Quote([string]$value) {
    $b = New-Object System.Text.StringBuilder
    [void]$b.Append('"')
    foreach ($c in $value.ToCharArray()) {
        $code = [int]$c
        if ($code -eq 0x22) { [void]$b.Append('\"') }
        elseif ($code -eq 0x5C) { [void]$b.Append('\\') }
        elseif ($code -eq 0x0A) { [void]$b.Append('\n') }
        elseif ($code -eq 0x0D) { [void]$b.Append('\r') }
        elseif ($code -eq 0x09) { [void]$b.Append('\t') }
        elseif ($code -lt 0x20) { [void]$b.Append(('\u{0:x4}' -f $code)) }
        else { [void]$b.Append($c) }
    }
    [void]$b.Append('"')
    $b.ToString()
}

function Json($v) {
    $invariant = [Globalization.CultureInfo]::InvariantCulture
    if ($null -eq $v) { return 'null' }
    if ($v -is [string]) { return Quote $v }
    if ($v -is [bool]) { if ($v) { return 'true' } else { return 'false' } }
    if ($v -is [int] -or $v -is [long]) { return $v.ToString($invariant) }
    if ($v -is [double] -or $v -is [decimal] -or $v -is [single]) { return ([double]$v).ToString('R', $invariant) }
    if ($v -is [System.Collections.IDictionary]) {
        $parts = foreach ($k in $v.Keys) { (Quote ([string]$k)) + ':' + (Json $v[$k]) }
        return '{' + ($parts -join ',') + '}'
    }
    if ($v -is [System.Collections.IEnumerable]) {
        $parts = foreach ($e in $v) { Json $e }
        return '[' + ($parts -join ',') + ']'
    }
    throw ('valeur inattendue : ' + $v.GetType())
}

# Un controle nomme : { "nom": corps }.
function Node([string]$name, $body) { $o = [ordered]@{}; $o[$name] = $body; $o }

# ---------------------------------------------------------------- formes du Punisher (tools/punisher/gen_punisher_ng.py)

function Filled { "(not((#hover_text) = ''))" }
function Has([string]$marker) { "(not ((#hover_text - '{0}') = #hover_text))" -f $marker }
function Lacks([string]$marker) { "((#hover_text - '{0}') = #hover_text)" -f $marker }
function Both([string]$first, [string]$second) { '({0} and {1})' -f $first, $second }

function VisibleBy([string]$condition) {
    , @(
        [ordered]@{ binding_name = '#hover_text'; binding_type = 'collection'; binding_collection_name = 'container_items' },
        [ordered]@{ binding_type = 'view'; source_property_name = $condition; target_property_name = '#visible' })
}

function Image($color, $size, $offset = @(0, 0), [int]$layer = 1, [string]$anchor = 'top_left',
               [string]$texture = 'textures/ui/background/background_white', $extra = $null) {
    $node = [ordered]@{ type = 'image'; texture = $texture; color = $color; anchor_from = $anchor; anchor_to = $anchor
                        offset = $offset; size = $size; layer = $layer }
    if ($null -ne $extra) { foreach ($k in $extra.Keys) { $node[$k] = $extra[$k] } }
    $node
}

# Le texte de la case de l'ancetre le plus proche qui porte un collection_index.
function Text([double]$scale, $color = $WHITE, $size = @('100%', 'default'), [string]$anchor = 'top_left', [string]$align = 'left',
              [string]$font = 'default', $offset = @(0, 0), [int]$layer = 4) {
    [ordered]@{ type = 'label'; text = '#text'; size = $size; anchor_from = $anchor; anchor_to = $anchor; offset = $offset
                text_alignment = $align; color = $color; font_scale_factor = $scale; font_type = $font; shadow = $false
                localize = $false; layer = $layer
                bindings = @([ordered]@{ binding_type = 'collection'; binding_collection_name = 'container_items'
                                         binding_name = '#hover_text'; binding_name_override = '#text' }) }
}

# Une zone liee a la case slot, visible selon condition ; clip : le texte est coupe au bord de la zone.
function Cell([int]$slot, $size, $offset = @(0, 0), [int]$layer = 1, [string]$condition = '', $controls = @(),
              [string]$anchor = 'top_left', [switch]$clip) {
    $inner = [ordered]@{ type = 'panel'; size = @('100%', '100%'); controls = @($controls) }
    if ($clip) { $inner['clips_children'] = $true }
    if ($condition) {
        $inner['bindings'] = @(
            [ordered]@{ binding_type = 'collection'; binding_collection_name = 'container_items'; binding_name = '#hover_text'
                        binding_name_override = '#hover_text' },
            [ordered]@{ binding_type = 'view'; source_property_name = $condition; target_property_name = '#visible' })
    }
    [ordered]@{ type = 'collection_panel'; collection_name = 'container_items'; anchor_from = $anchor; anchor_to = $anchor
                offset = $offset; size = $size; layer = $layer
                controls = @((Node 'cell' ([ordered]@{ type = 'collection_panel'; size = @('100%', '100%'); collection_index = $slot
                                                       controls = @((Node 'on' $inner)) }))) }
}

function LabelCell([int]$slot, $size, $offset, [double]$scale, $color = $WHITE, [string]$align = 'left', [string]$font = 'default',
                   [int]$layer = 2, [string]$anchor = 'top_left', [string]$labelAnchor = 'top_left') {
    Cell -slot $slot -size $size -offset $offset -layer $layer -condition (Filled) -anchor $anchor -controls @(
        (Node 'label' (Text $scale $color -anchor $labelAnchor -align $align -font $font)))
}

# Le bouton d'une case : un clic est un button.drop_all sur la case.
function Face($color) {
    if ($null -eq $color) { [ordered]@{ type = 'panel'; size = @('100%', '100%') } }
    else { Image -color $color -size @('100%', '100%') }
}

function Click([int]$slot, $default, $hover, $pressed = $null) {
    if ($null -eq $pressed) { $pressed = $hover }
    [ordered]@{ type = 'button'; collection_index = $slot; size = @('100%', '100%'); default_control = 'default'
                hover_control = 'hover'; pressed_control = 'pressed'; focus_enabled = $true; focus_magnet_enabled = $true
                sound_name = 'random.click'; sound_volume = 1.0; sound_pitch = 1.0
                bindings = @([ordered]@{ binding_type = 'collection_details'; binding_collection_name = 'container_items'
                                         binding_condition = 'once' })
                button_mappings = @(
                    [ordered]@{ from_button_id = 'button.menu_select'; to_button_id = 'button.drop_all'; mapping_type = 'pressed'
                                consume_event = $true },
                    [ordered]@{ from_button_id = 'button.menu_ok'; to_button_id = 'button.drop_all'; mapping_type = 'pressed'
                                consume_event = $true })
                controls = @((Node 'default' (Face $default)), (Node 'hover' (Face $hover)), (Node 'pressed' (Face $pressed))) }
}

# Un bouton gris (S'Y TELEPORTER) : fond 52525C, survol 71717B, texte blanc centre.
function GreyButton([int]$slot, $size, $offset, [string]$anchor = 'top_left') {
    Cell -slot $slot -size $size -offset $offset -layer 3 -condition (Filled) -anchor $anchor -controls @(
        (Node 'button' (Click $slot $BUTTON $OUTLINE)),
        (Node 'label' (Text 0.65 $WHITE -size @('default', 'default') -anchor 'center' -align 'center' -layer 6)))
}

function Window([int]$width, [int]$height, $controls) {
    $inner = Image -color $PANEL -size @('100% - 2px', '100% - 2px') -anchor 'center' -extra ([ordered]@{ controls = @($controls) })
    [ordered]@{ type = 'panel'; size = @('100%', '100%'); controls = @(
        (Node 'bounds' (Image -color $BORDER -size @($width, $height) -anchor 'center' -extra ([ordered]@{ controls = @((Node 'inner' $inner)) })))) }
}

function CloseButton($offset) {
    Node 'close@ng_module.close_button' ([ordered]@{ anchor_from = 'top_right'; anchor_to = 'top_right'; offset = $offset; layer = 8 })
}

# Le bouton Home avant la croix : la case 1 (le hub de PalaUiMod), que NGCountryMod fait ouvrir le telephone (/app).
function HomeButton($offset) {
    Node 'home@ng_module.home_button' ([ordered]@{ anchor_from = 'top_right'; anchor_to = 'top_right'; offset = $offset; layer = 8 })
}

# ---------------------------------------------------------------- warzone

# Une carte : bordure fine LINE autour d'un fond gris.
function Card($size, $offset, $controls, $fill = $HEADER) {
    $inner = Image -color $fill -size @('100% - 2px', '100% - 2px') -anchor 'center' -extra ([ordered]@{ controls = @($controls) })
    Image -color $LINE -size $size -offset $offset -layer 1 -extra ([ordered]@{ controls = @((Node 'inner' $inner)) })
}

# Le cadre du drapeau d'un pays (gris et vide sans drapeau) et le glyphe du drapeau, centre, dans la police par defaut.
function FlagBox([int]$slot, $size, $offset, [double]$scale, [int]$layer = 3) {
    Image -color $LINE -size $size -offset $offset -layer $layer -extra ([ordered]@{ controls = @(
        (Node 'glyph' (Cell -slot $slot -size @('100%', '100%') -layer 1 -condition (Filled) -controls @(
            (Node 'label' (Text $scale $PURE -size @('default', 'default') -anchor 'center' -align 'center')))))) })
}

# Le pays qui tient la zone d'un emplacement : son drapeau, son nom, puis "30% - depuis 39m" en gris. Sans pays
# (marqueur $OFF) : "Aucun pays" en gris au milieu, le cadre du drapeau vide.
function Holder([int]$p, [int]$width, [int]$height, $offset, [string]$anchor = 'top_left') {
    $textWidth = $width - 34
    $half = [int][Math]::Floor($height / 2)
    Image -color $BORDER -size @($width, $height) -offset $offset -layer 2 -anchor $anchor -extra ([ordered]@{ controls = @(
        (Node 'flag' (FlagBox (Place $p $P_FLAG) @(24, 14) @(3, [int][Math]::Floor(($height - 14) / 2)) 1.0)),
        (Node 'name' (Cell -slot (Place $p $P_HOLDER) -size @($textWidth, 9) -offset @(31, ($half - 8)) -layer 3 `
            -condition (Both (Filled) (Lacks $OFF)) -clip -controls @(
            (Node 'label' (Text 0.65 $WHITE -size @('default', 'default')))))),
        (Node 'free' (Cell -slot (Place $p $P_HOLDER) -size @($textWidth, $height) -offset @(31, 0) -layer 3 `
            -condition (Has $OFF) -clip -controls @(
            (Node 'label' (Text 0.6 $GREY_TEXT -size @('default', 'default') -anchor 'left_middle'))))),
        (Node 'control' (Cell -slot (Place $p $P_CONTROL) -size @($textWidth, 7) -offset @(31, ($half + 1)) -layer 3 `
            -condition (Filled) -clip -controls @(
            (Node 'label' (Text 0.5 $GREY_TEXT -size @('default', 'default'))))))) })
}

# Le bouton fleche des petites cartes : le meme bouton gris, l'icone de la fleche a la place du texte.
function ArrowButton([int]$slot, $size, $offset, [string]$anchor = 'top_left') {
    Cell -slot $slot -size $size -offset $offset -layer 3 -condition (Filled) -anchor $anchor -controls @(
        (Node 'button' (Click $slot $BUTTON $OUTLINE)),
        (Node 'icon' (Image -color $WHITE -size @(10, 10) -anchor 'center' -layer 6 -texture 'textures/ui/icon/icon_13')))
}

# Le grand emplacement : l'image de sa zone a gauche (celle dont le marqueur est dans le titre de l'emplacement), puis
# le titre, le pays qui tient la zone, la description et S'Y TELEPORTER (vers la zone en grand).
function BigCard() {
    $pictures = foreach ($zone in $ZONES) {
        $shown = [ordered]@{ bindings = (VisibleBy (Has $zone.marker)) }
        if ($zone.picture) { $image = Image -color $PURE -size @('100%', '100%') -texture $zone.picture -extra $shown }
        else { $image = Image -color $OUTLINE -size @(40, 40) -anchor 'center' -texture $zone.icon -extra $shown }
        Node ('picture_' + $zone.name) $image
    }
    $picture = Image -color $BORDER -size @(92, '100%') -extra ([ordered]@{ controls = @(
        (Node 'zone' (Cell -slot (Place $BIG $P_TITLE) -size @('100%', '100%') -layer 1 -condition (Filled) -controls @($pictures)))) })
    Card @(276, 112) @(6, 31) @(
        (Node 'picture' $picture),
        (Node 'title' (LabelCell (Place $BIG $P_TITLE) @(164, 10) @(102, 9) 1.0 -font 'MinecraftTen')),
        (Node 'holder' (Holder $BIG 164 22 @(102, 23))),
        (Node 'text' (LabelCell (Place $BIG $P_TEXT) @(164, 28) @(102, 51) 0.55 $GREY_TEXT)),
        (Node 'teleport' (GreyButton (Place $BIG $P_BUTTON) @(84, 15) @(102, -8) 'bottom_left')))
}

# Un petit emplacement : titre, description, bouton fleche a droite, pays qui tient la zone en bas. Toute la carte est
# aussi un bouton de la meme case (fond plus clair au survol, sous les textes) : un clic, sur la carte ou sur sa
# fleche, met sa zone en grand.
function SmallCard([int]$p, $offset) {
    # Pas de variable locale du nom d'une constante ($BUTTON...) : PowerShell ignore la casse et les fonctions appelees
    # verraient la locale a sa place.
    $swapSlot = Place $p $P_BUTTON
    Card @(135, 80) $offset @(
        (Node 'swap' (Cell -slot $swapSlot -size @('100%', '100%') -layer 1 -condition (Filled) -controls @(
            (Node 'button' (Click $swapSlot $null $LINE))))),
        (Node 'title' (LabelCell (Place $p $P_TITLE) @(100, 9) @(6, 6) 0.85 -font 'MinecraftTen')),
        (Node 'text' (LabelCell (Place $p $P_TEXT) @(100, 30) @(6, 18) 0.5 $GREY_TEXT)),
        (Node 'go' (ArrowButton $swapSlot @(18, 18) @(-6, 17) 'top_right')),
        (Node 'holder' (Holder $p 121 20 @(6, -6) 'bottom_left')))
}

# La ligue du pays du joueur, dans le bandeau : son icone (chemin lu apres les 90 premiers octets de la case 79 par
# ng_module.icone, comme la ligue de l'onglet Menu du menu de pays, case 40 de pays_general.json) puis son nom.
function LeaguePill($offset) {
    $name = [ordered]@{ type = 'panel'; size = @(56, 12); anchor_from = 'left_middle'; anchor_to = 'left_middle'; offset = @(16, 0)
                        clips_children = $true; layer = 3
                        controls = @((Node 'label' (Text 0.5 $WHITE -size @('default', 'default') -anchor 'left_middle'))) }
    Cell -slot $LEAGUE_NAME -size @(76, 14) -offset $offset -layer 3 -anchor 'top_right' -condition (Filled) -controls @(
        (Node 'border' (Image -color $OUTLINE -size @('100%', '100%') -layer 1)),
        (Node 'fill' (Image -color $PANEL -size @('100% - 2px', '100% - 2px') -anchor 'center' -layer 2)),
        (Node 'icon@ng_module.icone' ([ordered]@{ '$index' = $LEAGUE_ICON; '$Get_text_type' = 'Get_text_type_2'
                                                  anchor_from = 'left_middle'; anchor_to = 'left_middle'; offset = @(3, 0)
                                                  size = @(10, 10); layer = 3 })),
        (Node 'name' $name))
}

# Le keep inventory de la warzone, dans le bandeau : vert quand il est allume ($ON), rouge quand il est eteint.
function KeepInventoryPill($offset) {
    $pillOn = Cell -slot $KEEP_INVENTORY -size @(104, 14) -offset $offset -layer 3 -anchor 'top_right' -condition (Has $ON) -clip -controls @(
        (Node 'fill' (Image -color $GREEN -size @('100%', '100%') -layer 1)),
        (Node 'label' (Text 0.5 $PURE -size @('default', 'default') -anchor 'center' -align 'center' -layer 2)))
    $pillOff = Cell -slot $KEEP_INVENTORY -size @(104, 14) -offset $offset -layer 3 -anchor 'top_right' `
        -condition (Both (Filled) (Lacks $ON)) -clip -controls @(
        (Node 'fill' (Image -color $RED -size @('100%', '100%') -layer 1)),
        (Node 'label' (Text 0.5 $PURE -size @('default', 'default') -anchor 'center' -align 'center' -layer 2)))
    # Deux controles, rendus un par un : @(KeepInventoryPill ...) en fait une liste de deux.
    (Node 'keep_inventory_on' $pillOn)
    (Node 'keep_inventory_off' $pillOff)
}

# Une pastille de la carte du pays : rose pleine (l'argent, comme le palier du Punisher) ou cerclee de gris (power et
# skill, comme ses points).
function Pill([int]$slot, $offset, $fill) {
    if ($null -eq $fill) {
        $back = @((Node 'border' (Image -color $OUTLINE -size @('100%', '100%') -layer 1)),
                  (Node 'fill' (Image -color $PANEL -size @('100% - 2px', '100% - 2px') -anchor 'center' -layer 2)))
    } else {
        $back = @((Node 'fill' (Image -color $fill -size @('100%', '100%') -layer 1)))
    }
    Cell -slot $slot -size @(36, 12) -offset $offset -layer 2 -condition (Filled) -clip -controls ($back + @(
        (Node 'label' (Text 0.45 $PURE -size @('default', 'default') -anchor 'center' -align 'center' -layer 3))))
}

# La carte du pays du joueur : drapeau, nom, rang dans le classement de l'onglet montre, puis argent, power et skill.
function CountryCard() {
    Card @(124, 50) @(288, 31) @(
        (Node 'flag' (FlagBox $COUNTRY_FLAG @(32, 18) @(5, 5) 1.35)),
        (Node 'name' (Cell -slot $COUNTRY_NAME -size @(75, 9) -offset @(42, 5) -layer 2 -condition (Filled) -clip -controls @(
            (Node 'label' (Text 0.75 $WHITE -size @('default', 'default')))))),
        (Node 'rank' (LabelCell $COUNTRY_RANK @(75, 7) @(42, 16) 0.5 $GREY_TEXT)),
        (Node 'money' (Pill $COUNTRY_MONEY @(5, 31) $ROSE)),
        (Node 'power' (Pill $COUNTRY_POWER @(43, 31) $null)),
        (Node 'skill' (Pill $COUNTRY_SKILL @(81, 31) $null)))
}

# Un onglet du classement : montre ($OFF) texte blanc souligne, sans clic ; sinon un bouton sombre, texte gris.
function Tab([int]$slot, $offset) {
    $shown = Cell -slot $slot -size @(61, 15) -offset $offset -layer 3 -condition (Has $OFF) -controls @(
        (Node 'label' (Text 0.55 $WHITE -size @('default', 'default') -anchor 'center' -align 'center' -layer 5)),
        (Node 'underline' (Image -color $WHITE -size @('100% - 24px', 1) -offset @(0, -1) -layer 5 -anchor 'bottom_middle')))
    $other = Cell -slot $slot -size @(61, 15) -offset $offset -layer 3 -condition (Both (Filled) (Lacks $OFF)) -controls @(
        (Node 'button' (Click $slot $PANEL $LINE)),
        (Node 'label' (Text 0.55 $GREY_TEXT -size @('default', 'default') -anchor 'center' -align 'center' -layer 6)))
    # Deux controles, rendus un par un : @(Tab ...) en fait une liste de deux.
    (Node ('tab_{0}_shown' -f $slot) $shown)
    (Node ('tab_{0}' -f $slot) $other)
}

# Une ligne du classement : rang, drapeau, nom, score. Visible quand la case du nom est remplie, sur fond clair pour le
# pays du joueur (marqueur $ON dans le nom).
function RankingRow([int]$i) {
    $name = [ordered]@{ type = 'panel'; size = @(48, 12); anchor_from = 'top_left'; anchor_to = 'top_left'; offset = @(32, 0)
                        clips_children = $true; layer = 2
                        controls = @((Node 'label' (Text 0.6 $WHITE -size @('default', 'default') -anchor 'left_middle'))) }
    Node ('row_{0}' -f $i) (Cell -slot (Row $i $R_NAME) -size @('100%', 12) -offset @(0, (12 * $i)) -layer 3 -condition (Filled) -controls @(
        (Node 'own' (Image -color $LINE -size @('100%', '100%') -layer 1 -extra ([ordered]@{ bindings = (VisibleBy (Has $ON)) }))),
        (Node 'rank' (Cell -slot (Row $i $R_RANK) -size @(12, 12) -layer 2 -condition (Filled) -controls @(
            (Node 'label' (Text 0.6 $GREY_TEXT -size @('default', 'default') -anchor 'right_middle' -align 'right'))))),
        (Node 'flag' (Cell -slot (Row $i $R_FLAG) -size @(15, 12) -offset @(15, 0) -layer 2 -condition (Filled) -controls @(
            (Node 'label' (Text 0.6 $PURE -size @('default', 'default') -anchor 'left_middle'))))),
        (Node 'name' $name),
        (Node 'score' (Cell -slot (Row $i $R_SCORE) -size @(32, 12) -layer 2 -condition (Filled) -anchor 'top_right' -controls @(
            (Node 'label' (Text 0.6 $WHITE -size @('default', 'default') -anchor 'right_middle' -align 'right')))))))
}

# Le classement : les deux onglets, puis 10 lignes de 12 ou "Aucun classement pour le moment".
function RankingCard() {
    $rows = [ordered]@{ type = 'panel'; size = @('100% - 8px', (12 * $ROW_COUNT)); anchor_from = 'top_left'; anchor_to = 'top_left'
                        offset = @(4, 18); layer = 2; controls = @(0..($ROW_COUNT - 1) | ForEach-Object { RankingRow $_ }) }
    Card @(124, 142) @(288, 86) (@(Tab $TAB_DAILY @(0, 0)) + @(Tab $TAB_WEEKLY @(61, 0)) + @(
        (Node 'line' (Image -color $LINE -size @('100%', 1) -offset @(0, 15) -layer 2)),
        (Node 'rows' $rows),
        (Node 'empty' (LabelCell $RANKING_EMPTY @('100% - 16px', 24) @(8, 60) 0.55 $GREY_TEXT -align 'center'))))
}

function Build() {
    # Le bandeau : titre a gauche ; ligue, keep inventory, Accueil et croix a droite.
    $banner = @((Node 'title' (LabelCell $TITLE @(120, 12) @(10, 7) 1.2 -font 'MinecraftTen')),
                (Node 'league' (LeaguePill @(-150, 5)))) + @(KeepInventoryPill @(-42, 5)) + @((HomeButton @(-22, 4)), (CloseButton @(-4, 4)))
    $top = Image -color $HEADER -size @('100%', 24) -layer 1 -extra ([ordered]@{ controls = $banner })
    [ordered]@{ namespace = 'ng_warzone'; main_panel = (Window $WIDTH $HEIGHT @(
        (Node 'header' $top),
        (Node 'line' (Image -color $LINE -size @('100%', 1) -offset @(0, 24) -layer 2)),
        (Node 'big' (BigCard)),
        (Node 'left' (SmallCard $LEFT @(6, 148))),
        (Node 'right' (SmallCard $RIGHT @(147, 148))),
        (Node 'country' (CountryCard)),
        (Node 'ranking' (RankingCard)))) }
}

$head = @(
    "// Ecran de la warzone (/warzone), conteneur ng:warzone de NGCountryMod (NGCountryMod/Warzone/WarzoneUi.cs) : contenu",
    "// et disposition de l'ecran warzone de NationsGlory Java, habillage des ecrans NG. Fichier produit par",
    "// tools/warzone/gen_warzone.ps1 (powershell -ExecutionPolicy Bypass -File tools\warzone\gen_warzone.ps1) : chaque texte",
    "// vient du serveur, dans la case indiquee par collection_index (NGCountryMod/Warzone/WarzoneSlots.cs). Case 10 le titre,",
    "// 11 et 12 les onglets JOURNALIER et HEBDOMADAIRE (${OFF} l'onglet montre, ${ON} l'autre). 13 a 30 les trois emplacements des",
    "// zones, grand (13 a 18), petit gauche (19 a 24) et petit droit (25 a 30), 6 cases chacun : titre (marqueur de la zone,",
    "// $($ZONES[0].marker) bateau, $($ZONES[1].marker) petrole, $($ZONES[2].marker) mine : l'image du grand), description, drapeau, pays (${OFF} : aucun pays),",
    "// controle (30% - depuis 39m), bouton (S'Y TELEPORTER dans le grand ; dans un petit, toute la carte et sa fleche, qui",
    "// mettent sa zone en grand). 31 a 36 la carte du pays du joueur : drapeau, nom, rang, argent, power, skill. 37 le",
    "// classement vide. 38 a 77 les 10 lignes du classement, 4 cases chacune : rang, drapeau, nom (${ON} : le pays du joueur),",
    "// score. Le bandeau : 78 le nom de la ligue du pays du joueur, 79 le chemin de son icone apres 90 octets (ng_module.icone),",
    "// 80 le keep inventory (${ON} allume en vert, ${OFF} eteint en rouge). Les drapeaux sont les glyphes du tchat (glyph_E8.png",
    "// de NGPremiumResourcePack), dessines dans la police par defaut. Une case sans rien a montrer est vide (de l'air) : ce",
    "// qui la lit est cache. Textes du serveur en localize false.")

# Chaque element d'une liste "controls" est un controle nomme (un objet a une seule cle) : une liste dans une liste
# (fonction PowerShell qui rend un tableau) ferait un ecran que le jeu refuse. Une couleur est faite de trois nombres
# entre 0 et 1, et aucun texte ne porte le nom d'un type .NET : une variable locale qui en cache une autre (PowerShell
# ignore la casse) y mettrait un objet a la place d'une constante.
function Check($node, [string]$where) {
    if ($node -is [string]) {
        if ($node.Contains('System.')) { throw "objet a la place d'un texte sous $where : $node" }
        return
    }
    if ($node -isnot [System.Collections.IDictionary]) {
        if ($node -is [System.Collections.IEnumerable]) { foreach ($item in $node) { Check $item $where } }
        return
    }
    foreach ($k in $node.Keys) {
        $value = $node[$k]
        if ($k -eq 'controls') {
            foreach ($control in $value) {
                if ($control -isnot [System.Collections.IDictionary] -or $control.Count -ne 1) { throw "controle mal forme sous $where" }
                foreach ($name in $control.Keys) { Check $control[$name] ($where + '/' + $name) }
            }
        } elseif ($k -eq 'color') {
            $numbers = @($value | Where-Object { ($_ -is [int] -or $_ -is [double]) -and $_ -ge 0 -and $_ -le 1 })
            if (@($value).Count -ne 3 -or $numbers.Count -ne 3) { throw "couleur mal formee sous $where" }
        } else {
            Check $value ($where + '.' + $k)
        }
    }
}

$root = Build
Check $root.main_panel 'main_panel'
$out = Join-Path $Pack 'ui\Interface\warzone.json'
$json = Json $root
[IO.File]::WriteAllText($out, (($head -join "`r`n") + "`r`n" + $json + "`r`n"), (New-Object Text.UTF8Encoding $false))
Write-Output ('ecrit : ' + (Resolve-Path $out))
