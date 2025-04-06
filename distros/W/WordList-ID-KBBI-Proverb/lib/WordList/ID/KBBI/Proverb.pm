package WordList::ID::KBBI::Proverb;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-20'; # DATE
our $DIST = 'WordList-ID-KBBI-Proverb'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::RandomSeekPick';

our %STATS = ("num_words",400,"num_words_contain_nonword_chars",400,"num_words_contains_nonword_chars",400,"avg_word_len",32.7475,"longest_word_len",218,"shortest_word_len",11,"num_words_contain_unicode",0,"num_words_contains_whitespace",400,"num_words_contains_unicode",0,"num_words_contain_whitespace",400); # STATS

1;
# ABSTRACT: Indonesian proverb (peribahasa) entries from Kamus Besar Bahasa Indonesia (KBBI), 3e

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::KBBI::Proverb - Indonesian proverb (peribahasa) entries from Kamus Besar Bahasa Indonesia (KBBI), 3e

=head1 VERSION

This document describes version 0.001 of WordList::ID::KBBI::Proverb (from Perl distribution WordList-ID-KBBI-Proverb), released on 2024-11-20.

=head1 SYNOPSIS

 use WordList::ID::KBBI::Proverb;

 my $wl = WordList::ID::KBBI::Proverb->new;

 # Pick a (or several) random word(s) from the list
 my ($word) = $wl->pick;
 my ($word) = $wl->pick(1);  # ditto
 my @words  = $wl->pick(3);  # no duplicates

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }  # case-sensitive

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Iterate
 my $first_word = $wl->first_word;
 while (defined(my $word = $wl->next_word)) { ... }

 # Get all the words (beware, some wordlists are *huge*)
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

This wordlist uses random-seek picking, which gives higher probability for
longer words. See L<File::RandomLine> for more details.

=head1 WORDLIST STATISTICS

 +----------------------------------+---------+
 | key                              | value   |
 +----------------------------------+---------+
 | avg_word_len                     | 32.7475 |
 | longest_word_len                 | 218     |
 | num_words                        | 400     |
 | num_words_contain_nonword_chars  | 400     |
 | num_words_contain_unicode        | 0       |
 | num_words_contain_whitespace     | 400     |
 | num_words_contains_nonword_chars | 400     |
 | num_words_contains_unicode       | 0       |
 | num_words_contains_whitespace    | 400     |
 | shortest_word_len                | 11      |
 +----------------------------------+---------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ID-KBBI-Proverb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ID-KBBI-Proverb>.

=head1 SEE ALSO

