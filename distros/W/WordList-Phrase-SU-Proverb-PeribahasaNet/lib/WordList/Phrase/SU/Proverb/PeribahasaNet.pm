package WordList::Phrase::SU::Proverb::PeribahasaNet;

our $DATE = '2016-10-20'; # DATE
our $VERSION = '0.02'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("longest_word_len",149,"avg_word_len",22.8315789473684,"num_words_contains_nonword_chars",1312,"num_words_contains_unicode",2,"num_words_contains_whitespace",1306,"shortest_word_len",6,"num_words",1330); # STATS

1;
# ABSTRACT: Sundanese proverbs from peribahasa.net

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::SU::Proverb::PeribahasaNet - Sundanese proverbs from peribahasa.net

=head1 VERSION

This document describes version 0.02 of WordList::Phrase::SU::Proverb::PeribahasaNet (from Perl distribution WordList-Phrase-SU-Proverb-PeribahasaNet), released on 2016-10-20.

=head1 SYNOPSIS

 use WordList::Phrase::SU::Proverb::PeribahasaNet;

 my $wl = WordList::Phrase::SU::Proverb::PeribahasaNet->new;

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
 | avg_word_len                     | 22.8315789473684 |
 | longest_word_len                 | 149              |
 | num_words                        | 1330             |
 | num_words_contains_nonword_chars | 1312             |
 | num_words_contains_unicode       | 2                |
 | num_words_contains_whitespace    | 1306             |
 | shortest_word_len                | 6                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-SU-Proverb-PeribahasaNet>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-SU-Proverb-PeribahasaNet>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-SU-Proverb-PeribahasaNet>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<http://www.peribahasa.net/peribahasa-sunda.php>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
