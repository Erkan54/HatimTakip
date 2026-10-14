# Kur’an verisi kaynakları

- Arapça harekeli imlâî metin: [Tanzil Project](https://tanzil.net), **Simple / Imlaei**; risan/quran-json [Simple veri dosyası](https://quran-json.risanb.com/text/simple/quran.json) üzerinden indirildi. Harekeler korunur; metin elle sadeleştirilmez veya normalize edilmez. [Metin türleri](https://tanzil.net/docs/quran_text_types). Copyright © 2007–2021 Tanzil Project. Creative Commons Attribution 3.0; metin değiştirilmeden, kaynak ve Tanzil bağlantısı belirtilerek dağıtılmalıdır. Tam kaynak bildirimi [TANZIL-LICENSE.txt](TANZIL-LICENSE.txt) içinde ve uygulamanın Lisanslar ekranındadır. [Kaynak depo](https://github.com/risan/quran-json).
- Türkçe meal: Rowwad Translation Center, `turkish_rwwad` sürüm **1.0.4**, [QuranEnc kaynak sayfası](https://quranenc.com/en/browse/turkish_rwwad/), risan/quran-json `tr-rwwad` dosyaları üzerinden indirildi. QuranEnc yeniden yayına; çevirinin değiştirilmemesi, yayınevi ve QuranEnc kredisinin verilmesi, sürüm ve transkript bilgisinin korunması, düzeltme notlarının bildirilmesi, yeni sürümlerin takip edilmesi ve uygunsuz reklam kullanılmaması şartlarıyla izin verir. [Kaynak kataloğu](https://quran-json.risanb.com/translations/index.json).
- Sayfa, cüz ve sure sınırları: [Tanzil quran-data.xml](https://tanzil.net/res/text/metadata/quran-data.xml), Tanzil Project; lisans ve atıf için [Tanzil metin lisansı](https://tanzil.net/docs/text_license).
- Paketleme ve veri kataloğu: [risan/quran-json](https://github.com/risan/quran-json), CC BY-SA 4.0; kaynak içeriklerin ayrı şartları saklıdır.

`verses.json` 6.236 ayet, 114 sure, 604 sayfa ve 30 cüz içerir. Arapça ve Türkçe metin ayet numarasına göre birebir eşlenmiştir. Metinler uygulama tarafından değiştirilmez.

Simple kaynak dosyası SHA-256: `077f4c7deca5ddc07d93981a97ace763c2548025a1cab1284ddd6055d9e886cf`.
Kaynak anlık görüntüsü `tools/build_quran.py` içinde bu özetle sabitlenir.
`python tools/build_quran.py --update-arabic` yalnızca Arapça alanlarını değiştirir;
`python tools/build_quran.py --verify` tüm ayetleri kaynakla birebir karşılaştırır.
Sure/ayet kimlikleri, meal, sayfa ve cüz eşlemeleri bu geçişte değişmez.
