"""Build the bundled, immutable Quran asset from credited upstream snapshots."""
import json
from pathlib import Path
import requests
import xml.etree.ElementTree as ET

BASE = "https://quran-json.risanb.com"
OUT = Path("assets/quran/verses.json")


def get(url):
    response = requests.get(url, timeout=45)
    response.raise_for_status()
    return response


def main():
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
        arabic = get(f"{BASE}/text/uthmani/chapters/{number}.json").json()["verses"]
        turkish = get(f"{BASE}/translations/tr-rwwad/chapters/{number}.json").json()["verses"]
        assert len(arabic) == len(turkish) == int(sura.attrib["ayas"])
        for ayah, (ar, tr) in enumerate(zip(arabic, turkish), 1):
            assert ar["id"] == tr["id"] == ayah
            page = page_starts.get((number, ayah), page)
            juz = juz_starts.get((number, ayah), juz)
            verses.append({"s": number, "a": ayah, "n": sura.attrib["tname"],
                           "p": page, "j": juz, "ar": ar["text"], "tr": tr["translation"]})
    assert len(verses) == 6236 and verses[-1]["s"] == 114 and verses[-1]["a"] == 6
    assert {v["p"] for v in verses} == set(range(1, 605))
    assert {v["j"] for v in verses} == set(range(1, 31))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(verses, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(verses)} verses to {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
