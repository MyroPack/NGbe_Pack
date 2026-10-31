"""Ecrit ui/Interface/punisher_ng.json : l'ecran a cases du Punisher (conteneur ng:punisher de NGMod, comme le market).

    python -I tools/punisher/gen_punisher_ng.py .

Les cases sont celles de NGMod/Ui/Punisher/PunisherSlots.cs. Meme habillage que les fenetres du Punisher
(ui/Interface/punisher.json, gardees quand aucun serveur de jeu n'ouvre l'ecran). Formes de liaison reprises de l'annuaire
(ui/Interface/annuaire.json) : texte d'une case lu dans #hover_text, ligne cachee quand sa case est vide, marqueur cherche
par retrait d'une sous-chaine, clic par button.drop_all.
"""
import io
import json
import os
import sys

VIEW = 10
TIER, POINTS, TITLE, TEXT, EXPIRY, RULES_BUTTON, HISTORY_TITLE, NONE = 11, 12, 13, 14, 15, 16, 17, 18
TILE_FIRST = 20
ROW_FIRST, ROWS = 40, 10
PAGE_PREVIOUS, PAGE_LABEL, PAGE_NEXT = 50, 51, 52
RULES_TITLE, RULES_HELP, RULES_BACK = 60, 61, 62
RULE_FIRST, RULES = 64, 10
RULES_PAGE_PREVIOUS, RULES_PAGE_LABEL, RULES_PAGE_NEXT = 84, 85, 86
DETAIL_TITLE, DETAIL_NAME, DETAIL_BACK = 180, 181, 182
DETAIL_LINE_FIRST, DETAIL_LINES = 183, 12
TILE_ORDER = ["skills", "mute_chat", "mute_vocal", "atm_percent", "potions", "referent_countries", "ban_event", "gas_consumption",
              "toxic_status", "tax_market", "market_publicity", "coeff_toxicity", "ban_sanction"]

WHITE = [0.98, 0.98, 0.98]
GREY_TEXT = [0.631, 0.631, 0.667]
BORDER = [0.094, 0.094, 0.106]
PANEL = [0.122, 0.122, 0.133]
HEADER = [0.153, 0.153, 0.165]
LINE = [0.247, 0.247, 0.275]
ROSE = [1.0, 0.122, 0.424]
OUTLINE = [0.443, 0.443, 0.482]
BUTTON = [0.322, 0.322, 0.361]
HOVER = [0.208, 0.208, 0.224]
ORANGE = [0.851, 0.467, 0.024]


def filled():
    return "(not((#hover_text) = ''))"


def has(marker):
    return "(not ((#hover_text - '%s') = #hover_text))" % marker


def lacks(marker):
    return "((#hover_text - '%s') = #hover_text)" % marker


def visible_by(condition):
    return [
        {"binding_name": "#hover_text", "binding_type": "collection", "binding_collection_name": "container_items"},
        {"binding_type": "view", "source_property_name": condition, "target_property_name": "#visible"},
    ]


def image(color, size, offset=(0, 0), layer=1, anchor="top_left", texture="textures/ui/background/background_white", **extra):
    node = {"type": "image", "texture": texture, "color": color, "anchor_from": anchor, "anchor_to": anchor,
            "offset": list(offset), "size": list(size), "layer": layer}
    node.update(extra)
    return node


def text(scale, color=WHITE, size=("100%", "default"), anchor="top_left", align="left", font="default", offset=(0, 0), layer=4):
    """Le texte de la case de l'ancetre le plus proche qui porte un collection_index."""
    return {"type": "label", "text": "#text", "size": list(size), "anchor_from": anchor, "anchor_to": anchor, "offset": list(offset),
            "text_alignment": align, "color": color, "font_scale_factor": scale, "font_type": font, "shadow": False, "localize": False,
            "layer": layer,
            "bindings": [{"binding_type": "collection", "binding_collection_name": "container_items", "binding_name": "#hover_text",
                          "binding_name_override": "#text"}]}


