#!/usr/bin/env python3
# Icones des ligues pour la page Classement du menu de pays : textures/ui/ng_assets/league/, une image carree de
# 128 x 128 par ligue, nommee d'apres la ligue (unranked, bronze, silver, gold, platinum, diamond).
# Python 3 seul, aucune dependance.
#
#   python tools/league_icons/league_icons.py
#       refait les six icones a partir des dessins de textures/ui/ng_assets/Auther
#   python tools/league_icons/league_icons.py --check
#       ne modifie rien ; code 1 si le dossier n'est plus celui que donnent les dessins
#
# Pourquoi ce dossier, alors que les dessins existent deja dans ng_assets/Auther :
#   - NGCountryMod ecrit le chemin de l'icone d'une ligue dans une case de l'ecran (la ligue du pays, sa prochaine
#     ligue) et l'ecran la dessine dans un carre. Les dessins ne sont pas tous carres (rank_argent fait 100 x 128,
#     rank_or 128 x 122, rank_master 127 x 128) : dessines dans un carre ils sont etires. Ici chaque dessin est pose
#     au centre d'un carre transparent de 128 x 128, sans etre redimensionne.
#   - Le mod retrouve le fichier par le nom de la ligue, sans table a tenir.
#   - Il y a cinq ligues (bronze, argent, or, platine, diamant) et quatre dessins. La ligue platine n'en a pas : son
#     icone est le dessin de la ligue or repeint en bleu glace (PLATINUM ci-dessous : la lumiere de chaque pixel
#     choisit sa teinte dans un degrade, du bleu sombre au blanc). La ligue diamant, la plus haute,
#     garde le dessin le plus riche, rank_master. Un pays non classe a le medaillon gris rank_mistaire.
#     Quand un vrai dessin de la ligue platine existera : le poser dans ng_assets/Auther, le nommer dans SOURCES a la
#     place de la recoloration, relancer ce script.
#
# Les images sont comparees par leurs pixels, pas par leurs octets : une autre version de zlib ne fait rien reecrire.
# Tous les calculs sont en entiers : memes pixels sur toutes les machines.
import argparse, os, struct, sys, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SOURCE_DIR = os.path.join("textures", "ui", "ng_assets", "Auther")
TARGET_DIR = os.path.join("textures", "ui", "ng_assets", "league")
SIZE = 128

# Degrade de la ligue platine : (lumiere du pixel d'origine de 0 a 255, couleur), lineaire entre deux points. Les
# points sont poses sur les lumieres du dessin de la ligue or : son lisere orange (160), son fond jaune (205), ses
# ailes creme (245), son etoile blanche (255).
PLATINUM = [(0, (10, 45, 60)), (160, (64, 168, 198)), (205, (118, 218, 238)), (245, (224, 246, 250)), (255, (255, 255, 255))]
# ligue -> (dessin, degrade de recoloration ou None)
SOURCES = {
    "unranked": ("rank_mistaire", None),
    "bronze": ("rank_bronze", None),
    "silver": ("rank_argent", None),
    "gold": ("rank_or", None),
    "platinum": ("rank_or", PLATINUM),
    "diamond": ("rank_master", None),
}


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def png_bytes(width, height, pixels):
    """PNG 8 bits RGBA non entrelace. Par ligne, le filtre (aucun, a gauche, au-dessus) aux ecarts les plus petits."""
    raw, prev, stride = bytearray(), bytes(width * 4), width * 4
    for y in range(height):
        row = pixels[y * stride:(y + 1) * stride]
        best = None
        for kind in (0, 1, 2):
            if kind == 0:
                data = row
            elif kind == 1:
                data = bytes((row[i] - (row[i - 4] if i >= 4 else 0)) & 255 for i in range(stride))
            else:
                data = bytes((a - b) & 255 for a, b in zip(row, prev))
            cost = sum(v if v < 128 else 256 - v for v in data)
            if best is None or cost < best[0]:
                best = (cost, kind, data)
        raw += bytes([best[1]]) + best[2]
        prev = row
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def png_rgba(data):
    """(largeur, hauteur, octets RGBA) d'un PNG 8 bits non entrelace : palette (avec ou sans transparence), RGB ou
    RGBA. Leve ValueError pour tout autre fichier."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("pas un PNG")
    pos, idat, head, palette, alpha = 8, b"", None, b"", b""
    while pos + 8 <= len(data):
        size, tag = struct.unpack(">I", data[pos:pos + 4])[0], data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + size]
        if tag == b"IHDR":
            head = struct.unpack(">IIBBBBB", body)
        elif tag == b"PLTE":
            palette = body
        elif tag == b"tRNS":
            alpha = body
        elif tag == b"IDAT":
            idat += body
        pos += 12 + size
    if head is None or head[2] != 8 or head[3] not in (2, 3, 6) or head[4:] != (0, 0, 0):
        raise ValueError("PNG non pris en charge (8 bits, non entrelace, palette, RGB ou RGBA)")
    width, height, channels = head[0], head[1], {2: 3, 3: 1, 6: 4}[head[3]]
    raw = zlib.decompress(idat)
    stride, lines, prev = width * channels, [], bytearray(width * channels)
    if len(raw) != height * (stride + 1):
        raise ValueError("PNG tronque")
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
        lines.append(line)
        prev = line
    out = bytearray()
    for line in lines:
        if channels == 4:
            out += line
        elif channels == 3:
            for i in range(0, stride, 3):
                out += line[i:i + 3] + b"\xff"
        else:
            for index in line:
                out += palette[index * 3:index * 3 + 3] + bytes([alpha[index] if index < len(alpha) else 255])
    return width, height, bytes(out)


def div(n, d):
    """Division entiere arrondie au plus pres."""
    return (2 * n + d) // (2 * d)


def recolor(pixels, stops):
    """Repeint un dessin par un degrade : la lumiere de chaque pixel (0 a 255) choisit sa couleur entre deux points
    de « stops ». La transparence n'est pas touchee."""
    ramp = []
    for light in range(256):
        for (l0, c0), (l1, c1) in zip(stops, stops[1:]):
            if l0 <= light <= l1:
                ramp.append(bytes(c0[k] + div((c1[k] - c0[k]) * (light - l0), l1 - l0) for k in range(3)))
                break
    out = bytearray(pixels)
    for i in range(0, len(pixels), 4):
        light = div(299 * pixels[i] + 587 * pixels[i + 1] + 114 * pixels[i + 2], 1000)
        out[i:i + 3] = ramp[light]
    return bytes(out)