Abang-abang lambe
Abis bulan abis uang
Abong biwir teu diwengku
Abong biwir teu diwengku, abong letah teu tulangan
Abong letah teu tulangan
Adab biada
Adam lali tapel
Adat kakurung ku iga
Adean ku kuda beureum
Adep hidep
Adigung adiguna
Adil palamarta
Adu telu ampar tiga
Agul ku payung butut
Ahli leleb
Ajak jawa
Ajrihing gawe
Akal bulus
Akal keling
Akal koja
Aki-aki tujuh mulud
Aku panggung
Aku-aku angga
Alak paul
Alak-alak cumampaka
Alloh tara nanggeuy di bongkokna
Along-along bagja
Alus laur hade ome
Alus panggung
Ambek  nyedek tanaga midek
Ambek sadu santa budi
Ambekna sakulit bawang
Amis budi
Amis daging
Anak dua keur gumunda
Anak emas
Anak hiji keur gumeulis
Anak merak kukuncungan
Anak puputon
Anak tilu keur kumusut
Anggeus-anggeusan
Angin-anginan
Anjing ngagogogan kalong
Anjing nyampeurkeun paneunggeul
Anu burung diangklungan, anu gelo didogdogan, anu edan dikendangan
Apal cangkem
Ari darah supana, kudu dijaga catangna = ari diarah supana, kudu dipiara catangna
Ari umur tunggang gunung, angen-angen pecat sawed
Asa (ieu) aing uyah kidul
Asa bucat bisul
Asa dijual payu
Asa dina pangimpian
Asa dipupuk birus
Asa ditonjok congcot
Asa kabur pangacian
Asa kagunturan madu kaurugan menyan putih = asa kagunturan madu kaurungan menyan bodas
Asa katumbu umur = asa ditumbu umur
Asa kiamat
Asa nanggeuy endog beubeureumna = kawas nanggeuy endog beubeureumna
Asa nyanghulu ka jarian
Asa peunggas rancatan
Asa potong leungeun katuhu = asa pingges katahu
Asa rawing daun ceuli
Asa teu beungeutan
Asa tungkeb bumi alam
Asak warah
Atah adol
Atah anjang
Atah warah
Ateul biwir
Ateul dampal leungeun
Ateul putih badan bodas
Atung eneh-atung eneh (aé)
Aub payung, sabet sapon, sabasoba
Awak kawas badawang
Awak sabeulah
Awak sampayan (eun)
Awak satilas
Awet jaya awet ngora
Awet rajet
Awewe mah tara cari ka Batawi
Awewée(mah) dulang tinande
Aya astana sajeungkal
Aya bagja teu daulat
Aya buntutna
Aya di sihung maung
Aya gantar kakaitan
Aya garad =  boga garad
Aya jalan komo meuntas
Aya jodo pakokolot
Aya jurig tumpak kuda
Aya kelong newo-newo
Aya nu dianjing cai
Aya peurah
Aya pikir kpingburi = boga pikir kapingburi
Aya rengkolna
Ayak-ayak beas, nu badag moncor nu lembut nyangsang
Ayakan (mah) tara meunang kancra
Ayang-ayangan
Ayeuh ngora
Babalik pikir
Babateng jurit
Babon kapurba ku jago
Bacang pakewuh
Baleg tampele
Bali geusan ngajadi
Balik ngaran
Balung kulit kotok meuting
Balungbang timur, jalan gede sasapuan
Banda sasampiran nyawa gagaduhan
Banda tatalang raga
Bangbang kolentang
Banten ngamuk gajah meta
Banting tulang
Basa mah teu kudu meuli
Basa teh ciciren bangsa
Batok bulu eusi madu
Batok kohok piring semlek
Batu turun keusik naek
Batur ngaler ieu ngidul
Bau-bau sinduk
Beak beresih
Beak dengkak
Beak ka lebu-lebuna
Bear budi
Bebek ngoyor di sagara, rek nginum neangan cai
Beber layar tarik jangkar
Bedah bendungan
Belang bayah
Bengkok tikoro
Bengkung ngariung bongkok ngaronyok
Bentik curuk balas nunjuk
Beulah hoean
Beungeut nyanghareup ati mungkir
Beungeut si eta mah ruas bungbas
Beurat nyuhun beurat nanggung
Beureun paneureuy
Beurrrat birit
Beuteung anjingeun
Beuteung mutiktrik berekat meunang
Bilatung ninggang dage
Bilih aya tutus bengkung
Bisa ka bala la bale
Bisa mihapekeun maneh
Bisi aya ti cai geusan mandi
Biwir nyiru rombengeun
Biwir sambung lemek, suku sambung lengkah = suku sambung leumpang, biwir sambung lemek
Bluk nyuuh blak nangkarak
Bobo sapanon carang sapakan
Bobor karahayuan
Bobot panganyon timbang taraju
Bodo aleoh
Bodo katotoloyoh
Boga pikir rangkepan
Boga sawah saicak
Bogoh nogencang
Bohong dirawun
Bojo denok sawah ledok
Bongkok meongeun
Bonteng ngalawan kadu
Borang ku surak
Bosongot bade amprotan
Bru di juru bro di panto
Buah ati
Bubu ngawaregan cocok
Buburuh nyatu diupah beas
Budah laut
Budak bau jaringao
Budak olol leho (keneh)
Budak redok hulu
Budi santri, legeg lebe, ari lampah euwah-euwah
Bujang jengglengan
Bujang tarangna
Bulan alaeun
Buluh taneuh
Bumi tacan nyungcung
Buncir leuit loba duit
Bungbulang tunda
Buntu laku
Buntut kasiran
Bur beureum bur hideung, hurung nangtung siang leumpang
Buruk-buruk papan jati
Burung palung dulur sorangan
Burusut tuluy
Buta terong
Caang bulan dadamaran
Caang bulan opat welas, jalan geder sasapuan
Caang padang narawangan
Cacag nangkaeun
Cacah rucah atah warah
Cacarakan keneh
Cacing cau
Cadu mungkuk haram dempak
Cai asa tuak bari, kejo asa catang bobo
Cai di hilir mah kumaha ti girangna
Caina herang laukna beunang
Campaka jadi di reuma
Campur kaya
Cangkir emas eusi delan
Cape gawe teu kapake
Cara badak cihea = kawas badak cihea
Cara bueuk meunang mabuk =  kawas bueuk meunang mabuk
Cara cai dina daun bolang
Cara embe
Cara gaang katincak
Cara hurang, tai ka hulu-hulu
Cara jogjog mondok
Cara merak
Cara simeut hiris, tai kana beuheung-beuheung
Carang takol
Careham hayameun
Caringcing pageuh kancing, saringset pageuh iket
Cecendet mande kiara (cileuncang mande sagara)
Cengkir gading papasangan
Ceplak pahang
Ceuli lentaheun
Cicing dina sihung maung
Ciduh jeung reuhak
Cikal bungang
Cikaracak ninggang batu, laun-laun jadi legok
Cilaka dua belas
Cileuncang mande sagara
Cindul teureupeun
Ciri sabumi cara sadesa
Clik putih clak herang
Congo-congo ku amis, mun rek amis (o)ge puhuna
Copong pikir
Cruk-crek
Cucuk panon
Cucuk rungkang
Cueut ka hareup
Cukang tara neangan nu ngising
Cukup belengur
Cul dogdog tinggal igel
Cunduk waktu ninggang mangsa
Daek macok embung dipacok
Dagang oncom rancatan emas
Dagang peda ka cirebon = dagang pindang ka Cirebon
Dah bawang dah kapas = dah kapas dah bawang
Dahar kawas meri
Daharna sakeser daun
Daluang katinggang mangsi
Darma wawayangan bae
Datang katingali tarang, undur katingali punduk
Dedenge tara
Dengdek topi
Deugdeug tanjeuran
Deukeut bau tai, jauh seungit kembang
Deukeut deuleu pondok lengkah
Deukeut-deukeut anak taleus
Deungeun haseum
Di bawah tangan
Diadukumbangkeun
Dianakterekeun
Diangeuncareuhkeun
Dibabuk lalay
Dibejerbeaskeun
Dibere sabuku menta sajeungkal, dibere sajeungkal menta sadeupa.
Dibeuleum seuseur
Dibeuweung diutahkeun
Dibilang peuteuy
Didago-dago tilewo
Didgoan ku seeng nyengsreng
Diguley ku taina
Dihin pinasti anyar pinanggih
Dihurunsuluhkeun
Dijieun hulu teu nyanggut, dijieun buntut teu ngepot
Dijieun lalab rumbah
Dikeprak reumis
Dikepung wakul buaya mangap
Dikerid peuti
Dikompetdaunkeun = disakompetdaunkeun
Dikungkung teu diawur, dicangcang teu diparaban
Dininabobokeun
Dipake cocok conggang
Dipiamis buah gintung
Dipisudi mere budi
Disiksik dikunyit-kunyit, dicacag diwalang-walang
Disuhun dina embun-embunan
Disusul tepus
Ditangtang-ditengteng, dijieun bonteng sapasi
Ditegalambakeun
Ditilik ti gigir lenggik, disawang ti tukang lenjang, diteuteup ti hareup sieup
Ditiung geus hujan
Diwayangkeun
Dogdog pangrewong
Dogong-dogong tulak cau, geus gede dituar batur
Dosa salaput hulu
Dug hulu pet nyawa
Dug tinetek
Duit pait
Duit panas
Dukun lintuh kasakit matuh
Dulang tinande
Dulur pet ku hinis
Duum tinggi
Eleh deet
Elmu ajug
Elmu angklung
Elmu sapi
Elmu tumbila
Elmu tungtut dunya siar, sukan-sukan sakadarna
Elok bangkong
Embung kakalangkungan
Endog mapatahan hayam
Endog sapatalangan, peupeus hiji peupeus kabeh
Endog sasayang, remek hiji remek kabeh
Endog tara megar kabeh
Era parada
Euweuh elmu panungtungan
Euweuh nu ngaharu biru
Ewe randa dihiasan
Gagalana
Galagah kacaahan
Galak sinongnong
Galak timburu
Galegeh gado
Gancang pincang
Ganti pileumpangan
Gantung denge
Gantung teureuyeun
Garo singsat
Garo-garo teu ateul
Gede cahak manan cohok
Gede gunung pananggeuhan
Gede hulu
Gede-gede kayu randu, dipake pamikul bengkung, dipake lincar sok anggan, dipake pancir ngajedig
Gede-gede ngadage
Geledug ces
Gemah ripah loh jinawi
Gentel keak
Genteng-genteng ulah potong
Gereges gedebug
Gering nangtung
Getas harupateun =pingges harupateun
Geugeut manjaheun
Geulis sisi, laur gunung, sonagar huma
Geura mageuhan cangcut tali wanda
Geus apal luar jerona
Geus aya dina pesak
Geus aya kembang-kembangna
Geus bijil bulu mayang
Geus cuet ka hareup
Geus cumarita
Geus karasa pait peuheurna
Geus labuh bandera
Geus teu asa jeung jiga
Geus turun amis cau
Geusa nyanghulu ngaler
Gindi pikir belang bayah
Ginding bangbara
Ginding kakampis
Giri lungsi tanpa hingan
Goong nabeuh maneh
Goong saba karia
Goreng peujit
Goreng sisit
Gugon tuhon
Gulak-giluk kari tuur, herang-herang kari mata, teuas-teuas kari bincurang
Gunung luhur beunang diukur, laut jero beuang dijugjugan, tapi hate jelema najan deet moal kakobet
Gunung tanpa tutugan
Gurat batu
Gurat cai
Guru, ratu, wongatua karo
Gusti Allah tara nanggeuy di bongkokna
Hade gogog hade tagog
Hade ku omong, goreng ku omong
Hade lalambe
Halodo sataun lantis ku hujan sapoe
Hambur bacot murah congcot
Hampang birit
Hampang leungeun
Handap asor
Handap lanyap
Hantang-hantung hantigong hantriweli
Hapa heman
Hapa hui
Hapa-hapa (o)ge ranggeuyan
Harelung jangkung
Harewos bojong
Harigu manukeun
Haripeut ku teuteureuyeun
Harus omong batan goong
Haseum budi
Haseum kawas cuka bibit
Hawara biwir
Hayang leuwih jadi leweh
Hayang utung jadi buntung = hayang untung kalah buntung
Hejo cokor badag sambel
Hejo tihang
Henteu asa jeung jiga
Henteu cai herang-herang acan
Henteu gedag bulu salambar
Henteu jingjing henteu bawa
Henteu unggut kalinduan, henteu gedag kaanginan
Herang caina beunang laukna
Herang-herang kari mata, teuas-teuas kari bincurang
Hese cape teu kapake
Heueuh-heueuh bueuk
Heunceut ucingeun
Heuras genggerong
Heuras letah
Heureut pakeun
Heurin ku letah
Hideung ngabangbara
Hideung oge buah manggu, matak tigurawil bajing
Hirup di nuhun paeh di rampes
Hirup katungkul ku pati
Hirup ku ibun, gede ku poe
Hirup ku panyukup, gede ku pamere
Hirup ngabangbara
Hirup ramijud
Hirup teu neut, paeh teu hos
Hirup ulah manggih tuntung, paeh ulah manggih beja
Huap hiji diduakeun
Hudang pineuh =hudang tineuh
Hujan cipanon
Hulu gundul dihihidan
Hulu peutieun
Hunyur mandean gunung
Hurip gusti waras abdi
Hurung nangtung siang leumpang
Hutang salaput hulu
Hutang uyah bayar uyah, hutang nyeri bayar nyeri
Hutang-hatong
Ieu aing
Ieu aing uyah kidul
Igana kawas gambang
Ilang along margahina
Ilang along margahina, katinggang pangpung dilebok maung, rambutna salambar, getihna satetes, ambekanana sadami, agamana darigamana, kaula nyerenkeun
Ilang lebih tanpa karana
Indit sirib
Indung hukum bapa darigama
Indung lembu bapa banteng
Indung suku (o)ge moal dibejaan
Indung tunggul rahayu, bapa tangkal darajat
Inggis batan maut hinis
Inggis ku bisi rempan ku sugan
Ipis biwir
Ipis kulit beungeut
Ipis wiwirang
Iwak nangtang sujen
Jabung tumalapung sabda kumapalang
Jadi Senen kalemekan
Jadi cikal bungang
Jadi dogdog pangrewong
Jadi kulit jadi daging
Jadi maung malang
Jadi sabiwir hiji
Jajar pasar
Jalma cupet bener
Jalma masagi
Jalma notorogan
Jaman bedil sundut
Jaman cacing dua saduit
Jaman kuda ngegel beusi
Jaman tai kotok dilebuan
Janget kinatelon
Jantungeun
Jati kasilih ku junti
Jauh ka bedug, anggang ka dulag
Jauh tanah ka langit
Jauh-jauh panjang gagang
Jawadah tutung birtna, sacarana-sacarana
Jegjeg ceker
Jejer pasar
Jelema balung tunggal
Jelema bangkarak
Jelema kurang saeundan
Jelema pasagi
Jelema pasesaan
Jelema sok keuna ku owah gingsir
Jelema teu baleg
Jelema teu beres
Jelema teu eucreug
Jengkol aya usumna
Jeung leweh mah mending waleh
Jiga tunggul kahuru
Jogjog neureuy buah loa
Jojodog unggah ka salu
Jongjon bontos
Jual dedet
Ka cai diangir mandi, batu lempar panuusan
Ka cai jadi saleuwi, ka darat jadi selebak
Ka hareup ngala sajeujeuh, ka tukang ngala sajeungkal
Ka luhur sieun gugur, ka handap sieun cacing
Ka luhur teu sirungan, ka handap teu akaran
Kabawa ku sakaba-kaba
Kabedil langit
Kabeureuyan mah tara ku tulang munding, tapi ku cucuk peda
Kacang poho ka lanjaran
Kacanir bangban
Kacekal bagal buntutna
Kaceluk ka awun-awun, kawentar ka janapria, kakoncara ka mancanagara
Kaciwit kulit kabawa daging
Kaduhung tara ti heula
Kagok asor = kagok asong
Kahieuman bangkong
Kahirupan jelema sok aya pasang surudna
Kai teu kaur ku angin
Kajejek ku hakan
Kajeun kendor ngagembol, tibatan gancang pincang
Kajeun pait heula amis tungtung, manan amis heula pait tungtung
Kajeun panas tonggong, asal tiis beuteung
Kakeueum ku cai toge
Kalah ka engkeg
Kalapa bijil ti cungap
Kaliung kasiput
Kandel kulit beungeut
Kapiheulaan ngaluluh taneuh
Kapipit galih kadudut kalbu
Kapiring leutik
Karawu kapangku
Kasep ngalenggereng koneng
Kasuhun kalingga murda
Katempuhan buntut maung
Katerka ku kira-kira
Katindih ku kari-kari
Katumbukan catur kadatangan carita
Katurug katatuh
Kawas Rama jeung Sinta
Kawas aeud
Kawas aki-aki tujuh mulud
Kawas anjing kadempet lincar
Kawas anjing tutung buntut
Kawas anu teu dibedong
Kawas aul
Kawas awi sumaer di pasir
Kawas badak Cihea
Kawas bangkong katuruban batok
Kawas bayah kuda
Kawas beubeulahan terong
Kawas beusi atah beuleum
Kawas birit seeng
Kawas bodor reog
Kawas buek beunang mabuk
Kawas bujur aseupan
Kawas cai dina daun bolang
Kawas carangka
Kawas careuh bulan
Kawas ciduh jeung reuhak
Kawas congcorang murus
Kawas cucurut kaibunan
Kawas dodol bulukan
Kawas dongeng Si Bosetek
Kawas durukan huut
Kawas gaang katincak
Kawas gateuw
Kawas gula jeung peueut
Kawas hayam keur endogan
Kawas hayam lamba
Kawas hayam penyambungan
Kawas heulang pateuh jangjang
Kawas hileud peuteuy
Kawas himi-himi
Kawas jogjog mondok
Kawas ka budak rodek hulu
Kawas kacang ninggang kajang
Kawas kedok bakal
Kawas kedok rautaneun
Kawas kuda leupas ti gedongan
Kawas langit jeung bumi
Kawas lauk asup kana bubu
Kawas leungeun (a)nu palid
Kawas maung meunang
Kawas nenggeuy endog beubeureumna
Kawas nu dipupul bayu
Kawas nu keked
Kawas nu meunang lotre
Kawas nu mulangkeun panyiraman
Kawas pantun teu jeung kacapi
Kawas panyeupahan lalay
Kawas perah bedog rautaneun
Kawas siraru jadi
Kawas supa jadi
Kawas tatah
Kawas terong beulah dua
Kawas toed
Kawas tunggul kahuru
Kawas ucing garong
Kawas ucing kumareumbi
Kawas ucing nyanding paisan
Kawas wayang pangsisina
Kebo mulih pakandangan
Kejo asak angeun datang
Kelek jalan
Kembang buruan
Kembang carita
Kembang mata
Keuna ku aen
Keuna ku lara teu keuna ku pati
Keur (nuju) bentang surem
Keur awak saawakeun
Keur bentang surem
Keur meujeuhna bilatung dulang
Keur meujeuhna hejo lembok rambay carita
Keur tulang tonggong
Keuyeup apu
Kiceupna sabedug sakali
Kiruh ti girang, kiruh ka hilir
Kokod monongeun
Kokojona
Kokolot begog
Kokoro manggih mulud
Kokoro nyenang
Kokoro nyoso, malarat rosa
Kolot dapuran
Kolot dina beuheung munding
Kolot kolotok
Kolot pawongan
Kolot sapeuting
Koreh-koreh cok
Kotok bongkok kumorolong, kacingcalang kumarantang
Kudu asak jeujeuhan
Kudu bisa ngeureut miceun
Kudu boga pikir kadua leutik
Kudu ngukur ka kujur, nimbang ka awak
Kudu nyaho lautanana, kudu nyaho tatambanganana
Kujang dua pangadekna
Kukuh Ciburuy
Kukuk sumpung dilawan dada leway
Kulak canggeum
Kumaha bule hideungana (bae)
Kumaha ceuk nu dibendo (bae)
Kumaha kecebur caina, geletuk batuna  bae
Kumaha ramena pasar
Kumis bangbara ngaliang
Kunang-kunang nerus bumi
Kur'an butut
Kurang jeujeuhan
Kurang saeundan
Kuru aking ngajangjawing
Kuru cileuh kentel peujit
Kuru kurulang-kuruling
Kurung batok
Labuh diuk tiba neundeut
Laer gado
Lain bantrak-bantrakeun
Lain ku tulang munding kabeureuyan mah, ku cucuk peda
Lain lantung tambuh laku, lain lentang tanpa beja
Lain palid ku cikiih
Laki rabi tegang pati
Lalaki kermbang kamangi
Lalaki langit lalanang jagat
Landung kandungan laer aisan
Langkung saur bahe carek
Lantip budi
Lara aen
Lauk buruh milu mijah
Legeg lebe budi santri, ari lampah euwah-euwah
Legok tapak genteng kadek
Lelengkah halu
Leleyep asu
Lembur singkur mandala singkah
Lengkah kapiceun
Lengkeh lege
Lentah darat
Lesang kuras
Letah leuwih seukeut manan pedang
Leubeut buah hejo daun
Leuleus awak
Leuleus jeujeur liat tali
Leuleus kejo poena
Leumpang nurutkeun indung suku
Leumpeuh yuni
Leunggeuh cau beuleum
Leungit tanpa lebih ilang tanpa karana
Leutik burih
Leutik cahak gede cohok
Leutik pucus
Leutik ringkang gede bugang
Leutik-leutik cabe rawit
Leutik-leutik ngagalatik
Leuweung gonggong simagonggong, leuweung si sumenem kakobet
Leuwi jero beunang diteuleuman, hate jelema najan deet teu kakobet
Liang cocopet
Lieuk euweuh ragap taya
Lindeuk japati
Lindeuk piteuk
Loba (teuing) jaksa
Loba catur tanpa bukur
Lodong kosong ngelentrung
Lolondokan
Luhur kokopan
Luhur kuta gede dunya
Luhur pamakanan
Luhur tincak
Luhur tulupan
Luncat mulang
Lungguh tutut
Lungguh tutut bodo keong, sawah sakotak kaider kabeh
Mabok pangkat
Macan biungan
Maen sabun
Malengpeng pakel ku munding
Maliding sanak
Malik ka temen
Malik mepeh
Malik rabi pindah ngawula
Malikkeun pakarang
Malikkeun pangali
Malingping pakel ku munding
Manan leweh mending waleh
Manasina sambel jahe, top top tewewet
Mangkok emas eusi madu
Mangpengkeun kuya ka leuwi
Mani hayang utah iga
Manuk hiber ku jangjangna
Maot ulah manggih tungtung, paeh ulah manggih beja
Mapatahan naek ka monyet
Mapatahan ngojay ke meri
Mapay ka puhu leungeun
Marebutkeun balung tanpa eusi
Marebutkeun paisan kosong
Mata dijual ka peda
Mata duiteun
Mata karanjang
Matak andel-andeleun
Matak ear sajagat
Matak ibur salelembur
Matak muringkak bulu punduk
Matak pabalik letah
Matak pajauh huma
Matak tibalik aseupan
Matih tuman batan tumbal
Maung malang
Maung ompong, bedil kosong
Maung sarungkun
Maut ka puhu
Maut nyere ka congona
Meber-meber totopong heureut
Medal sila
Melengkung umbul-umbulna, ngerab-ngerab banderana
Memeh emal, emel heula
Mending kendor ngagembol ti battan gancang pincang
Mending pait ti heula tinimbang pait tungtungna
Mending waleh batan leweh
Mere langgir kalieun
Mesek kalapa ku jara
Meubeut meulit
Meuli teri meunang japuh
Meunag luang tina burang
Meunang kopi pait
Meungpeun carang
Meungpeung teugeu harianeun
Meupeus keuyang
Miceun batok meunang coet
Miceun beungeut
Midua pikir
Mihape hayam ka heulang
Milih-milih rabi mindah-mindah rasa
Mindingan beungeut ku saweuy
Mipit teu amit ngala teu menta
Misah badan misah nyawa
Miyuni hayam kabiri, (kumeok memeh dipacok)
Miyuni hui kamayung
Miyuni hurang, tai ka hulu-hulu
Miyuni umang
Moal aya haseup mun euweuh seuneu
Moal ceurik menta eusi
Moal ditarajean
Moal jauh laukna
Moal mundur satunjang beas
Moal neangan jurig (nu) teu kadeuleu
Mobok manggih gorowong
Modal dengkul
Modal nyapek mun teu ngoprek
Monyet dibere sesengked
Monyet kapalingan jagong
Monyet ngagugulung kalapa
Mopo memeh nanggung
Moro julang ngaleupaskeun peusing
Moro taya tinggal kaya
Mucuk eurih
Mulangkeun panyiraman
Mun kiruh ti girangna, komo ka hilirna
Mun teu ngakal moal ngakeul, mun teu ngarah moal ngarih, mun teu ngoprek moal nyapek
Muncang labuh ka puhu, (kebo mulih pakandangan)
Mupugkeun tai kanjut
Murag bulu bitis
Murah sandang murah pangan
Muriang teu kawayaan
Musuh kabuyutan
Naheun bubu pahareup-hareup
Najan dibawa kana liang cocopet, moal burung nuturkeun
Nanggung bugang
Nangkeup mawa eunyeuh
Nangtung di kariungan, ngadeg di karageman
Neneh bonteng
Nengterege
Nepak cai malar ceret
Nepakeun jurig pateuh
Nepi ka nyanghulu ngaler
Nepi ka pakotrek iteuk
Nepung-nepung bangkelung
Nete akar ngeumbing jangkar
Nete porot ngeumbing lesot
Nete samplek nincak semplak
Nete taraje nincak hambalan
Neukteuk curuk dina pingping
Neukteuk leukur meulah jantung, geus lain-lainna deui
Neukteuk mari anggeus, rokrok pondokeun, peunggas harupateun
Neundeun hate
Neundeun piheuleut nunda picela
Ngabejaan bulu tuur
Ngaboretekeun liang tai di pasar
Ngabudi ucing
Ngabuntut bangkong
Ngaburuy
Ngacak ngebur
Ngadagoan belut buluan oray jangjangan
Ngadagoan kuah beukah
Ngadagoan kuda tandukan
Ngadagoan uncal mapal
Ngadaun ngora
Ngadaweung ngabangbang areuy
Ngadek sacekna nilas saplasna
Ngadeupaan lincar
Ngado-dago dawuh
Ngadu angklung (dipasar)
Ngadu-ngadu rajawisuna
Ngagandong kejo susah nyatu
Ngagedag bari mulungan
Ngahihileudan
Ngahurun balung ka tulang
Ngajeler paeh
Ngajerit maratan langit, ngoceak maratan mega
Ngajual jarum ka tukang gendong
Ngajuk kudu naur, ngahutang kudu mayar
Ngajuk teu naur, ngahutang teu mayar
Ngajul bentang ku asiwung
Ngalap hate
Ngalebur tapak
Ngalenghoy lir macan teu nangan
Ngaletak ciduh
Ngaleut ngeungkeuy ngabandaleut, ngembat-ngembat nyatang pinang
Ngaliarkeun taleus ateul
Ngalintuhan maung kuru
Ngalungkeun kuya ka leuwi
Ngan ukur saoleseun
Ngandung hate
Nganyam samak, neukteukan bari motongan
Ngarah ngarinah
Ngarah sahuap sakopeun
Ngaraja dewek
Ngarancabang pikir
Ngarangkaskeun dungus
Ngarangkay koja
Ngarawu ku siku
Ngarep-ngarep bentang ragrag
Ngarep-ngarep kalangkang heulang
Ngarujak sentul
Ngawur kasintu nyieuhkeun hayam
Ngawurkeun wijen kana keusik
Ngebutkeun totopong
Ngegel curuk
Ngembang awi
Ngembang bako
Ngembang bawang
Ngembang bolang
Ngembang boled
Ngembang cabe
Ngembang cau
Ngembang cengek
Ngembang cikur
Ngembang gedang
Ngembang genjer
Ngembang honje
Ngembang jaat
Ngembang jambe
Ngembang jambu (aer)
Ngembang jambu batu
Ngembang jengkol
Ngembang jeruk
Ngembang kadu
Ngembang kaso
Ngembang kawung
Ngembang laja
Ngembang lopang
Ngembang pare
Ngembang peuteuy
Ngembang salak
Ngembang tangkil
Ngembang tiwu
Ngembang waluh
Ngeplek jawer ngandar jangjang, (miyuni hayam kabiri)
Ngepung meja
Ngeunah angeun ngeunah angen
Ngeunah eon teu ngeunah ehe
Ngeunah nyandang ngeunah nyanding
Ngeundeuk-ngeundeuk geusan eunteup
Ngeupeul ngahuapan maneh
Ngeureut miceun
Ngijing sila bengkok sembah
Ngimpi ge diangir mandi
Ngingu kuda kuru, ari geus lintuh nyepak
Nginjeum sirit ka nu kawin
Ngobah-ngobah macan turu, ngusik-ngusik ula mandi
Ngodok liang buntu
Ngodok liang jero
Ngomong sabedug sakali
Ngotok ngowo
Ngudag-ngudag kalangkang heulang
Ngukur baju sasereg awak
Ngukur ka kujur, nimbang ka awak
Ngukut kuda kuru, ari geus gede sok nyepak
Ngulit bawang
Ngusap birit bari indit
Ngusik-ngusik ula mandi
Nikukur = kawas tikukur
Nilik bari ngeusi
Nimu luang tina burang
Nincak parahu dua
Ninggalkeun hayam dudutaneun
Ninggang kekecrak
Ningnang
Nini-nini dikeningan, (ewe randa dihiasan)
Nini-nini leungit sapeuting, tai maung huisan
Nista, maja, utama
Nontot jodo
Noong ka kolong
Nu asih dipulang sengit, nu haat dipulang moha
Nu borok dirorojok, (nu titeuleum disimbeuhan)
Nu edan dikendangan, nu burung diangklungan
Nu geulis jadi werejitr, nu lenjang jadi baruang
Nu tani kari daki, nu dagang kari hutang
Nu temen tinemenan
Nu titeuleum disimbeuhan
Nuekteun mari anggeus
Nuju hurup ninggang wirahma
Nulungan anjing kadempet
Numbuk di sue
Nunggul pinang
Nungtik lari mapay tapak
Nungtut bari ngeusi
Nurub cupu
Nutup lobang gali lobang
Nuturkeun indung suku
Nya di hurang, nya di keuyeup
Nya ngagogog nya mantog
Nya picung nya hulu maung
Nyaah dulang
Nyaeuran gunung ku taneuh,sagara ku uyah
Nyaho lautanana
Nyair hurang meunang kancra
Nyaliksik ka buuk leutik
Nyalindung di caangna
Nyalindung ka gelung
Nyanggakeun beuheung teukteukeun, suku genteng belokeun
Nyanghulu ka jarian
Nyecepo ka nu rerempo
Nyekel sabuk milang tatu
Nyeri beuheung sosonggeteun
Nyeri peurih geus kapanggih, lara wirang geus kasorang
Nyeungeut damar di suhunan
Nyeungseurikeun upih ragrag
Nyiar batuk pibaraheun
Nyiar teri meunang japuh
Nyicikeun cai murulukkeun lebu
Nyiduh ka langit
Nyieun catur taya dapur
Nyieun heuleur jeroeun huma
Nyieun piandel
Nyieun poe bungsuna
Nyieun pucuk ti girang
Nyiruan (mah) teu resepeun nyeuseup nu pait.
Nyiuk cai ku ayakan
Nyium bari ngegel
Nyokor
Nyokot lesot ngeumbing porot
Nyolok mata buncelik
Nyolong bade
Nyoo gado
Nyuhun, nanggung, ngelek, ngegel
Nyuhunkeun bobot pangayon (timbang taraju)
Nyukcruk walung mapay-mapay wahangan
Ombak banyuan
Omong harus batan goong
Oray neangan paneunggeul
Owah akal
Owah ginsir
Paanteur-anteur julang
Pacikrak ngalawan merak
Pada rubak sisi samping
Padu teu buruk digantung
Paeh pikir
Paeh poso
Paeh teu hos, hirup teu neut
Pagede-gede urat rengge
Pageprak reumis
Pageuh kancing loba anjing
Pagiri-giri calik pagirang-girang tampian
Paheuyeuk-heuyeuk leungeun
Pait daging pahang tulang
Pait paria
Pakait pikir
Pakalolot supa
Pakotrek iteuk
Palid ku cileuncang
Paluhur-luhur diuk
Pamuka lawang
Panas leungeun
Panday tara boga (eun) bedog
Panjang lengkah
Panjang leungeun
Panjang punjung
Panon keongeun
Panonna kandar ka sisi
Papadon los ka kolong
Papais-pais paray
Paraji ukur malar saji
Pareumeun obor
Pariuk manggih kekeb
Pasini jangji pasang subaya
Pasrah arit
Patpat gulipat
Pelengkung bekas nyalahan
Perlu kasambut sunat kalampahkeun
Peso pangot ninggang lontar
Petot bengo dulur sorangan
Peujit koreseun
Peunggas rancatan
Peupeureum asu
Peureum kadeuleu beunta karasa
Piit ngeundeuk-ngeundeuk pasir
Pilih kasih
Pindah cai dibawa tampianana
Pindah cai pindah tampian
Pindah pileumpangan
Pinter aling-aling bodo
Pinter kabalinger
Pinter kodek
Pipilih nyiar nu leuwih, koceplak meunang nu pecak
Piritan milu endogan
Piruruhan dikatengah-imahkeun
Poe panganggeusan
Poek mongkleng buta radin
Poho ka purwadaksina
Pokrol bangbu
Pondok catur panjang maksud
Pondok heureut
Pondok jodo panjang baraya
Pondok lengkah
Pondok nyogok panjang nyugak
Potol jarum
Potol teko
Puasa manggih lebaran
Pucuk awian
Pucuk awian, lir awi sumaer di pasir
Punduk moal ngaluhuran hulu
Pundung eon
Pupulur memeh mantun
Pur kuntul kari tunggul, lar gagak kari tunggak, tunggak kacuatan daging
Pur manuk
Puraga tamba kadengda
Raga papisah jeung nyawa
Ragaji inggris
Rambat kamale
Rambay alaeun raweuy beuweungeun
Ranggaek memeh tandukan
Raris anjing
Raweuy beuweungeun rambay alaeun
Rea jungjang karawatna
Rea ketan rea keton
Rea rambat kamalena
Rejeki kaseser ku hakan
Rejeki maungeun
Rek dibeureum rek dihideung ge pasrah
Rek dijieun jimat parepeh
Rempan batan mesat gobang
Rempug jukung
Reuneuh munding
Reuntas ku tingkah
Risi ku bisi rempan ku basa
Riung mungpulung
Rokrok pondokeun
Rteu embul teu ciak
Rubuh-rubuh gedang
Rujak sentul
Rumbak caringin di buruan
Rumbak kuntieun
Rup ku padung
Rusuh luput
Saampar samak
Saaub payung sacaang damar
Sabata sarimbangan
Sabelas dua belas
Sabobot sapihanean
Sabuni-buni (a)nu ngisng
Sabuni-buni tarasi
Sacangreud pageuh sagolek pangkek
Saciduh metu saucap nyata
Sadom araning b(a)raja, sakuang araning geni
Saeutik mahi loba nyesa
Saeutik patri
Sagalak-galakna macan, tara nyatu anak
Sagara tanpa tepi
Saherang-herangna cibeas, (moal herang cara cisumur)
Sakecap kadua gobang
Sakeser daun
Saketek sapihanean sabata sarimbagan
Sakirincinging duit sakocopoking bogo
Sakuru-kuru(na) lembu saregeng-regeng(na) bateng
Salah kaparah
Salah tincak
Salieuk beh
Salisung garduh
Saluhur-luhur punduk, tara ngaliwatan hulu
Samagaha pikir
Sanajan nepi ka bisa ngukir langit
Sangsara digeusan betah
Sapapait samamanis
Sapi anut ka banteng
Sapu nyere pegat simpay
Sarengkak saparipolah
Sareundeuk saigel
Sareundeuk saigel, saketek sapihanean, sabata sarimbagan
Sari gunung
Sarumbak panggangan
Satalern tilu baru
Satali tiga uang
Satengah buah leunca
Sato busana daging, jalma busana elmu
Satru kabuyutan
Satungkebing langit
Saumur dumelah
Saumur jagong
Saumur nyunyuhun hulu
Saungkab peundeuy
Saur manuk
Sawaja sabeusi
Sawan geureuh
Sawan goleah
Sawan kuya
Sela kapitan gunung
Selang-seling
Selenting bawaning angin, kolepat bawaning kilat
Sembah kuriling
Sengserang padung
Sengserang panon
Sentak badakeun
Sepi paling towong rampog
Serah bongkokan
Sereg di buana, logor di(na) liang jarum
Setan bungkeuleukan
Setelan tiru baru
Seukeut ambeu seukeut panon
Seukeut tambang manan gobang
Seuneu hurung dipancaran
Seuneu hurung, cai caah, (ulah disorang)
Seuseut batan neureuy keueus
Si Cepot jadi raja
Sibanyo laleaur
Siduruk isuk
Sieun bahe tuluy tamplok
Sieurean
Siga Si Cepot
Siga bentang kabeurangan
Siga bungaok
Silihjenggut jeung nu gundul
Sing bisa mawa maneh
Sireum ateulan
Sireum ngalawan kadal
Sireum oge katincak-tincak teuing mah tangtu ngegel
Sirung ngaliwatan tunggul
Sisit kadal
Sisit kancra
Situ kaliung ku taman
Sonagar huma
Sono bogoh geus kalakon, lara wirang geus kasorang
Sosoroh ngandon kojor
Suku dijieun hulu, hulu dijieun suku
Suku sambng leumpang, biwir sambung lemek
Suluh besem oge ari diasur-asur mah hurung
Sumput salindung
Sundul ka langit
Taarrna teja mentrangan
Tacan aya nu nganjang ka pageto
Tai ka hulu-hulu
Taktak korangeun
Taman kaliung ku situ
Tamba gado ngaburayot
Tamiang meulit ka bitis
Tamplok aseupan
Tamplok batokeun
Tanggung renteng
Tangkal kai teus kalis ku angin
Tapel adam
Taraje nanggeuh dulang tinande
Tarik alahbatan mimis
Tatah wadung
Taya bandinganana
Taya dunya kinasihan
Taya genah panasaran
Taya geusan pakumaha
Taya halodo panyadapan
Taya kabau
Taya siruaneunana
Taya tangan pangawasa
Teguh pancuh
Tembong gelor
Tembong tambagana
Teng manuk teng anak merak kukuncungan
Terusing ratu rembesing kusumah
Teu asa jeung jiga
Teu asup ka rewah mulud
Teu asup kolem
Teu aya geuneuk maleukmeuk
Teu aya sarebuk samerang nyamu
Teu bade gawe
Teu basa teu carita
Teu basa-basa acan
Teu beja teu carita
Teu beunang dikoet ku nu keked
Teu boga pikir rangkepan
Teu boga tulang tonggong
Teu busik bulu salambar
Teu busik-busik acan
Teu cai herang-herang acan
Teu cari ka Batawi, tapi ka salaki
Teu di hurang teu di keuyeup
Teu diambeuan
Teu dibere cai atah =  teu dibere ciatah
Teu didenge ku tai ceuli
Teu didingding kelir
Teu dipiceun sasieur
Teu ditari teu ditakon
Teu eleh geleng
Teu elok teu embol
Teu gedag bulu salambar
Teu gugur teu angin
Teu hir teu walahir, teu kakak teu caladi, teu aro-aro acan
Teu inget sacongo buuk
Teu jauh laukna
Teu kakurung ku entik
Teu kaleungitan peuting
Teu kaur buluan
Teu lemek teu nyarek
Teu mais teu meuleum
Teu meunang cai atah = teu meunang ciatah
Teu nalipak maneh
Teu ngalarung nu burung, teu nyesakeun nu edan
Teu nginjeum ceuli, teu nginjeum mata
Teu nyaho di alip bingkeng
Teu nyaho di cedo
Teu nyaho di hitut bau
Teu nyaho di kaler kidul
Teu nyaho di lauk
Teu pindo damel
Teu pindo gawe
Teu puguh alang ujurna
Teu puguh monyet hideungna
Teu sanak teu kadang
Teu tuah teu dosa
Teu uyahan
Teu wawuh wuwuh pajauh, teu loma tambah paanggang
Teujauh ti tihang juru, teu anggang ti tihang tengah
Ti batan kapok anggur gawok
Ti batan meunang pala, anggur meunang palu
Ti kikirik nepi ka jadi anjing
Ti luhur sausap rambut, ti handap sahibas dampal
Ti nanggerang lila beurang, ti nanggorek lila poek
Ti ngongkoak nepi ka ngungkueuk
Ti penting kapalingan, ti beurang kasayaban
Tibalik pasangan
Tiis ceuli heranng mata
Tiis dingin paripurna
Tiis leungeun
Tiis-tiis jahe
Tikoro andon peso
Tikoro kotokeun, (careham hayameun)
Tilas tepus
Tinggal tulang jeung kulit
Tinggar kalongeun
Tipu keling ragaji inggris
Tisusut tidungdung
Titip diri sangsang badan
Titirah ngadon kanceuh
Totopong heureut dibeber-beber, (geus) tangtu soeh
Trong kohkol morongkol, dur bedug murungkut
Tuang jinis
Tudung acungan
Tugur tundan cuntang gantang
Tukang jilat
Tukuh Ciburuy
Tumenggung sundung patih arit
Tumorojog tanpa larapan
Tumpang sirang
Tunggul dirarud catang dirumpak
Tunggul kuras
Tunggul sirungan catang supaan
Tungkul ka jukut, tanggah ka sadapan
Turun ka ranjang
Turunan tumenggung sundung, patih arit
Tutung atahan
Tuturut munding
Tutus langkung kepang halang
Uang semir
Ubar puruluk
Ucing nyanding paisan
Ukur pulang modal
Ulah (sok) ngeok memeh dipacok
Ulah beunghar memeh boga
Ulah cara ka kembang malati, kudu cara ka picung
Ulah incah balilihan
Ulah kabawa ku sakaba-kaba
Ulah muragkeun duwegan ti luhur
Ulah nyeusngseurikeun upih ragrag
Ulah pangkat memeh jeneng
Ulah tiis-tiis jahe
Ulah unggut kalinduan, ulah gedag kaanginan
Uncal kaauban surak
Uncal tara ridu(eun) ku tanduk
Undur katingali punduk, datang katingali tarang
Unggah bale watangan
Urang curug ngebul
Urang kampung bau lisung, cacah rucah atah warah
Uteuk encer
Uteuk tongo dina tarang batur kanyahoan, gajah depa dina punduk teu karasa
Uteuk tongo walang taga
Uyah tara tees ka luhur
Waspada permana tingal
Watang sinambungan
Wawuh munding
Weruh sadurung winarah
Wiwirang di kolong catang, nya gede nya panjang
Wong asih ora kurang pangalem, wong sengit ora kurang panyacad
Wong becik ketitik, wong ala ketara
Yuni kembang
Yuni tai