def cell(slot, size, offset=(0, 0), layer=1, condition=None, controls=(), anchor="top_left", clip=False):
    """Une zone liee a la case slot (meme forme que les colonnes de l'annuaire), visible selon condition ; clip : le texte
    est coupe au bord de la zone (les tags ne debordent jamais)."""
    inner = {"type": "panel", "size": ["100%", "100%"], "controls": list(controls)}
    if clip:
        inner["clips_children"] = True
    if condition:
        inner["bindings"] = [{"binding_type": "collection", "binding_collection_name": "container_items", "binding_name": "#hover_text",
                              "binding_name_override": "#hover_text"},
                             {"binding_type": "view", "source_property_name": condition, "target_property_name": "#visible"}]
    return {"type": "collection_panel", "collection_name": "container_items", "anchor_from": anchor, "anchor_to": anchor,
            "offset": list(offset), "size": list(size), "layer": layer,
            "controls": [{"cell": {"type": "collection_panel", "size": ["100%", "100%"], "collection_index": slot,
                                   "controls": [{"on": inner}]}}]}


def label_cell(slot, size, offset, scale, color=WHITE, align="left", font="default", layer=2, anchor="top_left", label_anchor="top_left"):
    return cell(slot, size, offset, layer, filled(), [{"label": text(scale, color, anchor=label_anchor, align=align, font=font)}], anchor)


def click(slot, default, hover, pressed=None):
    """Le bouton d'une case (meme forme que la pastille de l'annuaire) : un clic est un button.drop_all sur la case."""
    def face(color):
        return {"type": "panel", "size": ["100%", "100%"]} if color is None else image(color, ("100%", "100%"))
    return {"type": "button", "collection_index": slot, "size": ["100%", "100%"], "default_control": "default",
            "hover_control": "hover", "pressed_control": "pressed", "focus_enabled": True, "focus_magnet_enabled": True,
            "sound_name": "random.click", "sound_volume": 1.0, "sound_pitch": 1.0,
            "bindings": [{"binding_type": "collection_details", "binding_collection_name": "container_items", "binding_condition": "once"}],
            "button_mappings": [
                {"from_button_id": "button.menu_select", "to_button_id": "button.drop_all", "mapping_type": "pressed", "consume_event": True},
                {"from_button_id": "button.menu_ok", "to_button_id": "button.drop_all", "mapping_type": "pressed", "consume_event": True}],
            "controls": [{"default": face(default)}, {"hover": face(hover)}, {"pressed": face(pressed if pressed is not None else hover)}]}


def grey_button(slot, size, offset, anchor="top_left"):
    """Un bouton gris (« Voir le reglement », « Retour ») : fond 52525C, survol 71717B, texte blanc centre."""
    return cell(slot, size, offset, 3, filled(), [
        {"button": click(slot, BUTTON, OUTLINE)},
        {"label": text(0.65, WHITE, size=("default", "default"), anchor="center", align="center", layer=6)},
    ], anchor)


def window(width, height, controls):
    return {"type": "panel", "size": ["100%", "100%"], "controls": [{"bounds": image(BORDER, (width, height), anchor="center", controls=[
        {"inner": image(PANEL, ("100% - 2px", "100% - 2px"), anchor="center", controls=controls)}])}]}


def close_button(offset):
    return {"close@ng_module.close_button": {"anchor_from": "top_right", "anchor_to": "top_right", "offset": list(offset), "layer": 8}}


# ---------------- Punisher ----------------

def tile(penalty, row):
    slot = TILE_FIRST + TILE_ORDER.index(penalty)
    lit = image([1, 1, 1], (41, 51), (1, 1), 1, texture="textures/ui/punisher/" + penalty, bindings=visible_by(has("§3§r")))
    off = image([1, 1, 1], (41, 51), (1, 1), 1, texture="textures/ui/punisher/" + penalty + "_off", bindings=visible_by(lacks("§3§r")))
    area = {"type": "panel", "size": [39, 15], "anchor_from": "top_left", "anchor_to": "top_left", "offset": [2, 35], "clips_children": True,
            "layer": 2, "controls": [{"label": text(0.38, [1, 1, 1], anchor="top_middle", align="center", layer=3)}]}
    return {"tile_%s" % penalty: {"type": "panel", "size": [44, 54], "collection_index": slot,
                                  "bindings": visible_by(has("§%d§r" % row)),
                                  "controls": [{"lit": lit}, {"off": off}, {"text": area}]}}


