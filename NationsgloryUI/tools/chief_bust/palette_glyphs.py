#!/usr/bin/env python3
# Palette du buste du chef (onglet Menu du menu de pays) : neuf pages de police, font/glyph_XX.png, dont chaque
# caractere est un carre d'une seule couleur. Python 3 seul, aucune dependance.
#
#   python tools/chief_bust/palette_glyphs.py
#       refait les neuf pages
#   python tools/chief_bust/palette_glyphs.py --check
#       ne modifie rien ; code 1 si une page n'est plus celle que donne la palette
#
# Pourquoi : l'ecran ne sait pas dessiner une image fabriquee par le serveur. NGCountryMod ecrit donc le buste du chef
# comme du texte, un caractere par pixel de sa peau, et ces pages donnent a chaque caractere sa couleur.
#
# La palette, la meme que ChiefBust de NGCountryMod (a changer des deux cotes ensemble) :
#   - LEVELS niveaux par canal, de 0 a 255 : 13 x 13 x 13 = 2 197 couleurs ;
#   - la couleur numero n = rouge x 169 + vert x 13 + bleu (niveaux de 0 a 12) est le caractere n % 256 de la page
#     PAGES[n // 256] ; dans une page, le caractere c est a la ligne c // 16, colonne c % 16 ;
#   - les cases au-dela de la derniere couleur restent transparentes.
# Pages d'usage prive qu'aucun pack de NationsGlory ni de Paladium n'utilise (pris au 14/10/2026 : E0, E1, E2, E4,
# E6, E8, EE, F1 a F6).
#
# Une case fait CELL pixels de cote, pleine jusqu'aux bords : le jeu mesure la largeur d'un caractere a son dernier
# pixel non transparent, tous les carres ont donc la meme largeur.
import argparse, os, struct, sys, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
LEVELS = 13
PAGES = [0xE3, 0xE5, 0xE7, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEF]
CELL = 16
SIZE = CELL * 16


def level_value(level):
    return (level * 255 + (LEVELS - 1) // 2) // (LEVELS - 1)


def color(index):
    return level_value(index // (LEVELS * LEVELS)), level_value(index // LEVELS % LEVELS), level_value(index % LEVELS)


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def png_bytes(pixels):
    """PNG 8 bits RGBA non entrelace de SIZE x SIZE, sans filtre (des aplats : la compression suffit)."""
    raw = bytearray()
    for y in range(SIZE):
        raw += b"\x00" + pixels[y * SIZE * 4:(y + 1) * SIZE * 4]
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def png_pixels(data):
    """Les octets RGBA d'un PNG ecrit par png_bytes, ou None pour tout autre fichier."""
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
    if head != (SIZE, SIZE, 8, 6, 0, 0, 0):
        return None
    try:
        raw = zlib.decompress(idat)
    except zlib.error:
        return None
    stride = SIZE * 4 + 1
    if len(raw) != SIZE * stride or any(raw[y * stride] != 0 for y in range(SIZE)):
        return None
    return b"".join(raw[y * stride + 1:(y + 1) * stride] for y in range(SIZE))


def page_pixels(page):
    pixels = bytearray(SIZE * SIZE * 4)
    for cell in range(256):
        index = page * 256 + cell
        if index >= LEVELS ** 3:
            break
        square = bytes(color(index)) + b"\xff"
        for y in range(CELL):
            start = ((cell // 16 * CELL + y) * SIZE + cell % 16 * CELL) * 4
            pixels[start:start + CELL * 4] = square * CELL
    return bytes(pixels)


def main():
    parser = argparse.ArgumentParser(description="Pages de police de la palette du buste du chef.")
    parser.add_argument("--check", action="store_true", help="ne modifie rien, code 1 si une page n'est pas a jour")
    args = parser.parse_args()
    assert LEVELS ** 3 <= len(PAGES) * 256

    stale = []
    for number, code in enumerate(PAGES):
        path = os.path.join(ROOT, "font", "glyph_%02X.png" % code)
        pixels = page_pixels(number)
        current = None
        if os.path.isfile(path):
            with open(path, "rb") as f:
                current = png_pixels(f.read())
        if current != pixels:
            stale.append(os.path.basename(path))
            if not args.check:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "wb") as f:
                    f.write(png_bytes(pixels))
    print("font : %d pages de palette (%d couleurs), %d %s" % (len(PAGES), LEVELS ** 3, len(stale), "a refaire" if args.check else "ecrite(s)"))
    for name in stale:
        print("  ", name)
    return 1 if args.check and stale else 0


if __name__ == "__main__":
    sys.exit(main())
