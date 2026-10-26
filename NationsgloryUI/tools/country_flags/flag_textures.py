#!/usr/bin/env python3
# Textures des drapeaux de pays pour le menu de pays. Deux series, un fichier par pays dans chacune :
#   textures/ui/country_flags/             le drapeau 26 x 13 tel quel (le petit drapeau encadre a cote du nom)
#   textures/ui/country_flag_backgrounds/  le drapeau en fond du bloc d'information de l'onglet Menu : 262 x 58,
#                                          etire aux proportions du bloc, lisse, et deja assombri par son voile
# Python 3 seul, aucune dependance.
#
#   python tools/country_flags/flag_textures.py
#       refait les textures a partir des sources et retire celles d'un pays disparu (une vingtaine de secondes)
#   python tools/country_flags/flag_textures.py --check
#       ne modifie rien ; code 1 si un dossier n'est plus celui que donnent les sources
#   option : --source <dossier> (par defaut ../NGPremiumResourcePack/tools/country_flags, a cote de ce depot)
#
# Les sources sont celles des glyphes de drapeaux du tchat, dans NGPremiumResourcePack/tools/country_flags :
#   flags.json           le drapeau de chaque pays (palette + un index de palette par pixel, 26 x 13)
#   country_glyphs.json  la table pays -> caractere, dont une copie est embarquee dans NGCountryMod
#
# Le nom du fichier est le code du caractere du pays, en minuscules : Afghanistan, caractere E801, donne e801.png
# dans les deux dossiers. NGCountryMod retrouve donc les chemins a partir de sa table (le nom du pays, son nom anglais
# et ses noms d'empire donnent le meme caractere) sans autre liste a tenir. Un pays garde son caractere d'une version
# a l'autre : il garde aussi ses fichiers.
#
# Le fond : le bloc d'information fait 393 x 87 unites d'interface. Le drapeau entier y est etire (rien n'est coupe),
# lisse par un noyau cubique de Mitchell, puis assombri par un voile en degrade : dense a gauche sous le nom, la
# description et le bouton, plus leger au centre, un peu plus dense a droite sous « Relation » et « Notation ». Le
# voile est cuit dans l'image pour qu'un pays sans drapeau garde le fond uni du bloc, sans rien a cacher cote ecran.
# Pour changer le voile : VEIL ci-dessous, puis relancer le script.
#
# Les images sont comparees par leurs pixels, pas par leurs octets : une autre version de zlib ne fait rien reecrire.
# Tous les calculs sont en entiers (poids en fractions exactes) : memes pixels sur toutes les machines.
#
# Apres un ajout de pays : refaire les glyphes dans NGPremiumResourcePack (country_flags.py), recopier la table dans
# NGCountryMod, puis relancer ce script ici.
import argparse, base64, json, os, re, struct, sys, zlib
from fractions import Fraction

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
FLAGS_DIR = os.path.join("textures", "ui", "country_flags")
BACKGROUNDS_DIR = os.path.join("textures", "ui", "country_flag_backgrounds")
DEFAULT_SOURCE = os.path.join(os.path.dirname(ROOT), "NGPremiumResourcePack", "tools", "country_flags")
CODE = re.compile(r"^[0-9A-F]{4}$")

# Le fond : deux tiers de pixel par unite d'interface (le bloc fait 393 x 87 unites).
BACKGROUND_SIZE = (262, 58)
# Part de la lumiere du drapeau gardee, de gauche (0) a droite (1) : (position, part), lineaire entre deux points.
VEIL = [(Fraction(0), Fraction(10, 100)), (Fraction(30, 100), Fraction(12, 100)), (Fraction(62, 100), Fraction(32, 100)),
        (Fraction(80, 100), Fraction(26, 100)), (Fraction(1), Fraction(16, 100))]
ONE = 1 << 12                                    # les poids sont en 1/4096


def read_json(path):
    with open(path, encoding="utf-8-sig") as f:
        return json.load(f)


def rgb(hex_color):
    h = hex_color.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


# ---------------------------------------------------------------- PNG