def tile_row(row, offset):
    return {"type": "stack_panel", "orientation": "horizontal", "collection_name": "container_items", "anchor_from": "bottom_middle",
            "anchor_to": "bottom_middle", "offset": list(offset), "size": [264, 54], "layer": 2,
            "controls": [tile(p, row) for p in TILE_ORDER]}


# Largeur des tags d'etat : celle du plus long tag reel, « Avertissement » (29,4 a l'echelle 0,42 sur la capture du vrai
# client du 28/10, ou il debordait du tag de 28), avec une marge ; le texte est coupe au bord s'il etait plus long.
STATUS_WIDTH = 36


def status_pill(marker, color, key, text_color):
    return image(color, (STATUS_WIDTH, 7), (2, 0), 3, anchor="left_middle", bindings=visible_by(has(marker)), clips_children=True,
                 controls=[{"label": {"type": "label", "size": ["default", "default"], "text": key, "font_scale_factor": 0.42,
                                      "color": text_color, "layer": 4}}])


def history_row(slot):
    return {"row_%d" % slot: {"type": "panel", "size": ["100%", 16], "collection_index": slot, "bindings": visible_by(filled()),
                              "controls": [
                                  {"button": dict(click(slot, None, HOVER), size=["100%", 15], anchor_from="top_left", anchor_to="top_left")},
                                  {"running": status_pill("§4§r", ROSE, "punisher.status.running", [1, 1, 1])},
                                  {"ended": status_pill("§5§r", BUTTON, "punisher.status.ended", [0.831, 0.831, 0.847])},
                                  {"warning": status_pill("§6§r", ORANGE, "punisher.status.warning", [1, 1, 1])},
                                  {"text": text(0.5, WHITE, size=("100%% - %dpx" % (STATUS_WIDTH + 6), "default"), anchor="left_middle",
                                                offset=(STATUS_WIDTH + 4, 0))},
                                  {"line": image(LINE, ("100%", 1), anchor="bottom_left", layer=2)}]}}


def none_row():
    return {"row_none": {"type": "panel", "size": ["100%", 16], "collection_index": NONE, "bindings": visible_by(filled()),
                         "controls": [{"text": text(0.5, WHITE, size=("100% - 8px", "default"), anchor="left_middle", offset=(4, 0))}]}}


def pagination(previous=PAGE_PREVIOUS, label=PAGE_LABEL, next_=PAGE_NEXT, size=("100% - 8px", 18), anchor="bottom_middle", offset=(0, -4)):
    """La barre de pages du market (ui/Interface/market.json, cases 21 a 23) : fleche gauche, « 1/3 », fleche droite."""
    def arrow(slot, icon, offset):
        return {"buttton@ng_module.Simple_Button": {"size": [11, 11], "offset": [0, 0.6], "$index": slot, "$icon_right_offset": [offset, 0],
                                                     "$size_icone_right": [7, 7], "$texture_icone_right": icon,
                                                     "$texture_button": "ng_asset.button_18"}}
    return {"paggination@ng_asset.background_white": {
        "size": list(size), "color": [0.18, 0.18, 0.192], "anchor_from": anchor, "anchor_to": anchor,
        "offset": list(offset), "layer": 3,
        "controls": [{"content@ng_module.stackpanel": {"orientation": "horizontal", "size": ["100%c", "100%"], "controls": [
            {"left_button@ng_module.panel": {"size": ["100%c", "100%"], "controls": [arrow(previous, "ng_asset.icon_34", -0.3)]}},
            {"padding@ng_module.panel": {"size": [3.1, 0.1]}},
            {"text@ng_module.panel": {"size": ["100%c", "100%"], "controls": [
                {"text@ng_module.Simple_text": {"$type_get_text": "Get_text_type_1", "$index": label, "offset": [0, 0.6],
                                                "size": ["100%c", "100%"], "$font_scale_factor": 0.7}}]}},
            {"padding@ng_module.panel": {"size": [2, 0.1]}},
            {"righ_button@ng_module.panel": {"size": ["100%c", "100%"], "controls": [arrow(next_, "ng_asset.icon_35", 0.3)]}},
        ]}}]}}


