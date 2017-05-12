package WordList::Phrase::ID::Proverb::KBBI;

our $DATE = '2016-01-13'; # DATE
our $VERSION = '0.03'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("shortest_word_len",11,"num_words_contains_nonword_chars",1713,"num_words",1713,"num_words_contains_whitespace",1713,"avg_word_len",31.4284880326912,"longest_word_len",110,"num_words_contains_unicode",0); # STATS

1;
# ABSTRACT: Proverb phrases from Kamus Besar Bahasa Indonesia




=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::ID::Proverb::KBBI - Proverb phrases from Kamus Besar Bahasa Indonesia

=head1 VERSION

This document describes version 0.03 of WordList::Phrase::ID::Proverb::KBBI (from Perl distribution WordList-Phrase-ID-Proverb-KBBI), released on 2016-01-13.

=head1 SYNOPSIS

 use WordList::Phrase::ID::Proverb::KBBI;

 my $wl = WordList::Phrase::ID::Proverb::KBBI->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 31.4284880326912 |
 | longest_word_len                 | 110              |
 | num_words                        | 1713             |
 | num_words_contains_nonword_chars | 1713             |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 1713             |
 | shortest_word_len                | 11               |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 SEE ALSO

Converted from L<Games::Word::Phraselist::KBBI> 0.03.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-ID-Proverb-KBBI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-ID-Proverb-KBBI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-ID-Proverb-KBBI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
ada bangkai ada hering
ada beras, taruh dalam padi
ada biduk serempu pula
ada gula ada semut
ada hujan ada panas, ada hari boleh balas
ada padi segala menjadi
ada rotan ada duri
ada rupa ada harga
ada sampan hendak berenang
ada uang ada barang
ada ubi ada talas, ada budi ada balas
adakah buaya menolak bangkai
adapun manikam itu jika dijatuhkan ke dalam limbahan sekalipun, niscaya tidak hilang cahayanya
adat bersendi syarak, syarak bersendi kitabullah
adat dagang tahan tawar
adat diisi janji dilabuh
adat diisi lembaga dituang
adat diisi, lembaga dituang
adat hidup tolong-menolong, syariat palu-memalu
adat pasang berturun naik
adat periuk berkerak, adat lesung berdekak
adat sepanjang jalan, cupak sepanjang betung
adat teluk timbunan kapal
agih-agih kungkang
air beriak tanda tak dalam
air besar batu bersibak
air cucuran atap jatuh ke pelimbahan juga
air diminum rasa duri, nasi dimakan rasa sekam
air jernih ikannya jinak
air lalu kubang tohor
air susu dibalas dengan air tuba
air tenang menghanyutkan
akal akar berpulas tak patah
akal tak sekali tiba
akan dijadikan tabuh singkat, akan dijadikan genderang berlebih
akidah disangka batu
alah bisa karena biasa
alah bisa tegal biasa
alah di rumpun betung
alah limau oleh benalu
alah main, menang sarak
alah membeli menang memakai
alah menang tak tahu, bersorak boleh
alah sabung menang sorak
alang berjawab, tepuk berbalas
alur bertempuh, jalan berturut
ampang sampai ke seberang, dinding sampai ke langit
amra disangka kedondong
anak ayam kehilangan induk
anak badak dihambat-hambat
anak baik menantu molek
anak orang, anak orang juga
anak sendiri disayangi, anak tiri dibengkengi
angan lalu paham bertumbuk
angan lalu, paham tertumbuk
angan menerawang langit
angan mengikat tubuh
angguk bukan, geleng ia
anggung-anggip bagai rumput tengah jalan
angin berputar ombak bersabung
angin tak dapat ditangkap, asap tak dapat digenggam
angkuh terbawa, tampan tinggal
anjing ditepuk menjungkit ekor
antah berkumpul sama antah, beras bersama beras
antan patah lesung hilang
antan patah, lesung hilang
apa gunanya kemenyan sebesar tungku kalau tidak dibakar
apa yang kurang pada belida, sisik ada tulang pun ada
api padam puntung berasap
api padam puntung hanyut
arang habis besi binasa
arang itu jikalau dibasuh dengan air mawar sekalipun, tiada akan putih
asal ada kecil pun pada
asal ada sama di hati, gajah terantai boleh dilepaskan
asal ayam pulang ke lumbung, asal itik pulang ke pelimbahan
asal berinsang, ikanlah
asal menugal adalah benih
asing lubuk, asing ikannya
asing maksud, asing sampai
aur ditanam, betung tumbuh
aur ditarik sungsang
awak tikus hendak menampar kepala kucing
awak yang payah membelah ruyung, orang lain yang beroleh sagunya
ayam bertelur di padi
ayam ditambat disambar elang
ayam hitam terbang malam
ayam itik raja pada tempatnya
ayam laga sekandang
ayam putih terbang siang
babi merasa gulai
badak makan anak
bagai air di daun talas
bagai air ditarik sungsang
bagai alu pencungkil duri
bagai anak sepat ketohoran
bagai anjing beranak enam
bagai anjing melintang denai
bagai ayam dibawa ke lampok
bagai balam dengan ketitir
bagai batu jatuh ke lubuk
bagai beliung dengan asahan
bagai belut digetil ekor
bagai belut diregang
bagai beruk kena ipuh
bagai bersesah kain dapat
bagai bertanak di kuali
bagai berumah di tepi tebing
bagai bulan dengan matahari
bagai bulan kesiangan
bagai buntal kembung
bagai bunyi cempedak jatuh
bagai bunyi siamang kenyang
bagai dawat dengan kertas
bagai dekan di bawah pangkal buluh
bagai denai gajah lalu
bagai dientak alu luncung
bagai dulang dengan tudung saji
bagai duri dalam daging
bagai empedu lekat di hati
bagai gadis jolong bersubang
bagai galah di tengah arus
bagai galah dijual
bagai garam jatuh ke air
bagai geluk tinggal di air
bagai getah dibawa ke semak
bagai guna-guna alu sesudah menumbuk dicampakkan
bagai ikan dalam keroncong
bagai ikan kena tuba
bagai ilak bercerai dengan benang
bagai inai dengan kuku
bagai itik pulang petang
bagai jampuk kesiangan hari
bagai jawi ditarik keluan
bagai jawi terkurung
bagai kacang direbus satu
bagai kambing dibawa ke air
bagai kambing harga dua kupang
bagai kapal tidak bertiang
bagai keluang bebar petang
bagai kena buah malaka
bagai kena santung pelalai
bagai kinantan hilang taji
bagai kucing dibawakan lidi
bagai kucing lepas senja
bagai kuku dengan daging
bagai kuku dengan isi
bagai langau di ekor gajah
bagai melihat asam
bagai membakar tunam basah
bagai mendapat durian runtuh
bagai menentang matahari
bagai menghela tali jala
bagai menggenggam bara, terasa hangat dilepaskan
bagai menghela rambut dalam tepung
bagai menyandang galas tiga
bagai menyukat belut
bagai orang kena miang
bagai pahat, tidak ditukul tidak makan
bagai pelita kehabisan minyak
bagai perian pecah
bagai pimping di lereng
bagai pinang belah dua
bagai pintu tak berpasak, perahu tak berkemudi
bagai pucuk pisang didiang
bagai rupa orang terkena beragih
bagai serangkak tertimbakan
bagai serdadu pulang baris
bagai si kudung beroleh cincin
bagai si lumpuh hendak merantau
bagai siamang kurang kayu
bagai tanduk bersendi gading
bagai tikus membaiki labu
bagai unta menyerahkan diri
bagaikan rama-rama masuk api
bagaimana bunyi gendang, begitulah tarinya
bagaimana ditanam, begitulah dituai
bagaimana ditanam begitulah dituai
bahasa menunjukkan bangsa
baik berjagung-jagung sementara padi belum masak
baik rupa sepemandangan, baik bunyi sependengaran
bajak patah banting terambau
bajak selalu di tanah yang lembut
bajak sudah terdorong ke bancah
baji dahan membelah dahan
baju indah dari balai, tiba di rumah menyarungkan
bak ilmu padi, kian berisi kian runduk
bak mandi di air kiambang, pelak lepas gatal pun datang
bak menanti orang dahulu, bak melalah orang kudian
bak tengguli ditukar cuka
bala lalu dibawa singgah
balik mayat di kubur
bandar air ke bukit
bangkit batang terendam
banyak menelan garam hidup
banyak orang banyak ragam nya
barang siapa menggali lubang, ia akan terperosok ke dalamnya
barang siapa yang berketuk ialah yang bertelur
barang tergenggam jatuh terlepas
batang betung beruas-ruas
batu hitam tak bersanding
bau busuk tidak berbangkai
bau nya setahun pelayaran
bayang-bayang disangka tubuh
bayang-bayang sepanjang badan
bayang-bayang tidak sepanjang badan
beban berat senggulung batu
belakang parang lagi jika diasah niscaya tajam
belalang dapat menuai
belalang hendak menjadi elang
belanak bermain di atas karang
belukar sudah menjadi rimba
belum beranak sudah ditimang belum duduk sudah berlunjur
belum beranak sudah ditimang
belum bertaji hendak berkokok
belum dipanjat asap kemenyan
belum diajun sudah tertarung
belum duduk belunjur dulu
belum duduk sudah belunjur
belum duduk sudah mengunjur
belum punya kuku hendak mencubit
belum tahu di pedas lada
belum tegak hendak berlari
belum tentu hilir mudik nya
belum tentu si upik si buyungnya
berair rongkong
berani hilang tak hilang, berani mati tak mati
berani malu, takut mati
berani sendok pengedang, air hangat direnanginya
berapa berat mata memandang, berat juga bahu memikul
berarak ke tebing
berat sama dipikul, ringan sama dijinjing
berat sepikul, ringan sejinjing
berbilang dari esa, mengaji dari alif
berbuat jahat jangan sekali, terbawa cemar segala ahli
bercerai sudah, talak tidak
berdiang di abu dingin
berebut temiang belah
berebut temiang hanyut, tangan luka temiang tak dapat
berendam se sayak air, berpaut sejengkal tali
bergantung di ujung kuku
bergantung pada rambut sehelai
berguru kepalang ajar, bagai bunga kembang tak jadi
berhakim kepada beruk
berhati baja, berurat kawat
beriak tanda tak dalam, berguncang tanda tak penuh
berjalan peliharakan kaki, berkata peliharakan lidah
berjalan sampai ke batas, berlayar sampai ke pulau
berjalan selangkah, melihat surut
berjalan selangkah menghadap surut, berkata sepatah dipikirkan
berkata peliharakan lidah
berkata-kata dengan lutut
berkepanjangan bagai agam
berkeras tidak berkeris
berlayar sambil memapan
berleleran bagai getah di lalang
bermain air basah, bermain api lecur
berminyak muka nya
berniaga di ujung lidah
beroleh badar tertimbakan
beroleh lumpur di tempat yang kering
beroleh sehasta hendak se depa
bersaksi ke lutut
bersandar di lemang hangat
berserah kabil
bersesapan belukar
bersikap masa bodoh
bersua beliung dengan sangkal
bersuluh menjemput api
bersurih bak sepasin, berjejak bak berkik, berbau bak embacang
bertali boleh dieret, bertampuk boleh dijinjing
bertanam tebu di bibir
berteduh di bawah betung
bertemu beliung dengan ruyung
bertemu muka dengan tedung
bertemu mura dengan tedung
bertemu ruas dengan buku
bertemu teras dengan beliung
bertenun sampai ke bunjai nya
bertepuk sebelah tangan
bertiraikan banir
bertukar beruk dengan cigak
bertunggul ditarah, kesat diampelas
berarak tidak berlari
bergantung pada tali rapuh
bergaduk diri, saku-saku diterbangkan angin
berguru dahulu sebelum bergurau
berhitung nasib peruntungan
berjanjang naik, bertangga turun
berkata siang melihat-lihat, berkata malam mendengar-dengar
berkayuh sambil ke hilir
berkelahi di ekor alahan
berkelahi dalam kepuk
berkelahi dalam mimpi
berkemudi di haluan, bergilir ke buritan
berkering air liur
berketuk di luar sangkar, bertanam di luar pagar
berkocak tanda tak penuh
berlaki anak semang
berlayar atas angin
berlayar bernakhoda, berjalan dengan yang tua
berlidah di lidah orang
berlurah di balik pendakian
bernapas ke luar badan
berpilin-pilin bagai kelindan
bertanjak baru bertinjau
bertabur bijan ke tasik
bertanam biji hampa
bertepuk sebelah tangan tidak akan berbunyi
bertitah lalu sembah berlaku
bertohor air liur
bertopang pangkal seia
besar berudu di kubangan, besar buaya di lautan
besar kapal besar gelombang
besar kayu besar bahan nya
besar kayu besar dahan nya
besar pasak dari tiang
besar periuk besar kerak
besar senggulung daripada beban, besar pasak daripada tiang
betung ditanam, aur tumbuh
becermin di air keruh
berakit-rakit ke hulu, berenang-renang ke tepian
berendam sesayak air, berpaut sejengkal tali
berebut lontong tanpa isi
biang menanti tembuk
biar dahi berluluk asal tanduk mengena
biar lambat laga, asal menang
biar miskin asal cerdik, terlawan jua orang kaya
biar putih tulang, jangan putih mata
biar singit jangan tertiarap
biar telinga rabit, asal dapat bersubang
biar tersengat, jangan tiarap
biar titik jangan tumpah
bibir nya bukan diretak panas
biduk lalu kiambang bertaut
biduk lalu, kiambang bertaut
biduk tiris menanti karam
bingung tak dapat diajar, cerdik tak dapat diikuti
bintang di langit boleh dibilang, tetapi arang di muka tak sadar
bodoh-bodoh sepat, tak makan pancing emas
bondong air bondong ikan
buah hati cahaya mata
buah manis berulat di dalamnya
buah tangisan beruk
buai diguncang, anak dicubit
bukan budak makan pisang
bukan tanahnya menjadi padi
bukit di balik pendakian
bukit jadi paya
bulan naik, matahari naik
bulang ayam betina
bulat air oleh pembuluh, bulat kata oleh mupakat
bulat boleh digulingkan, pipih boleh dilayangkan
bulu mata bagai seraut jatuh
bumi berputar zaman beredar
bumi mana yang tak kena hujan
bumi tidak selebar daun kelor
bungkuk kail hendak mengena
bungkuk sejengkal tidak terkedang
bungkus tulang dengan daun talas
buntat hendak jadi kemala
bunyi perempuan di air
buruk muka cermin dibelah
buruk perahu, buruk pangkalan
burung terbang dipipis lada
burung terbang dipipiskan lada
busuk kerbau, jatuh berdebuk
busut juga yang ditimbun anai-anai
buta kehilangan
cacing hendak menjadi naga
cacing menjadi ular naga
cakap berdegar-degar, tumit diketing
campak bunga dibalas dengan campak tahi
cangkat sama didaki lurah sama dituruni
cari umbut kena buku
carik-carik bulu ayam lama-lama bercantum juga
cekel berhabis, lapuk berteduh
cekur jerangau, ada lagi di ubun-ubun
cencang dua segerai
cencang putus tiang tumbuk
cencaru makan pedang
cepat kaki ringan tangan
cekak, bercekak henti, silat terkenang
condong ditumpil, lemah diaduk
condong yang akan menimpa
condong yang akan menongkat, rebah yang akan menegakkan
daging gajah sama dilapah, daging tuma sama dicecah
dagu nya lebah bergantung
dahan pembaji batang
dahi kiliran taji
dahi sehari bulan
dahulu bajak daripada jawi
dahulu sorak kemudian tohok
dahulu timah, sekarang besi
dalam laut boleh diajuk, dalam hati siapa tahu
dangkal telah keseberangan, dalam telah keajukan
dapat durian runtuh
dapat tebu rebah
darah baru setampuk pinang
darah se tampuk pinang
datang tak berjemput, pulang tak berhantar
datang tampak muka, pulang tampak punggung
datang tidak berjemput, pulang tidak berantar
degar degar merpati
dekat dapat ditunjal, jauh dapat ditunjuk
dekat mencari indu, jauh mencari suku
dekat mencari suku, jauh mencari hindu
dekat tak tercapai jauh tak berantara
dekat tak tercapai, jauh tak antara
delapan tapak bayang-bayang
di luar bagai madu, di dalam bagai empedu
di luar merah di dalam pahit
di mana bumi dipijak, di sana langit dijunjung
di mana bumi dipijak, di situ langit dijunjung
di mana kayu bengkok, di sanalah musang meniti
di mana pinggan pecah, di sana tembikar tinggal
di mana ranting dipatah, di situ air disauk
di mana tanah dipijak, di situ langit dijunjung
di mana tembilang terentak, di situlah cendawan tumbuh
di manakah berteras kayu mahang
di padang orang berlari, di padang sendiri berjingkat
diam di laut masin tidak, diam di bandar tak meniru
diam penggali berkarat, diam ubi berisi
diam seribu basa
dianjak layu, dianggur mati
dianjak layu, dibubut mati
dianjungkan seperti payung, ditambak seperti kasur
diberi berkuku hendak mencengkam
diberi berkuku hendak mencekam
diberi bertali panjang
diberi betis hendak paha
diberi kepala hendak bahu
diberi kuku hendak mencengkam
diberi sejari hendak setelempap
diberi sejengkal hendak sehasta diberi sehasta hendak sedepa
dibilang genap, dipagar ganjil
dibuat karena allah, menjadi murka allah
dibujuk ia menangis, ditendang ia tertawa
dicoba-coba bertanam mumbang, moga-moga tumbuh kelapa
dientak alu luncung
digenggam takut mati, dilepaskan takut terbang
dijual sayak, dibeli tempurung
dikatakan berhuma lebar, sesapan di halaman
dilihat pulut, ditanak berderai
diminta tebu diberi teberau
dinding teretas, tangga terpasang
dipilih antah satu-satu
diraih siku ngilu, direngkuh lutut sakit
dirintang siamang berbual
disangka panas sampai petang, kiranya hujan tengah hari
disangka tiada akan mengaram, ombak yang kecil diabaikan
diserakkan padi awak diimbaukan orang lain
ditetak belah, dipalu belah, tembikar juga akan jadinya
dialas bagai memengat
diasak layu, dicabut mati
diiringkan menyepak, dikemudiankan menanduk
dikati sama berat, diuji sama merah
dikerkah dia menampar pipi, dibakar dia melilit puntung
dipanggang tiada angus
ditindih yang berat, dililit yang panjang
dalam rumah membuat rumah
dengan sesendok madu dapat lebih banyak ditangkap serangga daripada dengan cuka sesendok
daripada cempedak lebih baik nangka, daripada tidak, lebih baik ada
daripada hidup bercermin bangkai lebih baik mati berkalang tanah
dari jung turun ke sampan
dari lecah lari ke duri
dari semak ke belukar
duduk berkisar, tegak berpaling
duduk di ambung-ambung taji
duduk meraut ranjau, tegak meninjau jarak
elok kata dalam mufakat, buruk kata di luar mufakat
elok palut, pengebat kurang
emas berpeti, kerbau berkandang
embun di ujung rumput
empang sampai ke seberang, dinding sampai ke langit
emping berantah
emping berserak hari hujan
emping terserak hari hujan
enak lauk dikunyah-kunyah, enak kata diperkatakan
enggan seribu daya, mau sepatah kata
endap di balik lalang sehelai
esa hilang dua terbilang
esa hilang, dua terbilang
gadai terdorong kepada Cina
gaharu dibakar kemenyan berbau
gajah lalu dibeli, rusa tidak terbeli
gajah mati karena gadingnya
gajah mati tulang setimbun
gajah seekor gembala dua
galas terdorong kepada Cina
gali lubang tutup lubang
garam di kulumnya tak hancur
garam di laut, asam di gunung bertemu dalam belanga juga
garam kami tak masin padanya
gayung bersambut, kata berjawab
gayung tua, gayung memutus
gamak-gamak seperti menyambal
gelegar buluh
geleng seperti patung kenyang
genting menanti putus, biang menanti tembuk
genting putus, biang menanti tembuk
geruh tak mencium bau
getah terbangkit kuaran tiba
gigi dengan lidah adakalanya bergigit juga
gigi tanggal rawan murah
gila di abun-abun
gombang di lebuh
gula di mulut, ikan dalam belanga
gunung juga yang dilejang panas
guru kencing berdiri, murid kencing berlari
habis beralur maka beralu-alu
habis kapak berganti beliung
habis manis sepah dibuang
habis miang karena bergeser
habis pati ampas dibuang
habis perkara, nasi sudah menjadi bubur
habis umpan kerong tak dapat
hancur badan dikandung tanah, budi baik terkenang jua
hangat hangat tahi ayam
hangus tiada berapi, karam tiada berair
hanyut dipintasi, lulus diselami, hilang dicari
harapan tak putus sampai jerat tersentak rantus
harimau ditakuti karena giginya
harimau mati karena belangnya
harimau mati meninggalkan belang, gajah mati meninggalkan gading, orang mati meninggalkan nama
harimau mati meninggalkan belang, gajah mati meninggalkan gading
harimau mengaum takkan menangkap
harimau menunjukkan belang nya
harum menghilangkan bau
harum semerbak mengandung mala
hati bak serangkak dibungkus
hati gatal mata digaruk
hawa pantang kerendahan, nafsu pantang kekurangan
hemat pangkal kaya, rajin pangkal pandai
hendak hinggap tiada berkaki
hendak megah, berlawan lebih
hendak menangguk ikan, tertangguk batang
hendak menggaruk tidak berkuku
hendak minyak air
hendak mulia bertabur urai
hendak panjang terlalu patah
hidung dicium pipi digigit
hidung laksana kuntum seroja, dada seperti mawar merekah
hidung seperti dasun tunggal
hidung tak mancung, pipi tersorong-sorong
hidup bertimba uang
hidup di ujung gurung orang
hidup dikandung adat, mati dikandung tanah
hidup dua muara
hidup kayu berbuah, hidup manusia biar berjasa
hidup sandar-menyandar umpama aur dengan tebing
hidup segan mati tak hendak
hidup segan, mati tak embuh
hidup seperti musang
hidup tidak karena doa, mati tidak karena sumpah
hilang di mata di hati jangan
hilang dicari, terapung direnangi, terbenam diselami
hilang geli karena gelitik
hilang kabus, teduh hujan
hilang kilat dalam kilau
hilang rona karena penyakit, hilang bangsa tidak beruang
hilang satu sepuluh gantinya
hilang sepuh tampak senam
hilang tak bercari, lulus tak berselami
hilang tak tentu rimbanya, mati tak tentu kuburnya
hilang tentu rimbanya, mati tentu kuburnya
hilir malam mudik tak singgah, daun nipah dikatakan daun abu
hinggap bak langau, titik bak hujan
hitam, hitam gula jawa
hitam, hitam kereta api, putih-putih kapur sirih
hitam, hitam tahi minyak dimakan juga, putih-putih ampas kelapa dibuang
hitam bagai pantat belanga
hitam di atas putih
hitam dikatakan putih, putih dikatakan hitam
hitam mata itu mana boleh bercerai dengan putihnya
hitam sebagai kuali
hitam seperti dawat
hitam tahan tempa, putih tahan sesah
hujan berbalik ke langit
hujan berpohon, panas berasal
hujan jatuh ke pasir
hujan menimpa bumi
hujan panas main hari, senang susah main hidup
hujan tak sekali jatuh, simpai tak sekali erat
hujan tempat berteduh, panas tempat berlindung
hulu malang pangkal celaka
hutan sudah terambah, teratak sudah tertegak
iba akan kacang sebuah, tak jadi memengat
ibarat menegakkan benang basah
ijuk tak bersagar lunak tak berbatu
ikan belum dapat, airnya sudah keruh
ikan biar dapat, serampang jangan pokah
ikan biar dapat, serampang jangan pukah
ikan di hulu, tuba di hilir
ikan di laut, asam di gunung, bertemu dalam belanga
ikan gantung, kucing tunggu
ikan lagi di laut, lada garam sudah dalam sengkalan
ikan pulang ke lubuk
ikan sekambu rusak oleh ikan seekor
ikhtiar menjalani untung menyudahi
ikut hati mati, ikut mata buta
ikut hati mati, ikut rasa binasa
ilmu padi, makin berisi makin runduk
inai tertepung kuku tanggal
indah kabar dari rupa
ingat sebelum kena, berhemat sebelum habis
ingin buah manggis hutan, masak ranum tergantung tinggi
intan disangka batu kelikir
isi lemak dapat ke orang, tulang bulu pulang ke kita
itik bertaji
jadi abu arang
jadi alas cakap
jadi bumi langit
jadi kain basahan
jahit sudah kelindan putus
janda belum berlaki
jangan dilepaskan tangan kanan, sebelum tangan kiri berpegang
jangan diperlebar timba ke perigi, kalau tak putus, genting
jangan ditentang matahari condong, takut terturut jalan tak berintis
jangan diperlelarkan timba perigi, kalau tak putus genting
jangat liat kurang panggang
janji sampai, sukatan penuh
jaras dikatakan raga jarang
jatuh di atas tilam
jatuh diimpit tangga
jauh bau bunga, dekat bau tahi
jauh berjalan banyak dilihat, lama hidup banyak dirasa
jauh berjalan banyak dilihat
jauh di mata di hati jangan
jauh di mata, dekat di hati
jauh panggang dari api
jelatang di hulu air
jerat halus kelindan sutra
jerat semata bunda kandung
jerih menentang boleh, rugi menentang laba
jika belalang ada seekor, jika emas ada miang
jika benih yang baik jatuh ke laut, menjadi pulau
jika kasih akan padi, buanglah rumput
jika langkah sudah terlangkahkan, berpantang dihela surut
jika takut dilimbur pasang, jangan berumah di tepi pantai
jika tidak pecah ruyung, di mana boleh mendapat sagu
jikalau di hulu airnya keruh, tak dapat tidak di hilirnya keruh juga
jiwa bergantung di ujung rambut
jinak-jinak merpati
jual sutra beli mastuli
jung pecah yu yang kenyang
jung satu, nakhoda dua
kacang lupa akan kulitnya
kadok naik junjung
kail sebentuk, umpan seekor, sekali putus, sehari berhanyut
kain basah kering di pinggang
kain dalam lipatan
kain lama dicampak buang, kain baru pula dicari
kain pendinding miang, uang pendinding malu
kain sehelai berganti-ganti
kaki naik, kepala turun
kaki terdorong badan merasa, lidah terdorong emas padahannya
kaki untut dipakaikan gelang
kalah jadi abu, menang jadi arang
kalau bangkai galikan kuburnya, kalau hidup sediakan buaiannya
kalau getah meleleh, kalau daun melayang
kalau guru makan berdiri, maka murid makan berlari
kalau kena tampar, biar dengan tangan yang pakai cincin, kalau kena tendang, biar dengan kaki yang pakai kasut
kalau kubuka tempayan budu, baharu tahu
kalau laba bercikun-cikun, buruk diberi tahu orang
kalau menampi jangan tumpah padinya
kalau pandai menggulai, badar jadi tenggiri
kalau pandai menggulai badar pun menjadi tenggiri
kalau pandai meniti buih, selamat badan sampai ke seberang
kalau sorok lebih dahulu daripada tokok, tidak mati babi
kalau tak ada angin, takkan pokok bergoyang
kalau takut dilimbur pasang, jangan berumah di tepi pantai
kapak menelan beliung
kapal besar ditunda jongkong
kapal satu nakhoda dua
karam berdua, basah seorang
karam berdua basah seorang
karam sambal oleh belacan
karam tidak berair
kasih ibu sepanjang jalan, kasih anak sepanjang penggalan
kata berjawab, gayung bersambut
kata dahulu bertepati, kata kemudian kata bercari
katak hendak jadi lembu
kawan gelak banyak, kawan menangis jarang bersua
ke bukit sama mendaki, ke lurah sama menurun
ke gunung tak dapat angin
ke hulu kena bubu, ke hilir kena tengkalak
ke hulu menongkah surut, ke hilir menongkah pasang
ke langit tak sampai, ke bumi tak nyata
ke mana angin yang deras ke situ condongnya
ke mana condong, ke mana rebah
ke mana dialih, lesung berdedak juga
ke mana kelok lilin, ke sana kelok loyang
ke mana tumpah hujan dari bubungan, kalau tidak ke cucuran atap
ke mudik tentu hulunya, ke hilir tentu muaranya
ke sawah berlumpur ke ladang berarang
ke sawah tidak berlubuk, ke ladang tidak berarang
ke sawah tidak berluluk, ke ladang tidak berarang
kecil dikandung ibu, besar dikandung adat, mati dikandung tanah
kecil tapak tangan, nyiru ditadahkan
kecil-kecil anak kalau sudah besar onak
kecil-kecil cabai rawit
kelam bagai malam dua puluh tujuh
keledai hendak dijadikan kuda
kelekatu hendak terbang ke langit
keli dua selubang
kelihatan asam kelatnya
kelik-kelik dalam baju
kemiri jatuh ke pangkalnya
kena kelikir
kena pedang bermata dua
kena sepak belakang
kendur menyusut, tegang memutus
kepak singkat, terbang hendak tinggi
kera kena belacan
kera men-jadi monyet
kera menegurkan tahinya
kera menjadi monyet
keras bagai batu, tinggi bagai bukit
keras ditakik, lunak disudu
kerat rotan, patah arang
kerbau menanduk anak
kerbau punya susu, sapi punya nama
kerbau runcing tanduk
kerbau seratus dapat digembalakan, manusia seorang tiada terkawal
kerosok ular di rumpun bambu
kesat daun pimping
kesturi mati karena baunya
ketahuan hina mulianya
ketam menyuruhkan anaknya berjalan betul
kicang-kecoh ciak
kilat di dalam kilau
kini gatal besok digaruk
kita di pangkal merawal dia di ujung merawal
kita semua mati, tetapi kubur masing-masing
kodok dapat bunga sekuntum
koyak tak berbunyi
karena mata buta, karena hati mati
karena mulut bisa binasa
karena nila setitik, rusak susu sebelanga
karena pijat-pijat mati tuma
kuat burung karena sayap
kuat ketam karena sepit
kuat ketam karena sepit, kuat burung karena sayap, kuat ikan karena radai
kuat sepit karena kempa
kucing pergi tikus menari
kuda pelejang bukit
kudis menjadi tokak
kuman beri bertali
kuman di seberang lautan tampak, gajah di pelupuk mata tidak tampak
kundur tidak melata pergi, labu tidak melata mari
kuning oleh kunyit, hitam oleh arang
kurang taksir, hilang laba
kusut diselesaikan, keruh diperjernih
laba sama dibagi, rugi sama diterjuni
laba tertinggal, harta lingkap
labu dikerobok tikus
ladang yang berpunya
lading tajam sebelah
lagi lauk lagi nasi
lain bengkak, lain bernanah
lain bengkak, lain menanah
lain biduk, lain di galang
lain di mulut, lain di hati
lain dulang lain kaki, lain orang lain hati
lain gatal lain digaruk
lain ladang lain belalang, lain lubuk lain ikannya
lain padang lain belalang
lain sakit lain diobat, lain luka lain dibebat
lain yang diagak lain yang kena
laki pulang kelaparan, dagang lalu ditanakkan
laksana apung di tengah laut, dipukul ombak jatuh ke tepi
laksana bunga dedap, sungguh merah berbau tidak
laksana jentayu menantikan hujan
laksana manau, seribu kali embat haram tak patah
laksana mestika gamat
lalu penjahit, lalu kelindan
lalu penjahit lalu kelindan
lancar kaji karena diulang, pasar jalan karena diturut
langkas buah pepaya
lapuk oleh kain sehelai
laut budi tepian akal
laut ditembak, darat kena
laut ditimba akan kering
laut mana yang tak berombak, bumi mana yang tak ditimpa hujan
layar menimpa tiang
layang-layang putus talinya
lebih baik mati berkalang tanah daripada hidup bercermin bangkai
lebih berharga mutiara sebutir daripada pasir sepantai
lemak manis jangan ditelan, pahit jangan dimuntahkan
lemak penyelar daging
lembut seperti buah bemban
lempar batu sembunyi tangan
lengan bagai lilin dituang
lengan seperti sulur bakung
lepas bantal berganti tikar
lepas dari mulut harimau jatuh ke mulut buaya
lesung mencari alu
lewat dari manis, masam, lewat dari harum, busuk
licin bagai belut
licin karena minyak berminta, elok karena kain berselang
lidah tak bertulang
lihat anak pandang menantu
lihat anak, pandang menantu
limau masak sebelah, perahu karam sekerat
lonjak bagai labu dibenam
lopak jadi perigi
lubuk dalam, si kitang yang empunya
lubuk menjadi pantai, pantai menjadi lubuk
lulus jarum lulus kelindan
lulus tidak berselam, hilang tidak bercari
lunak disudu, keras ditakik
lunak disudu, keras menekik
lunak gigi dari lidah
lupa kacang akan kulitnya
lupak jadi perigi
lurus bagai piarit
lurus macam bendul
lulur bersetungging
mabuk di enggang lalu
madu satu tong, jika rembes, rembesnya pun madu jua
mahal membeli sukar dicari
main air basah, main api letup, main pisau luka
main kong kalingkong
makan bersabitkan
makan bubur panas-panas
makan hati berulam jantung
makan masak mentah
makan sudah terhidang, jamu belum jua datang
makan upas berulam racun
makanan enggang akan dimakan pipit
malam di bawah nyiur pinang orang, kata orang diturut
malam selimut embun, siang bertudung awan
malang celaka Raja Genggang, anak terbeli tunjang hilang
malang tak berbau
malang tak boleh ditolak, mujur tak boleh diraih
maling berteriak maling
malu berkayuh, perahu hanyut
malu tercoreng pada kening
mana busuk yang tidak berbau
mandi dalam cupak
mandi sedirus
manikam sudah menjadi sekam
manis daging
manis mulut nya bercakap seperti sa-utan manisan, di dalam bagai empedu
manusia mengikhtiarkan, Allah menakdirkan
manusia tahan kias, binatang tahan palu
manusia tertarik oleh tanah airnya, anjing tertarik oleh piringnya
mara hinggap mara terbang, enggang lalu ranting patah
mara jangan dipukat, rezeki jangan ditolak
marah akan tikus rengkiang dibakar
masak buah rumbia
masak di luar mentah di dalam
masih berbau pupuk jeringau
masin mulutnya
masuk dari kuping kiri keluar lewat kuping kanan
masuk kandang kambing mengembik, masuk kandang kerbau menguak
masuk ke telinga kanan, keluar ke telinga kiri
masuk lima keluar sepuluh
masuk meliang penjahit keluar meliang tabuh
masuk sarang harimau
masuk tak genap, keluar tak ganjil
masuk tiga, keluar empat
mata tidur, bantal terjaga
matahari itu bolehkah ditutup dengan nyiru
mati anak berkalang bapak, mati bapak berkalang anak
mati ayam, mati tungau
mati berkafan cindai
mati dicatuk katak
mati dikandung tanah
mati enau tinggal di rimba
mati gajah tidak dapat belalainya, mati harimau tidak dapat belangnya
mati kuang karena bunyi
mati kuau karena bunyinya
mati puyuh hendakkan ekor
mati rusa karena tanduknya
mati se ladang
mati tidak akan menyesal, luka tidak akan menyiuk
mati-mati mandi biar basah
mati-mati minyak biar licin
mayang menolak seludang
melanggar benang hitam
melangkahi ular
melanting menuju tampuk
melarat panjang
melekatkan kersik ke buluh
melepaskan anjing terjepit
meletakkan api di bubungan
melonjak badar, melonjak gerundang
melukut di tepi gantang
melukut tinggal sekam melayang
memakan habis-habis, menyuruh hilang-hilang
memakuk dengan punggung lading
memalit rembes menampung titik
memancing dalam belanga
memasang pelita tengah hari
memasukkan minyak tanah
membangkit batang terendam
membasuh najis dengan malu
membawakan cupak ke negeri orang
membekali budak lari
membeli kerbau bertuntun
membeli kerbau di padang
memberi lauk kepada orang membantai
membesarkan kerak nasi
membuang bunga ke jirat
membuang garam ke laut
membuat titian berakuk
membuka tambo lama
memegang besi panas
memikul di bahu, menjunjung di kepala
meminta tanduk kepada kuda
memperlapang kandang musang, mempersempit kandang ayam
mempertinggi semangat anjing
membakar tak hangus direndam tak basah
mempertinggi tempat jatuh, memperdalam tempat kena
menabur bijan ke tasik
menahan jerat di tempat genting
menahan lukah di penggentingan
menaikkan air ke gurun
menaikkan bandar sondai
menambak gunung, menggarami air laut
menanam mumbang
menanti putih gagak hitam
menantikan ara tak bergetah
menantikan kucing bertanduk
menantikan kuar bertelur
mencabik baju di dada
mencampakkan batu ke luar
mencari belalang atas akar
mencari jejak dalam air
mencari kutu dalam ijuk
mencari lantai terjungkat
mencari umbut dalam batu
mencari yang sehasta sejengkal
mencencang berlandasan, melompat bersetumpu
mencencang lauk tengah helat
mencencangkan lading patah
mencit seekor, penggada seratus
mencungkil kuman dengan alu
mendapat badai tertimbakan
mendapat panjang hidung
mendapat pisang berkubak
mendapat tebu rebah
mendapati tanah terbalik
mendengarkan cakap enggang
mendukung biawak hidup
menebas buluh serumpun
menegakkan benang basah
menegakkan sumpit tak berisi
menembak beralamat, berkata bertujuan
menepak nyamuk menjadi daki
menepik mata pedang
mengadu buku lidah
mengajar orang tua makan dadih
mengambil bungkal kurang
mengata dulang paku serpih, mengata orang awak yang lebih
mengebat erat-erat, buhul mati-mati
mengembalikan manikam ke dalam cembulnya
mengembang ketiak amis
menggantang anak ayam
menggaut laba dengan siku
menggeriak bagai anak nangui
menggolek batang terguling
menggunting dalam lipatan
menghadapkan bedil pulang
menghambat kerbau berlabuh
menghendaki urat lesung
mengisi gantang pesuk
mengisi perian bubus
mengorek lubang ulat
menguak-nguak bagai hidung gajah
mengukur baju di badan sendiri
mengungkit batu di bencah
mengunyah orang bergigi
mengairi sawah orang
mengalangkan leher, minta disembelih
menggali lubang menutup lubang
menggenggam erat membuhul mati
menggenggam tiada tiris
menghasta kain sarung
mengukir langit
mengusir asap, meninggalkan api
menjemur bangkai ke atas bukit
menjilat air liur
menjilat keluan bagai kerbau
menjilat ludah
menjolok sarang tabuhan
menjual bedil kepada lawan
menjual petai hampa
menjunjung sangkak ayam
menohok kawan seiring, menggunting dalam lipatan
mensiang yang baru dicari, kampil 'lah sudah dahulu
menumbuk di lesung, bertanak di periuk
menumbuk di periuk, bertanak di lesung
menunjukkan ilmu kepada orang menetak
menyandang lemang hangat orang
menyandang lukah tiga
menyenduk kuah dalam pengat
menyimpan embacang busuk
menyinggung mata bisul orang
menyisip padi dengan ilalang
menconteng arang di muka
mendabih menampung darah
mendapat sama berlaba, kehilangan sama merugi
mendebik mata parang
menjangkau sehabis tangan
menjalankan jarum halus
menjaring angin
merah padam muka nya
meraih pangkur ke dada
meraih pekung ke dada
merawal memulang bukit, cerana menengah kota
merayap-rayap seperti kangkung di ulak jamban
meremas santan di kuku
melanting menuju tampuk, berkata menuju benar
melakak kucing di dapur
meludah ke langit, muka juga yang basah
memancing di air keruh
memanjat bersengkelit
memanjat dedap
memanjat terkena seruda
memagar diri bagai aur
memahat di dalam baris, berkata dalam pusaka
memepas dalam belanga
memijakkan bayang-bayang
memilin kacang hendak mengebat, memilin jering hendak berisi
menambak gunung menggarami laut
menambak ke laut
menambat tidak bertali
menampalkan kersik ke buluh
menangguk di air keruh
menanak semua berasnya
menangis daun bangun-bangun hendak sama dengan hilir air
menempong menuju jih
menebang menuju pangkal, melanting menuju tampuk
menengadah ke langit hijau
menengadah membilang layar, menangkup membilang lantai
mengail berumpan, berkata bertipuan
mengail dalam belanga, menggunting dalam lipatan
mengais dulu maka makan
mengaut laba dengan siku
mengebat erat-erat, membuhul mati-mati
mengegungkan gung pesuk
mengepit kepala harimau
menimbang sama berat
menohok kawan seiring
menunggu angin lalu
menunggu laut kering
menyisih bagai antah
merantau di sudut dapur, merantau ke ujung bendul
merebus tak empuk
miang tergeser kena miang, terlanggar kena rabasnya
minta dedak kepada orang mengubik
minta sisik pada limbat
minta tulang kepada lintah
minum darah orang
minum serasa duri, makan serasa lilin, tidur tak lena, mandi tak basah
minyak habis sambal tak enak
misai bertaring bagai panglima, sebulan sekali tak membunuh orang
monyet mendapat bunga, adakah ia tahu akan faedah bunga itu?
mu-rah di mulut mahal di timbangan
mudah juga pada yang ada, sukar jua pada yang tidak
mudik menyongsong arus, hilir menyongsong pasang
mujur Pak Belang
mujur sepanjang hari malang sekejap mata
mujur tidak boleh diraih, malang tidak boleh ditolak
muka bagai ditampar dengan kulit babi
muka licin, ekor berkedal
mulut bagai ekor ayam diembus
mulut bajan boleh ditutup, mulut manusia tidak
mulut bau madu, pantat bawa sengat
mulut di mulut orang
mulut kamu, harimau kamu
mulut kapuk dapat ditutup, mulut orang tidak
mulut manis jangan percaya, lepas dari tangan jangan diharap
mulut manis mematahkan tulang
mulut satu lidah bertopang
mumbang ditebuk tupai
mumbang jatuh kelapa jatuh
murah di mulut, mahal di timbangan
musang berbulu ayam
musang terjun, lantai terjungkat
musim kemarau menghilirkan baluk
musuh dalam selimut
musuh jangan dicari-cari, bersua jangan dielakkan
nafsu nafsi, raja di mata, sultan di hati
napas tidak sampai ke hidung
nasi habis budi bersua
nasi sama ditanak, kerak dimakan seorang
nasi sendok tidak termakan
nasi sudah menjadi bubur
nasi tersaji di lutut
neraca palingan bungkal, hati palingan Tuhan
neraca yang palingan, bungkal yang piawai
nibung bangsai bertaruk muda
nyamuk mati gatal tak lepas
nyawa bergantung di ujung kuku
obat jauh penyakit hampir
ombak nya kedengaran, pasirnya tidak kelihatan
ombak yang kecil jangan diabaikan
orang berdendang di pentas nya
orang berdendang di pentasnya, orang beraja di hatinya
orang berdendang di pentasnya
orang bini beranak tak boleh disuruh
orang budi-budian, orang tabung seruas
orang dahaga diberi air
orang haus diberi air, orang lapar diberi nasi
orang mandi bersiselam, awak mandi bertimba
orang mengantuk disorongkan bantal
orang muda selendang dunia, orang kaya suka dimakan
orang penggamang mati jatuh
orang terpegang pada hulu nya, awak terpegang pada matanya
orang timpang jangan dicacat, ingat-ingat hari belakang
orang tua diajar makan pisang
pacet hendak menjadi ular
padang perahu di lautan, padang hati dipikirkan
padi dikebat dengan daunnya
padi masak, jagung mengupih
padi segenggam dengan senang hati lebih baik daripada padi selumbung dengan bersusah hati
padi sekapuk hampa, emas seperti loyang, kerbau sekandang jalang
padi selumbung dimakan orang banyak
pagar makan padi
pagar makan tanaman
pahit dahulu, manis kemudian
paksa tekukur, padi rebah, paksa tikus, lengkiang terbuka
panas setahun dihapuskan hujan sehari
panas tidak sampai petang
pandai minyak air
pandang jauh dilayangkan, pandang dekat ditukikkan
panjang langkah singkat permintaan
pantang kutu dicukur, pantang manusia dihinakan
parang gabus menjadi besi
pasang masuk muara
pasar jalan karena diturut, lancar kaji karena diulang
patah batu hatinya
patah kemudi dengan bam nya
patah kemudi dengan ebamnya
patah lidah alamat kalah, patah keris alamat mati
patah sayap bertongkat paruh
patah selera banyak makan
patah tongkat berjermang
patah tumbuh hilang berganti
payah-payah dilamun ombak, tercapai juga tanah tepi
paut sehasta tali
pecah anak buyung, tempayan ada
pecah buyung tempayan ada
pecah kapi, putus suai
pecah menanti sebab, retak menanti belah
pecak boleh dilayangkan, bulat boleh digulingkan, batu segiling pecak setepik
pejatian awak, kepantangan orang
pekak pembakar meriam
pelanduk melupakan jerat, tetapi jerat tidak melupakan pelanduk
pelanduk melupakan jerat, tetapi jerat tak melupakan pelanduk
pelepah bawah luruh, pelepah atas jangan gelak
pelesit dua sejinjang
pendekar elak jauh
pengaduan berdengar, salah bertimbang
pencarak benak orang
pepat kuku seperti bulan tiga hari
perahu bertambatan, dagang bertepatan
perahu papan bermuat intan
perahu sudah di tangan, perahu sudah di air
perang bermalaikat, sabung berjuara
pergi berempap, pulang eban
permata lekat di pangkur
perut panjang sejengkal
perkawinan tempat mati
pengayuh sama di tangan, perahu sama di air
perah santan di kuku
pikir dahulu pendapatan, sesal kemudian tidak berguna
pikir itu pelita hati
pinang pulang ke tampuk nya
pinggan tak retak nasi tak dingin
pipinya sebagai pauh dilayang
pipit meminang anak enggang
pipit menelan jagung
pipit pekak makan berhujan
pisang tidak buah dua kali
pijat-pijat menjadi kura-kura
pilih-pilih ruas, terpilih pada buku
potong hidung rusak muka
pucat seperti mayat
pucuk diremas dengan santan, urat direndam dengan tengguli, lamun peria pahit juga
pucuk layu disiram hujan
pukat terlabuh, ikan tak dapat
pukul anak sindir menantu
pukul anak, sindir menantu
pulau sudah lenyap, daratan sudah tenggelam
punggung parang sekalipun jika selalu diasah, akan tajam juga
punggur rebah belatuk menumpang mati
punggur rebah, belatuk menumpang mati
pusat jala pumpunan ikan
putih tapak nya lari
putus kelikir, rompong hidung
puyu di air jernih
raja adil raja disembah, raja lalim raja disanggah
rajin mengais tembolok berisi
ramai beragam, rimbun menyelara
rambut sama hitam hati masing-masing
rambut sama hitam, hati masing-masing
rasa tak mengapa hidung dikeluani
rasam minyak ke minyak, rasam air ke air
ragang gawe
rebung tak miang, bemban pula miang
rebung tidak jauh dari rumpun
redup atau panas keras
rendah gunung tinggi harapan
rentak sedegam, langkah sepijak
retak menanti belah
retak-retak mentimun
rindu jadi batasnya maka manis tak jadi cuka
ringan tulang, berat perut
rongkong menghadap mudik
rugi menentang laba, jerih menentang boleh
rumah gedang ketirisan
rumah sudah, tukul berbunyi
rumah terbakar tikus habis ke luar
rumput mencari kuda
runcing tanduk
rupa boleh diubah, tabiat dibawa mati
rupa harimau, hati tikus
rusak anak oleh menantu
rusak bangsa oleh laku
rusak bawang ditimpa jambak
rusak tapai karena ragi
sabung selepas hari petang
sakit kepala panjang rambut
sakit kepala panjang rambut, patah selera banyak makan
sakit menimpa, sesal terlambat
saksi ke lutut
salah cotok melantingkan
salai tidak berapi
sama lebur sama binasa
sambil berdendang biduk hilir
sambil berdiang nasi masak
sambil menyelam minum air
sambil selam minum air
sampah itu di tepi juga
sampai titik darah yang penghabisan
sampan ada pengayuh tidak
sampan rompong, pengayuh sompek
samun sakar berdarah tangan
sarak serasa hilang, bercerai serasa mati
sarap sehelai dituilkan, batu sebuah digulingkan
satu juga gendang berbunyi
satu nyawa, dua badan
satu sangkar dua burung
sauk kering-kering, membeli habis-habis
sawah seperempat piring, ke sawah sama dengan orang
sayap singkat, terbang hendak jauh
sayat sebelanga juga
sebagai anai-anai bubus
sebagai aur dengan rebung
sebagai ayam diasak malam
sebagai bisul hampir memecah
sebagai dawat dengan kertas
sebagai di rumah induk bako
sebagai duri landak
sebagai garam dengan asam
sebagai kepiting batu
sebagai kera dapat canggung
sebagai kunyit dengan kapur
sebagai minyak dengan air
sebagai orang mabuk gadung
sebagai pancang diguncang arus
sebagai petai sisa pengait
se hina semalu
sebab buah dikenal pohonnya
sebaik-baiknya hidup teraniaya
sebelum ajal berpantang mati
sebesar-besarnya bumi ditampar tak kena
sebusuk-busuk daging dikincah dimakan juga, seharum-harum tulang dibuang
secupak tak jadi segantang
sedangkan bah kapal tak hanyut, ini pula kemarau panjang
sedap dahulu pahit kemudian
sedepa jalan ke muka, setelempap jalan ke belakang
sedia payung sebelum hujan
sedikit hujan banyak yang basah
seekor kerbau berkubang, sekandang kena luluknya
seekor kerbau berlumpur semuanya berlabur
segala senang hati
segan bergalah hanyut serantau
segar dipakai, layu dibuang
sehabis kelahi teringat silat
sehari selembar benang, lama-lama menjadi sehelai kain
sehari selembar benang, lama-lama jadi sehelai kain
seikat bagai sirih, serumpun bagai serai
seiring bertukar jalan, seia bertukar sebut
sekali merengkuh dayung, dua tiga pulau terlampaui
sekam menjadi hampa berat
sekerat ular sekerat belut
seladang bagai panas di padang
selam air dalam tonggak
selama enggang mengeram
selama gagak hitam, selama air hilir
selama hayat dikandung badan
selama hujan akan panas jua
selama sipatung mandi
seliang bagai tebu, serumpun bagai serai
seludang menolakkan mayang
seluduk sama bungkuk, melompat sama patah
sembunyi puyuh
sembunyi tuma kepala tersuruk, ekor kelihatan
semisal udang dalam tangguk
sendok berdengar-dengar, nasi habis budi dapat
sendok besar tak mengenyang
senjata makan tuan
seorang ke hilir seorang ke mudik
seorang makan cempedak, semua kena getahnya
seorang makan nangka, semua kena getahnya
sepala-pala mandi biarlah basah
sepandai-pandai bungkus yang busuk berbau juga
sepandai-pandai tupai melompat, sekali waktu gawal juga
sepanjang tali beruk
sepasin dapat bersiang
sepenggalah matahari naik
seperti katak di bawah tempurung
serigala berbulu domba
serigala dengan anggur
sesak bagai ular tidur
sesak berundur-undur, hendak lari malu, hendak menghambat tak lalu
sesak undang kepada yang runcing tiada dapat bertenggang lagi
sesal dahulu yang bertuah, sesal kemudian yang celaka
sesat surut, terlangkah kembali
setali tiga uang
setinggi-tinggi bangau terbang, surutnya ke kubangan
setinggi-tinggi melambung, surutnya ke tanah juga
searah bertukar jalan
seciap bak ayam, sedencing bak besi
sedatar saja lurah dengan bukit
segenggam digunungkan, setitik dilautkan
sehina semalu
seidas bagai benang, sebentuk bagai cincin
sekebat bagai sirih
sekepal menjadi gunung, setitik menjadi laut
sekudung limbat, sekudung lintah
sekutuk beras basah
selangkas betik berbuah
selapik seketiduran
sepandai-pandai tupai melompat, sekali gawal juga
setapak jangan lalu, setapak jangan surut
setempuh lalu, sebondong surut
seukur mata dengan telinga
sia-sia menjaring angin, terasa ada tertangkap tidak
sia-sia negeri alah
sia-sia utang tumbuh
siapa berkotek, siapa bertelur
siapa gatal, dialah menggaruk
siapa lama tahan, menang
siapa luka siapa menyiuk
siapa makan lada, ialah berasa pedas
siapa menjala, siapa terjun
siapa melejang siap patah
siapa pun jadi raja, tanganku ke dahi juga
siapa yang gatal, dialah yang menggaruk
siar bakar berpuntung suluh
sigai dua segeragai
silap mata pecah kepala
singkat diulas panjang dikerat
singkat tidak terluas, panjang tidak terkerat
siput memuji buntut
sirih naik junjungan patah
sirih pulang ke gagang
sokong membawa rebah
seperti Belanda minta tanah, diberi kuku hendak menggarut
seperti Cina karam
seperti air basuh tangan
seperti anjing bercawat ekor
seperti antan pencungkil duri
seperti api dalam sekam
seperti ayam pulang ke pautan
seperti batang mengkudu, dahulu dengan bunga
seperti belanda kesiangan
seperti belanda minta tanah
seperti belut pulang ke lumpur
seperti beranak besar hidung
seperti bertih direndang
seperti biji saga rambat di atas talam
seperti birah dengan keladi
seperti birah tidak berurat
seperti birah tumbuh di tepi lesung
seperti bisai makan sepinggan
seperti buah bemban masak
seperti buah kedempung, di luar berisi di dalam kosong
seperti bujuk lepas dari bubu
seperti buku gaharu
seperti burung gagak pulang ke benua
seperti cacing kepanasan
seperti cincin dengan permata
seperti ditempuh gajah lalu
seperti elang menyongsong angin
seperti embun di atas daun
seperti embun di ujung rumput
seperti gadis jolong bersubang, bujang jolong bekerja
seperti gadis sudah berlaki
seperti gajah dengan sengkela nya
seperti gajah masuk kampung
seperti gergaji dua mata
seperti gerundang yang kekeringan
seperti gerup dengan sisir
seperti gula dalam mulut
seperti gunting makan di ujung
seperti harimau menyembunyikan kuku
seperti ikan baung dekat pemandian
seperti ikan dalam air
seperti ikan dalam belat
seperti ikan dalam tebat
seperti ikan kena tuba
seperti itik mendengar guntur
seperti janggut pulang ke dagu
seperti kambing dikupas hidup-hidup
seperti kambing putus tali
seperti katak ditimpa kemarau
seperti kedangkan dengan caping
seperti kelekatu masuk api
seperti kera dapat bunga
seperti kera dengan monyet
seperti kerbau dicocok hidung
seperti keroncor dengan belangkas
seperti kodok ditimpa kemarau
seperti kucing dibawakan lidi
seperti kuda lepas dari pingitan
seperti labu dibenam
seperti lampu kekurangan minyak
seperti lebah, mulut membawa madu, pantat membawa sengat
seperti lepat dengan daun
seperti lipas kudung
seperti lonjak alu penumbuk padi
seperti mayat ditegakkan
seperti melukut di tepi gantang
seperti memegang tali layang-layang
seperti menangkap ikan dalam belanga
seperti menanti orang dahulu, mengejar orang kemudian
seperti menating minyak penuh
seperti menghilang manau
seperti menepung tiada berberas
seperti misai pulang ke bibir
seperti orang kecabaian
seperti orang mati jika tiada orang mengangkat bila akan bergerak
seperti panji-panji, ditiup angin berkibar-kibaran
seperti parang bermata dua
seperti pikat kehilangan mata
seperti pinang dibelah dua
seperti pinang pulang ke tampuknya
seperti pinggan dengan mangkuk salah sedikit hendak berantuk
seperti pipit menelan jagung
seperti polong kena sembur
seperti pungguk merindukan bulan
seperti rabuk dengan api
seperti rusa kena tambat
seperti rusa masuk kampung
seperti santan dengan tengguli
seperti sayur dengan rumput
seperti sebuah biji sesat dalam rumput
seperti sengkalan tak sudah
seperti siang dengan malam
seperti tikus jatuh di beras
seperti tikus masuk perangkap
seperti tikus masuk rumah
seperti toman makan anak
seperti ular mengutik-ngutik ekor
suarang ditagih, sekutu dibelah
suaranya seperti membelah betung
sudah arang-arang hendak minyak pula
sudah basah kehujanan
sudah bertarah berdongkol pula
sudah beruban baru berguam
sudah biasa makan emping
sudah biasa makan kerak
sudah dapat gading bertuah, tanduk tiada berguna lagi
sudah di depan mata
sudah dieban dihela pula
sudah dikecek, dikecong pula
sudah genap bilangannya
sudah jatuh ditimpa tangga
sudah kenyang makan kerak
sudah lulus maka hendak melantai
sudah makan, bismillah
sudah masuk angin
sudah mati kutu nya
sudah mengilang membajak pula
sudah panas berbaju pula
sudah panjang langkahnya
sudah se asam segaramnya
sudah seasam se garam nya
sudah tahu peria pahit
sudah terantuk, baru tengadah
sudah terlalu hilir malam, apa hendak dikata lagi
sudah terantuk baru tengadah
sudah tidak sudu oleh angsa, baharu diberikan kepada itik
sukar kaji pada orang alim, sukar uang pada orang kaya
sukat air menjadi batu
sukat penuh sudah
suku tak boleh dianjak, malu tak boleh diagih
sumur digali air terbit
sungai sambil mandi
sungguhpun kawat yang dibentuk, ikan di laut yang diadang
surat atas batu
surat di atas air
surih bak sepasin, berjejak bak berkik, berbau bak embacang
suruk hilang-hilang, memakan habis-habis
sutan di mata beraja di hati
syariat palu-memalu, hakikat balas-membalas
syariat palu-memalu, pada hakikat nya adalah balas-membalas
tabuhan meminang anak labah-labah
tahan jerat sorong kepala
tahu asam garamnya
tahu di angin berkisar
tahu di angin turun naik
tahu di asin garam
tahu di dalam lubuk
tahu makan tahu simpan
tak ada beras yang akan ditanak
tak ada gading yang tak retak
tak ada guruh bagi orang pekak, tak ada kilat bagi orang buta
tak ada kusut yang tak selesai
tak ada laut yang tak berombak
tak ada padi yang bernas setangkai
tak ada pendekar yang tak bulus
tak air talang dipancung
tak akan terlawan buaya menyelam air
tak beras antah dikisik
tak boleh bertemu roma
tak emas bungkal diasah
tak jauh rebung dari rumpun nya
tak kan lari gunung dikejar, hilang kabut tampaklah dia
tak lalu dandang di air, di gurun ditanjakkan
tak lapuk di hujan, tak lekang di panas
tak lekang oleh panas
tak lekang oleh panas, tak lapuk oleh hujan
tak putus dirundung malang
tak tanduk telinga dipulas
tak tentu hilir mudiknya
tak tentu hilir nya, tidak berketentuan hulu hilir nya
tak tentu kepala ekornya
tak terkayuhkan lagi biduk hilir
takut akan lumpur, lari ke duri
takut di hantu, terpeluk ke bangkai
takut titik lalu tumpah
talam dua muka
tali busur tidak selamanya dapat diregang
tali jangan putus, kaitan jangan rekah
tali putus keluan putus
tali tiga lembar tak suang putus
tali yang tiga lembar itu tak suang-suang putus
tampak tembelang nya
tampuk bertangkai
tampuk nya masih bergetah
tanah lembah kandungan air, kayu bengkok titian kera
tanam lalang tak akan tumbuh padi
tanduk di berkas
tanduk di kepala tak dapat digelengkan
tangan kanan jangan percaya akan tangan kiri
tangan mencencang bahu memikul
tangan menggenggam tangan
tangguk lerek dengan bingkainya
tangguk rapat, keruntung bubus
tandang ke surau
tandang membawa lapik
tarik muka dua belas
taruh beras dalam padi
tebu masuk di mulut gajah
tebu setuntung masuk geraham gajah
tegak pada yang datang
tegak sama tinggi, duduk sama rendah
teguh paling, duduk berkisar
telaga di bawah gunung
telaga mencari timba
telah bau bagai embacang
telah berasap hidungnya
telah busuk maka dipeda
telah dapat gading bertuah, terbuang tanduk kerbau mati
telah dijual, maka dibeli
telah jadi indarus
telah karam maka tertimpa
telah mati yang bergading
telah mengguncang girik
telah meraba-raba tepi kain
telinga rabit dipasang subang
teluknya dalam, rantau nya sakti
telunjuk lurus kelingking berkait
telunjuk lurus, kelingking berkait
telur di ujung tanduk
telur sesangkak, pecah satu pecah semua
tempat makan jangan dibenahi
tempayan tertiarap dalam air
tengah tapak bayang-bayang
tepuk berbalas, alang berjawat
tepuk perut tanya selera
tepung kena ragi
terajar pada banting pincang
teralang-alang bagaikan sampah dalam mata
terang kabut, teduh hujan
terapung tak hanyut, terendam tak basah
teras terunjam, gubal melayang
terban bumi tempat berpijak
terbang bertumpu hinggap mencekam
tercincang puar bergerak andilau
tercubit paha kiri, paha kanan pun berasa sakit
terdesak padang ke rimba
terdorong gajah karena besarnya
terentak ruas ke buku
tergantung tidak bertali
terikat kaki tangan
terlampau dikadang, mentah
terlongsong perahu boleh balik, terlongsong cakap tak boleh balik
termakan di rambut
termakan di sadah
terpasang jerat halus
terpecak peluh di muka
terpegang di abu hangat
terpijak bara hangat
terpijak benang arang hitam tampak
tersendeng-sendeng bagai sepat di bawah mengkuang
tersingit-singit bagai katung di bawah reba
tertambat hati terpaut sayang
tertangkap basah
tertangkap di ikan kalang
tertumbuk biduk dikelokkan, tertumbuk kata dipikiri
terapung sama hanyut, terendam sama basah
tercacak seperti lembing tergadai
terconteng arang di muka
tergerenyeng-gerenyeng bagai anjing disua antan
terjual terbeli
terkalang di mata, terasa di hati
terkilan di hati, terkalang di mata
terpeluk di batang dedap
tertangkup sama termakan tanah, telentang sama terminum air
tertelentang berisi air, tertiarap berisi tanah
tertelentang sama terminum air, tertelungkup sama termakan tanah
tertimbun dikais, terbenam diselam
teperlus maka hendak menutup lubang
tiada berketentuan hulu hilirnya
tiada kayu janjang dikeping
tiada kubang yang tiada berkodok
tiada mengetahui hulu hilir nya
tiada raja menolak sembah
tiada terbawa sekam segantang
tiada terempang peluru oleh lalang
tiang pandak hendak menyamai tiang panjang
tiba di perut dikempiskan, tiba di mata dipicingkan, tiba di dada dibusungkan
tiba di rusuk menjeriau
tidak ada orang menggaruk ke luar badan
tidak berluluk mengambil cekarau
tidak hujan lagi becek, ini pula hujan
tidak kekal bunga karang
tidak kelih mau tengok
tidak makan benang
tidak makan siku-siku
tidak mati oleh belanda
tidak tahu antah terkunyah
tidak terindang dedak basah
tidur bertilam air mata
tidur bertilam pasir
tidur tak lelap, makan tak kenyang
timur beralih ke sebelah barat
tinggal kelopak salak
tinggal sehelai sepinggang
tinggi banir tempat berlindung
tinggi gelepur rendah laga
tinggi terbawa oleh ruas nya
tingkalak menghadap mudik, lukah menghadap hilir
tohok lembing ke semak
tohok raja tidak dapat dielakkan
tolak tangga berayun kaki
tong kosong nyaring bunyinya
tongkat membawa rebah
tuah anjing, celaka kuda
tuah ayam boleh dilihat, tuah manusia siapa tahu
tuah melambung tinggi, celaka menimpa, celaka sebesar gunung
tuak terbeli, tunjang hilang
tuba habis, ikan tak dapat
tunggang hilang berani mati
tunggang hilang tak hilang
ucap habis niat sampai
udang dalam tangguk
udang hendak mengatai ikan
udang tak tahu bungkuk nya
udang tak tahu di bungkuknya
uir-uir minta getah
ujung jarum halus kelindan sutera
ulam mencari sambal
ular menyusur akar
umpama air digenggam tiada tiris
umpama ayakan dawai
umpan habis, ikan tak kena
umpan seumpan, kail sebentuk
umpat tidak membunuh, puji tidak mengenyang
unjuk yang tidak diberikan
untung ada tuah tiada
untung sabut timbul, untung batu tenggelam
upah lalu bandar tak masuk
usahlah teman dimandi pagi
usang dibarui, lapuk dikajangi
usul menunjukkan asal
utang emas boleh dibayar utang budi dibawa mati
utang emas dapat dibayar, utang budi dibawa mati
wau melawan angin
yang berbaris yang berpahat, yang bertakuk yang bertebang
yang bertakuk yang ditebang, yang bergaris yang dipahat
yang bujur lalu, yang terlintang patah
yang bulat datang bergolek, yang pipih datang melayang
yang dikejar tiada dapat, yang dikandung berceceran
yang dikejar tidak dapat, yang dikandung berceceran
yang enggang sama enggang juga, yang pipit sama pipit juga
yang lahir menunjukkan yang batin
yang merah saga, yang kurik kundi
yang pipit sama pipit, yang enggang sama enggang
yang rebah ditindih
yang se cupak takkan jadi segantang
yang sukat tak akan jadi segantang
yang teguh disokong, yang rebah ditindih
zaman beralih musim bertukar
