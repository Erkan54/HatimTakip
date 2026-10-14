"""Build the bundled, immutable Quran asset from credited upstream snapshots."""
import json
import argparse
import hashlib
from pathlib import Path
import requests
import xml.etree.ElementTree as ET

BASE = "https://quran-json.risanb.com"
OUT = Path("assets/quran/verses.json")
SIMPLE_URL = f"{BASE}/text/simple/quran.json"
# Pin the downloaded snapshot: upstream changes require a reviewed update.
SIMPLE_SHA256 = "077f4c7deca5ddc07d93981a97ace763c2548025a1cab1284ddd6055d9e886cf"


def load_simple(source_file=None):
    raw = Path(source_file).read_bytes() if source_file else get(SIMPLE_URL).content
    if hashlib.sha256(raw).hexdigest() != SIMPLE_SHA256:
        raise ValueError("Simple source checksum changed; review the upstream text before updating")
    chapters = json.loads(raw)
    assert [s["id"] for s in chapters] == list(range(1, 115))
    texts = {}
    for chapter in chapters:
        assert [v["id"] for v in chapter["verses"]] == list(range(1, len(chapter["verses"]) + 1))
        for verse in chapter["verses"]:
            assert isinstance(verse["text"], str) and verse["text"]
            texts[(chapter["id"], verse["id"])] = verse["text"]
    assert len(texts) == 6236
    return texts, chapters[0]["notice"]


def get(url):
    response = requests.get(url, timeout=45)
    response.raise_for_status()
    return response


def build_all(texts):
    meta = ET.fromstring(get("https://tanzil.net/res/text/metadata/quran-data.xml").content)
    suras = list(meta.find("suras"))
    pages = {int(x.attrib["index"]): (int(x.attrib["sura"]), int(x.attrib["aya"])) for x in meta.find("pages")}
    juzs = {int(x.attrib["index"]): (int(x.attrib["sura"]), int(x.attrib["aya"])) for x in meta.find("juzs")}
    assert len(suras) == 114 and len(pages) == 604 and len(juzs) == 30
    page_starts = {v: k for k, v in pages.items()}
    juz_starts = {v: k for k, v in juzs.items()}
    verses = []
    page = juz = 1
    for sura in suras:
        number = int(sura.attrib["index"])
        turkish = get(f"{BASE}/translations/tr-rwwad/chapters/{number}.json").json()["verses"]
        assert len(turkish) == int(sura.attrib["ayas"])
        for ayah, tr in enumerate(turkish, 1):
            assert tr["id"] == ayah
            page = page_starts.get((number, ayah), page)
            juz = juz_starts.get((number, ayah), juz)
            verses.append({"s": number, "a": ayah, "n": sura.attrib["tname"],
                           "p": page, "j": juz, "ar": texts[(number, ayah)], "tr": tr["translation"]})
    return verses


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--update-arabic", action="store_true",
                        help="Replace only Arabic; retain existing translation, IDs, pages and juzs")
    parser.add_argument("--verify", action="store_true", help="Check bundled Arabic against the pinned source without writing")
    parser.add_argument("--source-file", help="Use a local copy of the pinned Simple snapshot")
    args = parser.parse_args()
    texts, notice = load_simple(args.source_file)
    if args.update_arabic or args.verify:
        original = json.loads(OUT.read_text(encoding="utf-8"))
        assert [(v["s"], v["a"]) for v in original] == list(texts)
        verses = [dict(v, ar=texts[(v["s"], v["a"])]) for v in original]
        # Verify all non-Arabic fields, including ordering, before writing anything.
        assert [{k: val for k, val in v.items() if k != "ar"} for v in verses] == [
            {k: val for k, val in v.items() if k != "ar"} for v in original]
        if args.verify:
            assert verses == original, "Bundled Arabic differs from the pinned Simple source"
            print("Verified all 6236 Arabic verses verbatim against the pinned Simple source")
            return
    else:
        verses = build_all(texts)
    assert [(v["s"], v["a"]) for v in verses] == list(texts)
    assert len(verses) == 6236 and verses[-1]["s"] == 114 and verses[-1]["a"] == 6
    assert {v["p"] for v in verses} == set(range(1, 605))
    assert {v["j"] for v in verses} == set(range(1, 31))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(verses, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    OUT.with_name("TANZIL-LICENSE.txt").write_text(notice + "\n", encoding="utf-8")
    print(f"Wrote {len(verses)} verses to {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