def main_view():
    header = image(HEADER, ("100%", 100), layer=1, controls=[
        {"tier": cell(TIER, (50, 11), (10, 9), 2, filled(), clip=True, controls=[
            {"fill": image(ROSE, ("100%", "100%"), layer=1)},
            {"label": text(0.6, [1, 1, 1], size=("default", "default"), anchor="center", align="center", layer=2)}])},
        {"points": cell(POINTS, (66, 11), (63, 9), 2, filled(), clip=True, controls=[
            {"border": image(OUTLINE, ("100%", "100%"), layer=1)},
            {"fill": image(PANEL, ("100% - 2px", "100% - 2px"), anchor="center", layer=2)},
            {"label": text(0.6, [1, 1, 1], size=("default", "default"), anchor="center", align="center", layer=3)}])},
        {"title": label_cell(TITLE, ("100% - 20px", 16), (10, 22), 1.5, font="MinecraftTen")},
        {"text": label_cell(TEXT, ("100% - 20px", 26), (10, 38), 0.6, GREY_TEXT)},
        {"expiry": label_cell(EXPIRY, ("100% - 20px", 7), (10, 65), 0.6, GREY_TEXT)},
        {"rules": grey_button(RULES_BUTTON, (72, 14), (10, 78))},
    ])
    left = image(BORDER, (270, "100%"), layer=1, controls=[{"inner": image(PANEL, ("100% - 2px", "100% - 2px"), anchor="center", controls=[
        {"header": header},
        {"row_1": tile_row(1, (0, -60))},
        {"row_2": tile_row(2, (0, -5))},
    ])}])
    # Une page de l'historique (10 lignes de 16, sans defilement), puis la barre de pages en bas, comme le market.
    history = {"type": "stack_panel", "orientation": "vertical", "collection_name": "container_items", "anchor_from": "top_left",
               "anchor_to": "top_left", "offset": [4, 25], "size": ["100% - 8px", 160], "layer": 3,
               "controls": [history_row(ROW_FIRST + i) for i in range(ROWS)] + [none_row()]}
    right = image(BORDER, (144, "100%"), layer=1, anchor="top_right", controls=[{"inner": image(HEADER, ("100% - 2px", "100% - 2px"), anchor="center", controls=[
        {"title": label_cell(HISTORY_TITLE, ("100% - 30px", 10), (7, 7), 0.8)},
        close_button((-4, 4)),
        {"line": image(LINE, ("100%", 1), (0, 21), 2)},
        {"list": history},
        pagination(),
    ])}])
    return {"type": "panel", "size": [420, 222], "anchor_from": "center", "anchor_to": "center",
            "controls": [{"left": left}, {"right": right}]}


# ---------------- Reglement ----------------

def rule_row(i):
    points, name = RULE_FIRST + 2 * i, RULE_FIRST + 2 * i + 1
    pill = cell(points, (30, 9), (3, 2.5), 6, filled(), clip=True, controls=[
        {"fill": image(ROSE, ("100%", "100%"), layer=1)},
        {"label": text(0.5, [1, 1, 1], size=("default", "default"), anchor="center", align="center", layer=2)}])
    return {"rule_%d" % i: {"type": "panel", "size": ["100%", 14], "collection_index": name, "bindings": visible_by(filled()),
                            "controls": [{"pill": pill},
                                         {"text": text(0.6, WHITE, size=("100% - 44px", "default"), anchor="left_middle", offset=(39, 0))},
                                         {"line": image(LINE, ("100%", 1), anchor="bottom_left", layer=2)}]}}


