# Hatim Zinciri

Android öncelikli Flutter uygulaması. Firebase Anonymous Authentication ve Cloud Firestore kullanır. Kur’an metni, Türkçe meal, 604 Medine Mushafı sayfası ve 30 cüz eşlemesi cihazda `assets/quran/verses.json` içinde bulunur. Cloud Functions, Cloud Run, reklam ve ödeme bileşeni yoktur.

## Arayüz

Ortak tema `lib/app_design.dart` içindedir: sıcak krem zemin, koyu yeşil yüzeyler,
mat altın detaylar ve cihazda saklanan Manrope / Amiri yazı tipleri. Yazı tipi
kaynakları ve lisansları `assets/fonts/README.md` dosyasında bulunur.
Ana ekranda harita kısayolu yoktur; okuma ekranındaki harita simgesi kullanılır.
Haritadaki arama simgesi sayfa numarasıyla yerel seçim yapar, veritabanını okumaz.

Tamamlanan arayüz yenilemesi:

- **Okuma:** kalıcı meal tercihi, A−/A+ ile kalıcı Arapça yazı boyutu, Türkçe sure adları, ayet sonu işareti, segmentli ilerleme ve aralık sonunda **Devam et / Bitir** seçimi. Yeni aralık yalnızca Devam et ile ayrılır.
- **Grup takibi ve okuma:** 604 sayfa için cüz satırlı ızgara ve 30 cüz kartı, boş/kısmi/tamamlanan durumları, tamamlanan cüz/sayfa sayıları, sayfa araması ve yeni işaretlerde Geri al. Gruptaki **Kur’an oku** veya seçilen sayfa/cüzdeki **Bu bölümden oku** eylemi sınırsız sayfa okuması açar. Bu ekranda 10 ayetlik rezervasyon ve ayet onayı yoktur; sayfalar arasında ilerlenir, meal ve yazı boyutu ayarlanabilir. Evde veya uygulamada okunan sayfa/cüzler grupta elle işaretlenir; okuma ekranı otomatik tamamlandı kaydı oluşturmaz. Paylaşım ve tireli davet kodu uygulama çubuğundadır.
- **Ayarlar:** açık/koyu tema, meal, yazı boyutu, titreşim, isim değiştirme ve lisanslar. İlk kurulumda açık tema kullanılır; sistem teması izlenmez. Eski sistem tercihi açık temaya geçer, elle seçilmiş koyu tema korunur. Görünüm tercihleri yalnızca cihazdaki SharedPreferences içinde tutulur.
- **Ortak harita:** mevcut tek-belge okuması korunur. 604 sayfa birer kez çizilir; cihazdaki dört ortak cüz sayfası ilk ayetinin cüz satırına yerleştirilir, detayda iki cüz de gösterilir.
- **Android açılışı:** sistem temasından bağımsız açık açılış zemini ve halka/kitap simgesi; Android 12+ splash ve uyarlanabilir launcher ikonu. Kaydedilmiş görünüm Flutter açılınca uygulanır.

`screens.dart` dışa aktarma dosyasıdır. Ekranlar `home_screen.dart`,
`onboarding_screen.dart`, `reader_screen.dart`, `group_screen.dart`,
`settings_screen.dart` olarak ayrılmıştır. Ortak harita `hatim_map_view.dart`,
ızgara `page_grid.dart`, hareket araçları `motion.dart` içindedir.
Özel gruptan açılan yerel sayfa okuyucusu `group_reader_screen.dart` içindedir.
Animasyonlar azaltılmış hareket tercihine uyar; küçük/yatay ekran ve büyük yazı
senaryoları test edilir.

`flutter test` küçük ekran, yatay kullanım, büyütülmüş yazı, okuma akışı ve harita
seçimini yerel verilerle kontrol eder. Görsel önizlemeler oluşturmak için:

```powershell
flutter test test/ui_test.dart --dart-define=WRITE_UI_PREVIEWS=true
```

Önizlemeler `build/ui-previews/` altına yazılır; örnek veriler içerirler.

## Spark planı kurulumu