def centred(width, height, pixels):
    """Le dessin au centre d'un carre transparent de SIZE x SIZE, sans redimensionnement."""
    if width > SIZE or height > SIZE:
        raise ValueError("dessin plus grand que %d x %d" % (SIZE, SIZE))
    left, top = (SIZE - width) // 2, (SIZE - height) // 2
    out = bytearray(SIZE * SIZE * 4)
    for y in range(height):
        start = ((top + y) * SIZE + left) * 4
        out[start:start + width * 4] = pixels[y * width * 4:(y + 1) * width * 4]
    # Un pixel transparent n'a pas de couleur utile : noir partout, pour des fichiers stables.
    for i in range(0, len(out), 4):
        if out[i + 3] == 0:
            out[i:i + 3] = b"\x00\x00\x00"
    return bytes(out)


def build():
    icons = {}
    for league, (drawing, how) in SOURCES.items():
        with open(os.path.join(ROOT, SOURCE_DIR, drawing + ".png"), "rb") as f:
            width, height, pixels = png_rgba(f.read())
        if how is not None:
            pixels = recolor(pixels, how)
        icons[league + ".png"] = centred(width, height, pixels)
    return icons


def main():
    parser = argparse.ArgumentParser(description="Icones des ligues de la page Classement du menu de pays.")
    parser.add_argument("--check", action="store_true", help="ne modifie rien, code 1 si le dossier n'est pas a jour")
    args = parser.parse_args()

    icons, folder, stale = build(), os.path.join(ROOT, TARGET_DIR), []
    present = sorted(os.listdir(folder)) if os.path.isdir(folder) else []
    for name, pixels in sorted(icons.items()):
        path, current = os.path.join(folder, name), None
        if os.path.isfile(path):
            try:
                with open(path, "rb") as f:
                    current = png_rgba(f.read())
            except (ValueError, zlib.error):
                current = None
        if current != (SIZE, SIZE, pixels):
            stale.append(name)
            if not args.check:
                os.makedirs(folder, exist_ok=True)
                with open(path, "wb") as f:
                    f.write(png_bytes(SIZE, SIZE, pixels))
    extra = [name for name in present if name not in icons]
    for name in extra:
        if not args.check:
            os.remove(os.path.join(folder, name))

    done = "a refaire" if args.check else "ecrite(s)"
    print("%s : %d icone(s), %d %s, %d fichier(s) en trop" % (TARGET_DIR.replace(os.sep, "/"), len(icons), len(stale), done, len(extra)))
    for name in stale + extra:
        print("  ", name)
    return 1 if args.check and (stale or extra) else 0


if __name__ == "__main__":
    sys.exit(main())