def rules_view():
    # Une page du reglement (10 lignes de 14, sans defilement), puis Retour a gauche et la barre de pages a sa droite.
    rules = {"type": "stack_panel", "orientation": "vertical", "collection_name": "container_items", "anchor_from": "top_left",
             "anchor_to": "top_left", "offset": [6, 52], "size": ["100% - 12px", 140], "layer": 3,
             "controls": [rule_row(i) for i in range(RULES)]}
    content = window(300, 222, [
        {"header": image(HEADER, ("100%", 48), layer=1, controls=[
            {"title": label_cell(RULES_TITLE, ("100% - 40px", 14), (10, 8), 1.2, font="MinecraftTen")},
            close_button((-6, 6)),
            {"help": label_cell(RULES_HELP, ("100% - 20px", 14), (10, 27), 0.6, GREY_TEXT)}])},
        {"line": image(LINE, ("100%", 1), (0, 48), 2)},
        {"list": rules},
        {"back": grey_button(RULES_BACK, (60, 14), (10, -6), anchor="bottom_left")},
        pagination(RULES_PAGE_PREVIOUS, RULES_PAGE_LABEL, RULES_PAGE_NEXT, ("100% - 86px", 18), "bottom_right", (-6, -4)),
    ])
    return content


# ---------------- Detail d'une sanction ----------------

def detail_view():
    lines = {"type": "stack_panel", "orientation": "vertical", "collection_name": "container_items", "anchor_from": "top_left",
             "anchor_to": "top_left", "offset": [10, 62], "size": ["100% - 20px", "100%c"], "layer": 3,
             "controls": [{"line_%d" % i: {"type": "panel", "size": ["100%", 9], "collection_index": DETAIL_LINE_FIRST + i,
                                            "bindings": visible_by(filled()),
                                            "controls": [{"text": text(0.6, WHITE, anchor="left_middle")}]}} for i in range(DETAIL_LINES)]}
    return window(300, 222, [
        {"header": image(HEADER, ("100%", 48), layer=1, controls=[
            {"title": label_cell(DETAIL_TITLE, ("100% - 40px", 14), (10, 8), 1.2, font="MinecraftTen")},
            close_button((-6, 6)),
            {"name": label_cell(DETAIL_NAME, ("100% - 20px", 10), (10, 30), 0.8)}])},
        {"line": image(LINE, ("100%", 1), (0, 48), 2)},
        {"lines": lines},
        {"back": grey_button(DETAIL_BACK, (60, 14), (10, -7), anchor="bottom_left")},
    ])


def view(marker, content):
    return cell(VIEW, ("100%", "100%"), (0, 0), 1, has(marker), [{"content": content}])


def build():
    main = main_view()
    rules = rules_view()
    return {
        "namespace": "punisher_ng",
        "main_panel": {"type": "panel", "size": ["100%", "100%"], "controls": [
            {"main": view("§1§r", main)},
            {"rules": view("§2§r", rules)},
            {"detail": view("§3§r", detail_view())},
        ]},
    }


HEAD = """// Ecran a cases du Punisher (conteneur ng:punisher de NGMod, NGMod/Ui/Punisher), comme le market : le proxy
// (ModerationModule) envoie tout le contenu, NGMod le range dans ses cases (NGMod/Ui/Punisher/PunisherSlots.cs) et change
// de vue sur place. Fichier produit par tools/punisher/gen_punisher_ng.py (python -I tools/punisher/gen_punisher_ng.py .).
// Case 10 : la vue (§1§r Punisher, §2§r reglement, §3§r detail). Cases des malus : §1§r ou §2§r la rangee, §3§r allumee.
// Lignes de l'historique : §4§r en cours, §5§r terminee, §6§r avertissement, 10 par page (cases 40 a 49), barre de pages
// du market en cases 50 a 52 (fleches « §1 » ou « §0 », numero « 1/3 »). Reglement : 10 sanctions par page (cases 64 a 83),
// meme barre en cases 84 a 86. Une case sans rien a montrer est vide (de l'air, NGMod) : sa ligne, son tag et son texte
// sont caches. Textes du serveur en localize false.
"""


if __name__ == "__main__":
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    out = os.path.join(root, "ui", "Interface", "punisher_ng.json")
    io.open(out, "w", encoding="utf-8", newline="\r\n").write(HEAD + json.dumps(build(), ensure_ascii=False, separators=(",", ":")) + "\n")
    print("ecrit :", out)