def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def png_bytes(width, height, channels, rows, filters=(0,)):
    """PNG 8 bits non entrelace, RGB (3 canaux) ou RGBA (4). Par ligne, le filtre de « filters » dont la somme des
    ecarts est la plus petite : 0 aucun, 1 a gauche, 2 au-dessus."""
    raw, prev = bytearray(), bytes(width * channels)
    for row in rows:
        best = None
        for kind in filters:
            if kind == 0:
                data = row
            elif kind == 1:
                data = bytes((row[i] - (row[i - channels] if i >= channels else 0)) & 255 for i in range(len(row)))
            else:
                data = bytes((a - b) & 255 for a, b in zip(row, prev))
            cost = sum(v if v < 128 else 256 - v for v in data) if len(filters) > 1 else 0
            if best is None or cost < best[0]:
                best = (cost, kind, data)
        raw += bytes([best[1]]) + best[2]
        prev = row
    color_type = {3: 2, 4: 6}[channels]
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, color_type, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def png_pixels(data):
    """(largeur, hauteur, canaux, octets des pixels) d'un PNG 8 bits RGB ou RGBA non entrelace, ou None."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    pos, idat, head = 8, b"", None
    while pos + 8 <= len(data):
        size, tag = struct.unpack(">I", data[pos:pos + 4])[0], data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + size]
        if tag == b"IHDR":
            head = struct.unpack(">IIBBBBB", body)
        elif tag == b"IDAT":
            idat += body
        pos += 12 + size
    if head is None or head[2] != 8 or head[3] not in (2, 6) or head[4:] != (0, 0, 0):
        return None
    width, height, channels = head[0], head[1], {2: 3, 6: 4}[head[3]]
    try:
        raw = zlib.decompress(idat)
    except zlib.error:
        return None
    stride, out, prev = width * channels, bytearray(), bytearray(width * channels)
    if len(raw) != height * (stride + 1):
        return None
    for y in range(height):
        kind, line = raw[y * (stride + 1)], bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b, c = prev[i], (prev[i - channels] if i >= channels else 0)
            if kind == 1:
                line[i] = (line[i] + a) & 255
            elif kind == 2:
                line[i] = (line[i] + b) & 255
            elif kind == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif kind == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        out += line
        prev = line
    return width, height, channels, bytes(out)


# ---------------------------------------------------------------- le fond : lissage et voile

def mitchell(x):
    """Noyau cubique de Mitchell et Netravali (B = C = 1/3), en fractions exactes."""
    x = abs(x)
    if x < 1:
        return (7 * x * x * x - 12 * x * x + Fraction(16, 3)) / 6
    if x < 2:
        return (Fraction(-7, 3) * x * x * x + 12 * x * x - 20 * x + Fraction(32, 3)) / 6
    return Fraction(0)


def axis(source, target):
    """Pour chaque pixel d'arrivee : les quatre pixels de depart (bornes au bord) et leurs poids en 1/4096."""
    table = []
    for i in range(target):
        u = Fraction(2 * i + 1, 2) * source / target - Fraction(1, 2)
        base = u.numerator // u.denominator
        t = u - base
        taps = [[base + o, int((mitchell(t - o) * ONE + Fraction(1, 2)) // 1)] for o in (-1, 0, 1, 2)]
        taps[1][1] += ONE - sum(w for _, w in taps)          # la somme fait exactement 1
        table.append([(min(max(p, 0), source - 1), w) for p, w in taps])
    return table


def veil(width):
    """Part de lumiere gardee par colonne, en 1/4096."""
    keep = []
    for x in range(width):
        t = Fraction(x, width - 1)
        for (a, va), (b, vb) in zip(VEIL, VEIL[1:]):
            if t <= b:
                keep.append(int(((va + (vb - va) * (t - a) / (b - a)) * ONE + Fraction(1, 2)) // 1))
                break
    return keep


def background_rows(flag, xs, ys, keep):
    """Les lignes RGB du fond d'un pays : « flag » est la liste des lignes de (r, g, b) du drapeau."""
    wide = [[tuple(sum(row[p][k] * w for p, w in taps) for k in range(3)) for taps in xs] for row in flag]
    rows = []
    for taps in ys:
        data = bytearray()
        for x in range(len(xs)):
            for k in range(3):
                v = sum(wide[p][x][k] * w for p, w in taps) // ONE          # couleur lissee, en 1/4096
                data.append((min(max(v, 0), 255 * ONE) * keep[x] + (ONE * ONE >> 1)) // (ONE * ONE))
        rows.append(bytes(data))
    return rows


# ---------------------------------------------------------------- les deux series

def build(source):
    """Rend {dossier: {nom de fichier: (largeur, hauteur, canaux, lignes)}} pour chaque pays de la table."""
    flags = read_json(os.path.join(source, "flags.json"))
    table = read_json(os.path.join(source, "country_glyphs.json"))
    width, height = flags["width"], flags["height"]
    colors = [rgb(c) for c in flags["palette"]]
    by_slug = {c["slug"]: c for c in flags["countries"]}
    back_w, back_h = BACKGROUND_SIZE
    xs, ys, keep = axis(width, back_w), axis(height, back_h), veil(back_w)
    out = {FLAGS_DIR: {}, BACKGROUNDS_DIR: {}}
    for name, entry in sorted(table["countries"].items()):
        code = entry["code"]
        if not CODE.match(code):
            sys.exit("code de caractere inattendu pour %s : %r" % (name, code))
        if name not in by_slug:
            sys.exit("%s est dans la table des caracteres mais pas dans flags.json" % name)
        indexes = base64.b64decode(by_slug[name]["flag"])
        if len(indexes) != width * height or max(indexes) >= len(colors):
            sys.exit("drapeau illisible pour %s (%d pixels)" % (name, len(indexes)))
        flag = [[colors[indexes[y * width + x]] for x in range(width)] for y in range(height)]
        filename = code.lower() + ".png"
        if filename in out[FLAGS_DIR]:
            sys.exit("deux pays ont le code %s" % code)
        out[FLAGS_DIR][filename] = (width, height, 4, [bytes(v for p in row for v in p + (255,)) for row in flag])
        out[BACKGROUNDS_DIR][filename] = (back_w, back_h, 3, background_rows(flag, xs, ys, keep))
    return out


def main():
    parser = argparse.ArgumentParser(description="Textures des drapeaux de pays du menu de pays.")
    parser.add_argument("--source", default=DEFAULT_SOURCE, help="dossier de flags.json et country_glyphs.json")
    parser.add_argument("--check", action="store_true", help="ne modifie rien, code 1 si un dossier n'est pas a jour")
    args = parser.parse_args()

    status = 0
    for folder, wanted in build(args.source).items():
        target = os.path.join(ROOT, folder)
        present = sorted(os.listdir(target)) if os.path.isdir(target) else []
        stray = [f for f in present if f not in wanted]
        stale = []
        for f in sorted(wanted):
            width, height, channels, rows = wanted[f]
            path = os.path.join(target, f)
            if f not in present or png_pixels(open(path, "rb").read()) != (width, height, channels, b"".join(rows)):
                stale.append(f)
        label = folder.replace(os.sep, "/")
        if args.check:
            for f in stale:
                print("a refaire :", label + "/" + f)
            for f in stray:
                print("en trop   :", label + "/" + f)
            print("%s : %d textures attendues, %d a refaire, %d en trop" % (label, len(wanted), len(stale), len(stray)))
            status |= 1 if stale or stray else 0
            continue
        os.makedirs(target, exist_ok=True)
        for f in stale:
            width, height, channels, rows = wanted[f]
            with open(os.path.join(target, f), "wb") as image:
                image.write(png_bytes(width, height, channels, rows, (0,) if channels == 4 else (1, 2)))
        for f in stray:
            os.remove(os.path.join(target, f))
        weight = sum(os.path.getsize(os.path.join(target, f)) for f in wanted)
        print("%s : %d textures (%d ecrites, %d retirees), %d Ko" % (label, len(wanted), len(stale), len(stray), weight // 1024))
    sys.exit(status)


if __name__ == "__main__":
    main()