L<ArrayData::Lingua::Word::ID::KBBI::Proverb> contains the same data.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-ID-KBBI-Proverb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
ada biduk serempu pula
ada gula ada semut
adat diisi, lembaga dituang
adat hidup tolong-menolong, syariat palu-memalu
air beriak tanda tak dalam
air cucuran atap jatuh ke pelimbahan juga
air lalu kubang tohor
air tenang menghanyutkan
alah limau oleh benalu
asal ada sama di hati, gajah terantai boleh dilepaskan
asal berinsang , ikanlah
asal menugal adalah benih
ayam laga sekandang
bagai bersesah kain dapat
bagai bertanak di kuali
bagai berumah di tepi tebing
bagai kapal tidak bertiang
bagai menggenggam bara, terasa hangat dilepaskan
bagai menghela rambut dl tepung
bagai pucuk pisang didiang
bagaimana ditanam begitulah dituai
bagaimana ditanam, begitulah dituai
baik berjagung-jagung sementara padi belum masak
baik rupa sepemandangan , baik bunyi sependengaran
bak menanti orang dahulu, bak melalah orang kudian
banyak menelan garam hidup
barang siapa yg berketuk ialah yg bertelur
barang tergenggam jatuh terlepas
baru (belum) beranjur sudah tertarung
batang betung beruas-ruas
bayang-bayang disangka tubuh
bayang-bayang sepanjang badan
bayang-bayang tidak sepanjang badan
beban berat senggulung batu
becermin di air keruh
belum beranak sudah ditimang
belum beranak sudah ditimang belum duduk sudah berlunjur
belum bergigi hendak mengunyah (menggigit)
belum bertaji hendak berkokok
belum diajun sudah tertarung
belum duduk sudah mengunjur
belum tahu di pedas lada
beraja di hati, bersultan di mata, ( beraja di mata, bersultan di hati)
berakit-rakit ke hulu, berenang-renang ke tepian
berarak tidak berlari
berat sama dipikul, ringan sama dijinjing
berbilang dr esa, mengaji dr alif
bercerai tidak bertalak (kalau bercerai tidak usah menjatuhkan talak)
berebut lontong tanpa isi
berendam sesayak air, berpaut sejengkal tali
bergaduk diri, saku-saku diterbangkan angin
bergantung pd tali rapuh
bergantung tidak bertali (sehasta tali)
berguru dahulu sebelum bergurau
berhakim kpd beruk
berhati baja, berurat kawat
berhitung nasib peruntungan
berjalan selangkah menghadap surut, berkata sepatah dipikirkan
berjanjang naik, bertangga turun
berkain tiga hasta; berkain tak cukup sebelit pinggang; tak berkain sehelai benang)
berkata siang melihat-lihat, berkata malam mendengar-dengar
berkayuh sambil ke hilir
berkelahi di ekor alahan
berkelahi dl kepuk
berkelahi dl mimpi
berkemudi di haluan, bergilir ke buritan
berkeras tidak berkeris
berkering air liur
berketuk di luar sangkar, bertanam di luar pagar
berkocak tanda tak penuh
berlaki anak semang
berlayar atas angin
berlayar bernakhoda, berjalan dng yg tua
berlayar sambil memapan
berlidah di lidah orang
berlurah di balik pendakian
bernapas ke luar badan
berpilin-pilin bagai kelindan
berserah kabil
bertabur bijan ke tasik
bertali boleh dieret, bertampuk boleh dijinjing
bertanam biji hampa
bertanam tebu di bibir
bertanjak baru bertinjau
berteduh di bawah betung
bertemu ruas dng buku
bertepuk sebelah tangan
bertepuk sebelah tangan tidak akan berbunyi
bertitah lalu sembah berlaku
bertohor air liur
bertopang pangkal seia
biduk lalu kiambang bertaut
buah tangisan beruk
buruk muka cermin dibelah
cakap berlauk (-lauk), makan dng sambal lada
calak ganti asah (menanti tukang belum datang)
carik-carik bulu ayam lama-lama bercantum juga
cekak, bercekak henti, silat terkenang
dalam laut boleh diajuk , dalam hati siapa tahu
dangkal telah keseberangan, dalam telah keajukan
datang tak berjemput, pulang tak berhantar
datang tampak muka, pulang tampak punggung
datang tidak berjemput, pulang tidak berantar
di manakah berteras kayu mahang
dialas bagai memengat
diam penggali berkarat, diam ubi berisi
diam-diam ubi (berisi)
dianjak layu, dibubut mati
diasak layu, dicabut mati
diberi berkuku hendak mencekam
diberi berkuku hendak mencengkam
diberi bertali panjang
diberi betis hendak paha
diberi sejari hendak setelempap
diberi sejengkal hendak sehasta diberi sehasta hendak sedepa
dibujuk ia menangis , ditendang ia tertawa
diiringkan menyepak, dikemudiankan menanduk
dikatakan berhuma lebar, sesapan di halaman
dikati sama berat, diuji sama merah
dikerkah dia menampar pipi, dibakar dia melilit puntung
dipanggang tiada angus
disangka tiada akan mengaram , ombak yg kecil diabaikan
ditindih yg berat, dililit yg panjang
diuji sama merah, dl hati (ditail) sama berat
dr semak ke belukar
duduk berkisar , tegak berpaling
duduk seorang bersempit-sempit, duduk bersama berlapang-lapang
emping berserak hari hujan
endap di balik lalang sehelai
gamak-gamak spt menyambal
habis beralur maka beralu-alu
habis manis sepah dibuang
hati bagai baling-baling (- di atas bukit)
hati gajah sama dilapah , hati tuma (tungau) sama dicecah
hendak menangguk ikan, tertangguk batang
hendak menggaruk tidak berkuku
hidup bertimba uang
hidup dua muara
hujan tempat berteduh , panas tempat berlindung
hutan sudah terambah , teratak sudah tertegak
iba akan kacang sebuah, tak jadi memengat
ibarat menegakkan benang basah
indah kabar dr rupa
ingat sebelum kena, berhemat sebelum habis
jangan diperlelarkan timba perigi, kalau tak putus genting
jauh berjalan banyak dilihat
jauh panggang dr api
jika langkah sudah terlangkahkan , berpantang dihela surut
jinak-jinak merpati
kain pendinding miang, uang pendinding malu
kaki terdorong badan merasa, lidah terdorong emas padahannya
kalau getah meleleh, kalau daun melayang
kalau menampi jangan tumpah padinya
kalau pandai menggulai badar pun menjadi tenggiri
kalau takut dilimbur pasang, jangan berumah di tepi pantai
karam berdua basah seorang
kasih ibu sepanjang jalan, kasih anak sepanjang penggalan
kata dahulu bertepati, kata kemudian kata bercari
ke hulu menongkah surut, ke hilir menongkah pasang
ke sawah berlumpur ke ladang berarang
ke sawah tidak berluluk , ke ladang tidak berarang
kecil dikandung ibu, besar dikandung adat, mati dikandung tanah
kecil-kecil cabai rawit
keluar tak mengganjilkan , masuk tak menggenapkan (masuk tidak genap, keluar tidak ganjil)
krn pijat-pijat mati tuma
kuda pelejang bukit
kura-kura (hendak) memanjat kayu
lain bengkak, lain menanah
lain ladang lain belalang, lain lubuk lain ikannya
lain yg diagak lain yg kena
laki pulang kelaparan, dagang lalu ditanakkan
lalu penjahit lalu kelindan
lalu penjahit, lalu kelindan
layang-layang putus talinya
lebih baik mati berkalang tanah dp hidup bercermin bangkai
lempar batu sembunyi tangan
lulur bersetungging
lunak disudu, keras menekik
lunak gigi dr lidah
mahal membeli sukar dicari
makan hati berulam jantung
malu tercoreng di kening (dahi)
mati dikandung tanah
melakak kucing di dapur
melanting menuju tampuk, berkata menuju benar
meludah ke langit, muka juga yg basah
memagar diri bagai aur
memahat di dl baris, berkata dl pusaka
memakan habis-habis , menyuruh hilang-hilang
memalit rembes menampung titik
memancing di air keruh
memanjat bersengkelit
memanjat dedap
memanjat terkena seruda
membakar tak hangus direndam tak basah
membeli kerbau bertuntun
membuang bunga ke jirat
membuang garam ke laut
membuat titian berakuk
memepas dl belanga
memijakkan bayang-bayang
memilin kacang hendak mengebat, memilin jering hendak berisi
mempertinggi tempat jatuh, memperdalam tempat kena
menambak gunung menggarami laut
menambak gunung, menggarami air laut
menambak ke laut
menambat tidak bertali
menampalkan kersik ke buluh
menanak semua berasnya
menangguk di air keruh
menangis daun bangun-bangun hendak sama dng hilir air
menantikan kuar bertelur
menantikan kucing bertanduk
mencabik baju di dada
mencari yg sehasta sejengkal
mencencang berlandasan, melompat bersetumpu
mencencang berlandasan, melompat bersetumpu (bertumpuan)
menconteng arang di muka
mendabih menampung darah
mendapat badai tertimbakan
mendapat pisang berkubak
mendapat sama berlaba, kehilangan sama merugi
mendebik mata parang
menebang menuju pangkal, melanting menuju tampuk
menembak beralamat , berkata bertujuan
menempong menuju jih
menengadah ke langit hijau
menengadah membilang layar, menangkup membilang lantai
mengail berumpan, berkata bertipuan
mengail dl belanga, menggunting dl lipatan
mengairi sawah orang
mengais dulu maka makan
mengalangkan leher, minta disembelih
mengaut laba dng siku
mengebat erat-erat, membuhul mati-mati
mengegungkan gung pesuk
mengepit kepala harimau
menggali lubang menutup lubang
menggenggam erat membuhul mati
menggenggam tiada tiris
menggunting dl lipatan
menghasta kain sarung
mengukir langit
mengunyah orang bergigi
mengusir asap, meninggalkan api
menimbang sama berat
menjalankan jarum halus
menjangkau sehabis tangan
menjaring angin
menjolok sarang tabuhan
menohok kawan seiring
menohok kawan seiring , menggunting dl lipatan
menunggu angin lalu
menunggu laut kering
menyisih bagai antah
meraih pekung ke dada
merantau di sudut dapur, merantau ke ujung bendul
merapat sambil berlayar ( berlayar sambil memapan)
merebus tak empuk
muka licin, ekor berkedal
musuh dl selimut
nasi sudah menjadi bubur
orang berdendang di pentasnya
orang penggamang mati jatuh
patah tongkat berjermang
patah tumbuh hilang berganti
paut sehasta tali
payah-payah dilamun ombak, tercapai juga tanah tepi
pelanduk melupakan jerat, tetapi jerat tak melupakan pelanduk
pencarak benak orang
pengaduan berdengar, salah bertimbang
pengayuh sama di tangan, perahu sama di air
perah santan di kuku
pergi berempap , pulang eban
perkawinan tempat mati
pijat-pijat menjadi kura-kura
pilih-pilih ruas, terpilih pd buku
potong hidung rusak muka
pukul anak sindir menantu
pusat jala pumpunan ikan
ragang gawe
rajuk kpd yg kasih (sayang)
ramai beragam , rimbun menyelara
retak menanti belah
retak-retak mentimun
sambil berdendang biduk hilir
sambil berdiang nasi masak
sambil selam minum air
sbg ayam diasak malam
searah bertukar jalan
sebelum ajal berpantang mati
seciap bak ayam, sedencing bak besi
secupak tak jadi segantang
sedatar saja lurah dng bukit
seekor kerbau berkubang , sekandang kena luluknya
seekor kerbau berlumpur semuanya berlabur
segan (malu) mengayuh perahu hanyut
segan bergalah hanyut serantau
segenggam digunungkan, setitik dilautkan
sehari selembar benang, lama-lama jadi sehelai kain
sehina semalu
seidas bagai benang, sebentuk bagai cincin
seiring bertukar jalan (sekandang tidak sebau, seia bertukar sebut)
seiring bertukar jalan, seia bertukar sebut
sekebat bagai sirih
sekepal menjadi gunung, setitik menjadi laut
sekudung limbat, sekudung lintah
sekutuk beras basah
selam air dl tonggak
selama hayat dikandung badan
selangkas betik berbuah
selapik seketiduran
sepandai-pandai tupai melompat, sekali gawal juga
serumpun bagai serai, selubang (seliang) bagai tebu
setali tiga uang
setapak jangan lalu, setapak jangan surut
setempuh lalu, sebondong surut
setinggi-tinggi melambung , surutnya ke tanah juga
seukur mata dng telinga
siapa berkotek , siapa bertelur
siapa melejang siap patah
siapa menjala , siapa terjun
silap mata pecah kepala
singkat diulas panjang dikerat
sokong membawa rebah
spt ayam pulang ke pautan
spt cincin dng permata
spt janggut pulang ke dagu
spt kerbau dicocok hidung
spt kuda lepas dari pingitan
spt memegang tali layang-layang
spt menating minyak penuh
spt menepung tiada berberas
spt orang kecabaian
spt panji-panji , ditiup angin berkibar-kibaran
spt ular mengutik-ngutik ekor
subur krn dipupuk, besar krn diambak; (besar diambak , tinggi di anjung)
sudah bertarah berdongkol pula
sudah beruban baru berguam
sudah dapat gading bertuah , tanduk tiada berguna lagi
sudah dieban dihela pula
sudah dikecek , dikecong pula
sudah jatuh ditimpa tangga
sudah mengilang membajak pula
sudah terantuk baru tengadah
sungguhpun kawat yg dibentuk, ikan di laut yg diadang
tak ada pendekar yg tak bulus
tak kan lari gunung dikejar , hilang kabut tampaklah dia
tak lalu dandang di air, di gurun ditanjakkan
tak terkayuhkan lagi biduk hilir
tandang ke surau
tandang membawa lapik
tangan mencencang bahu memikul
tangan menetak (mencencang) bahu memikul
teguh paling , duduk berkisar
telah berasap hidungnya
telah dijual , maka dibeli
telah mati yg bergading
telinga rabit dipasang subang
telunjuk lurus, kelingking berkait
telur di ujung tanduk
teperlus maka hendak menutup lubang
terapung sama hanyut, terendam sama basah
terapung tak hanyut, terendam tak basah
tercacak spt lembing tergadai
terconteng arang di muka
tergantung tidak bertali
tergerenyeng-gerenyeng bagai anjing disua antan
terjual terbeli
terkalang di mata, terasa di hati
terkilan di hati, terkalang di mata
terlampau dikadang , mentah
terpeluk di batang dedap
tertangkup sama termakan tanah, telentang sama terminum air
tertelentang berisi air, tertiarap berisi tanah
tertelentang sama terminum air, tertelungkup sama termakan tanah
tertimbun dikais, terbenam diselam
tertumbuk biduk dikelokkan, tertumbuk kata dipikiri
tiada kubang yg tiada berkodok
tiada terempang peluru oleh lalang
tiba di rusuk menjeriau
tidak ada orang menggaruk ke luar badan
tidak berluluk mengambil cekarau
tidak terindang dedak basah
tidur bertilam air mata
tidur bertilam pasir
tinggal sehelai sepinggang
tuak terbeli, tunjang hilang
tunggang hilang berani mati
tunjal, menunjal v 1 menumpu atau menekankan kaki ketika hendak melompat; menjejakkan kaki (hendak berdiri dsb); 2 menunjuk dan menyentuh dng jari (biasanya dng jari telunjuk); jauh dapat ditunjuk, dekat dapat ditunjal
untung sabut timbul, untung batu tenggelam
usang dibarui, lapuk dikajangi
usul menunjukkan asal
yg berbaris yg berpahat , yg bertakuk yg bertebang
yg bertakuk yg ditebang, yg bergaris yg dipahat
yg bulat datang bergolek , yg pipih datang melayang
yg dikejar tiada dapat, yg dikandung berceceran
yg dikejar tidak dapat, yg dikandung berceceran
yg rebah ditindih
zaman beralih musim bertukar