1. Firebase Console içinde **Spark** planında bir proje ve tek bir **(default)** Cloud Firestore veritabanı oluşturun. Faturalandırma hesabı bağlamayın.
2. Authentication > Sign-in method bölümünde **Anonymous** yöntemini açın.
3. Firebase projesine `com.example.hatim_halkasi` Android uygulamasını kaydedin. `google-services.json` dosyasını `android/app/` içine koyun. Bu projede Android Firebase seçenekleri `lib/firebase_options.dart` içinde kayıtlıdır.
4. Firestore Security Rules ve indexleri yükleyin: `npx firebase-tools deploy --only firestore:rules,firestore:indexes --project PROJE_ID`. Bu komut Firebase CLI oturumu gerektirir; **Functions deploy etmeyin**.
5. Firestore Console içinde `public/state` belgesini **bir kez** oluşturun: `round: 1`, `nextChunk: 0`, `completedChunks: 0`, `completedHatims: 0`, `lastCompletedChunk: -1` (hepsi number/integer). Kurallar istemcinin bu belgeyi oluşturmasına izin vermez. Bu başlangıç belgesi olmazsa hızlı katılım uyarı verir.
6. App Check için Android Play Integrity sağlayıcısını yapılandırın. Geliştirmede debug token kullanılabilir. Firestore ve Auth enforcement açmadan önce kayıtlı uygulamanın token alabildiğini doğrulayın.
7. Firebase Console > Firestore > Usage ekranından ücretsiz kotayı izleyin. Uygulama kotaya erişince kullanıcıya kısa uyarı gösterir; ücretli plana otomatik geçiş yoktur.

Gerçek Firebase projesiyle çalıştırma:

```powershell
flutter run -d "SM G990B2"
flutter build apk --debug
```

## Yerel emülatör

`npx firebase-tools emulators:start --only auth,firestore --project hatimhalkasi-66bba` komutuyla emülatörleri açın. Firestore emülatöründe `public/state` başlangıç belgesini emülatör arayüzünden oluşturun. Ardından Android emülatörü için:

```powershell
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

`flutter analyze`, `flutter test` ve `flutter build apk --debug` yerel doğrulama komutlarıdır. Gerçek Firebase projesi veya Android cihazı olmadan gerçek servis akışı doğrulanmış sayılmaz.

Profil isim değişikliği `users/{uid}.name` alanına tek yazma yapar. Kurallar yalnızca
hesabın sahibine 1–40 karakterlik adı güncelleme izni verir; grup/okuma kayıtları ve
`createdAt` korunur. Eski üyelik/işaret kayıtlarında o zamanki ad kalabilir. Bu
özelliği canlı projede kullanmadan önce güncel `firestore.rules` dosyasını yayınlayın:

```powershell
npx firebase-tools deploy --only firestore:rules --project PROJE_ID
```

Kuralları ve okuma senaryolarını gerçek projeyi kullanmadan doğrulamak için:

```powershell
cd tools/integration
npm ci
cd ../..
npx firebase-tools emulators:exec --only auth,firestore --project demo-hatim-halkasi "node tools/integration/run-checks.mjs"
```

Bu kontrol isim güncelleme yetkilerini, okuma rezervasyonunu/devralmayı,
sayfa tamamlamasını ve hatmin son aralığını kapsar; canlı dağıtım yapmaz.

## Veri ve maliyet modeli

- Ortak hatim 10 ayetlik 624 aralığa bölünür. Bir kullanıcı aralığı aldığı veya ayet onayladığı andan itibaren 30 dakika boyunca o aralık ona ayrılır; bu sırada başka kullanıcıya farklı bir aralık verilir. Süre dolduğunda eksik aralık öncelikle yeniden dağıtılır ve yeni kullanıcı son onaylanan ayetten sonraki ayetle devam eder. Her “Sonraki Ayet” onayı, yalnızca atanmış aralığın `next` alanını bir artırır. Son ayette ortak sayaç bir kez artar. Bir cihaz kapanırsa onaylanmış `next` korunur.
- Hatim Haritası 604 sayfanın tamamını kaydırmadan gösterir. Bir sayfadaki bütün ayetler onaylandığında sayfa numarası `public/state` belgesindeki `completedPages` listesine eklenir; başka aralıklara taşan sayfalar için ilgili aralıkların ilerlemesi de transaction içinde kontrol edilir. Harita açılışta yalnızca bu tek belgeyi okur, canlı dinleyici açmaz; Yenile düğmesi yeni bir okuma yapar. Yeni hatim başlayınca liste temizlenir.
- Atama çoğunlukla 1 state okuması + 1 chunk okuması ve 3 yazmadır; normal ayet onayı çoğunlukla 2 belge okuması ve 1 yazmadır. Sayfanın son ayeti onaylandığında birkaç komşu aralık daha okunabilir ve state belgesine bir ek yazma yapılır. Her onayda `state` de okunduğu için 1.000 kullanıcının yoğun okumasında 50.000 okuma / 20.000 yazma günlük Spark kotası aşılabilir. Bu miktar indirme sayısına değil günlük etkileşime bağlıdır.
- Ana ekranda bir state dinleyicisi; açık özel grupta yalnızca grup ve tek ilerleme belgesi dinleyicileri vardır. 604 sayfa ve 30 cüz için ayrı dinleyici yoktur. Grup ilerlemesi tek belgede saklandığından büyük veya çok aktif gruplarda belge boyutu/çekişme sınırı vardır.
- Firestore ücretsiz kota: 50.000 okuma, 20.000 yazma, 20.000 silme/gün, 1 GiB depolama, 10 GiB/ay çıkış. Kota sıfırlanma saati Pasifik saatine göredir. [Resmî Firestore kotaları](https://firebase.google.com/docs/firestore/quotas).
- TTL silme, otomatik yedekleme, PITR ve diğer faturalandırma gerektiren özellikler etkin değildir. [Firebase planları](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans).

## Spark planındaki güvenlik sınırları

Firestore Security Rules, eşzamanlı aralık çakışmasını ve tek ayetin aynı aralıkta iki defa onaylanmasını sınırlar. **Gerçek okuma davranışını doğrulayamaz.** Anonim bir kullanıcı hızlıca “Sonraki Ayet”e basarak katkıyı sahte gösterebilir. App Check de insanın ayeti okuduğunu kanıtlamaz. İstemciden gelen özel grup tamamlanma ve yeni hatim başlatma beyanları güvenilir sunucu olmadığı için kesin doğrulanamaz. Davet kodu rastgele 16 karakterdir; kodu bilen biri gruba katılabilir. Anonim hesap uygulama verileri silinince veya cihaz değişince kurtarılamaz. Bu sınırlamalar için ücretli bir backend eklenmemiştir.

Şu an paylaşılan davet metnindeki kod uygulama içinde elle girilir; otomatik derin bağlantı açılışı yoktur. Firebase projesi ve gerçek cihaz testi olmadan bu proje yayıma hazır kabul edilmemelidir.

## Kur’an verisi ve lisans

Okuma ekranında Tanzil **Simple / Imlaei** harekeli imlâî Arapça metin kullanılır.
Amiri yazı tipi cihazda saklanır; vasıl elifi ve Osmanlı imlasına özgü sıfır
işaretleri bu kaynak metinde yoktur. Normal harekeler ve kaynakta bulunan küçük
elif korunur. Metin elle işaret silerek dönüştürülmez. Sayfa/cüz numaraları mevcut
Medine Mushafı ayet eşlemesine dayanır; görünüm satır satır mushaf kopyası değildir.

`tools/build_quran.py` kaynaklardan ayetleri birebir eşler ve aralık bütünlüğünü kontrol eder. Metin uygulama çalışırken internetten alınmaz. Ayrıntılar [assets/quran/LICENSES.md](assets/quran/LICENSES.md) dosyasındadır. Türkçe meal yayına çıkmadan önce yayınevi/transkript şartlarına göre tekrar gözden geçirilmelidir.

Yalnızca Arapça kaynağını yenilemek ve kaynağa karşı doğrulamak için:

```powershell
python tools/build_quran.py --update-arabic
python tools/build_quran.py --verify
```

Kaynak SHA-256 özeti sabitlenmiştir; beklenmeyen kaynak değişikliğinde işlem durur.

## Kaynak yapısı ve hızlı başlangıç

| Konum | Sorumluluk |
| --- | --- |
| [`lib/`](lib/) | Flutter ekranları, tema, Kur'an verisi ve Firestore akışı |
| [`assets/`](assets/) | Yerel ayet/meal verileri ve lisanslı yazı tipleri |
| [`firestore.rules`](firestore.rules) | Veri erişimi ve ilerleme doğrulama kuralları |
| [`test/`](test/) | Arayüz, ayet kapsama ve harita kontrolleri |
| [`tools/integration/`](tools/integration/) | Firebase emülatörü için entegrasyon yardımcıları |
| `app/`, kök Gradle dosyaları | Depoda korunan Android/Kotlin başlangıç iskeleti |

Aktif mobil arayüz Flutter `lib/` katmanındadır; Android çalıştırma hedefi `android/` klasörüdür. Firebase kurulumu için yukarıdaki adımları tamamladıktan sonra:

```sh
git clone https://github.com/Erkan54/HatimTakip.git
cd HatimTakip
flutter pub get
flutter run
```

Firebase istemci tanımlayıcıları erişim yetkisi sağlamaz; erişim Firestore Security Rules ve App Check ayarlarıyla yönetilir. Mevcut veri/lisans ve Spark planı sınırlamaları yukarıda açıklanmıştır.
