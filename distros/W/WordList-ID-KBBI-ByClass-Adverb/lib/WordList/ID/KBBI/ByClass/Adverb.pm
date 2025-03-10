package WordList::ID::KBBI::ByClass::Adverb;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-19'; # DATE
our $DIST = 'WordList-ID-KBBI-ByClass-Adverb'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::RandomSeekPick';

our %STATS = ("num_words_contains_whitespace",13,"num_words_contain_nonword_chars",151,"num_words_contains_unicode",0,"avg_word_len",9.8655462184874,"num_words_contain_unicode",0,"num_words_contains_nonword_chars",151,"shortest_word_len",3,"num_words_contain_whitespace",13,"num_words",357,"longest_word_len",29); # STATS

1;
# ABSTRACT: Indonesian adverb words from Kamus Besar Bahasa Indonesia (KBBI), 3e

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::KBBI::ByClass::Adverb - Indonesian adverb words from Kamus Besar Bahasa Indonesia (KBBI), 3e

=head1 VERSION

This document describes version 0.001 of WordList::ID::KBBI::ByClass::Adverb (from Perl distribution WordList-ID-KBBI-ByClass-Adverb), released on 2024-11-19.

=head1 SYNOPSIS

 use WordList::ID::KBBI::ByClass::Adverb;

 my $wl = WordList::ID::KBBI::ByClass::Adverb->new;

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

 +----------------------------------+-----------------+
 | key                              | value           |
 +----------------------------------+-----------------+
 | avg_word_len                     | 9.8655462184874 |
 | longest_word_len                 | 29              |
 | num_words                        | 357             |
 | num_words_contain_nonword_chars  | 151             |
 | num_words_contain_unicode        | 0               |
 | num_words_contain_whitespace     | 13              |
 | num_words_contains_nonword_chars | 151             |
 | num_words_contains_unicode       | 0               |
 | num_words_contains_whitespace    | 13              |
 | shortest_word_len                | 3               |
 +----------------------------------+-----------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ID-KBBI-ByClass-Adverb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ID-KBBI-ByClass-Adverb>.

=head1 SEE ALSO

L<ArrayData::Lingua::Word::ID::KBBI::ByClass::Adverb> contains the same data.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-ID-KBBI-ByClass-Adverb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
aci-acinya
ada-adanya
ada-adanyakah
adakala
agaknya
akhir-akhirnya
akhirnya
alangkah
ambreng-ambrengan
anggar-anggar
aposteriori
bacut, kebacut
baheula
baku
banget
barang
barangkali
bareng
baru-baru ini
barusan
belaka
beleng
belum
belum-belum
berbareng
berendeng
beresok
berganda-ganda
berjurus-jurus
berka-li-kali
berkelebihan
berlantasan
berlarut-larut
berlebih-lebihan
berlekas-lekas
bermati-mati
bermula-mula
berpelayaran
berpetak-petak
berpotongan
berputusan
bersangatan
bertempat-tempat
bertentu-tentu
biasanya
bila-bila
bis
boleh
boro-boro
bukan
cepat-cepat
cuma
cuma-cuma
cuman
dadak, mendadak
dalam-dalam
dapat
datang-datang
dekat-dekat
diam-diam
duyun
edan-edanan
embuh-embuhan
enggak
enggan
entah
ganal-ganal
garan
gaya-gayanya
gelap-gelapan
gerangan
habis-habisan
hampir
hampir-hampir
hanya
harap-harap, harap cemas
harus
hebat-hebatan
hendak
hendaklah
ibidem
in absensia
interim
intramembran
jangan
jangan-jangan
jerongkang, jerongkang korang
jolong-jolong
juga
justru
kali
kejer
kelihatannya
kemati-matian
kemput
kepingin
kerap-kerap
kesipu-sipuan
kesipuan
keterlaluan
kimah
kira-kira
kiraan
kiranya
klandestin
konon
kromatis
kuat-kuat
kurang
kurang-kurang
lagi
lagi-lagi
lagian
lama-kelamaan
lama-lama
langsung
lantas
laun-laun
layaknya
lebih-lebih
lekas
macam-macam
makin
malah
malar-malar
masa
masak
masak-masak
masakan
masih
mati-mati
melemping
melulu
memang
mendaun
mengkali
mentah-mentah
mesti
metah
moga
mula-mula
mumpung
mungkin
neka-neka
nian
niscaya
non
nyaris
pada
paling
pecicilan
percuma
perlu
pernah
pertama-tama
pesai
puguh
pura-pura
putus-putus
rasa-rasanya
rasanya
rupa-rupanya
rupanya
saja
saling
sama-sama
sampai-sampai
samsam
sangat
sangat-sangat
satu-satu
sayup-menyayup
sayup-sayup
seadanya
seagak
seagak-agak
seakal-akal
seakan-akan
sebaik-baiknya
sebaiknya
sebaliknya
sebelum
sebenarnya
sebentar-sebentar
sebetulnya
sebisanya
seboleh-bolehnya
secepatnya
secukupnya
sedalam-dalamnya
sedang
sedapat-dapatnya
sederum
sedia, sedianya
sedikit-dikitnya
sedikit-sedikit
sedikit-sedikitnya
sedikitnya
sedini-dininya
seelok-eloknya
segala-galanya
segalanya
segera
sehabis-habisnya
seharusnya
seingat
sejadi-jadinya
sejamaknya
sekadar
sekala
sekali
sekali-kali
sekali-sekali
sekalian
sekaligus
sekehendak
sekenyang-kenyangnya
sekenyangnya
seketika
sekira-kira
sekiranya
sekonyong-konyong
sekosong-kosongnya
sekuasa-kuasanya
sekuasanya
sekuat-kuatnya
sekurang-kurangnya
selagi
selalu
selama-lamanya
selamanya
selang
selanjutnya
selari
selat-latnya
selayaknya
selejang
selekas-lekasnya
selekasnya
selepas-lepas
selewat
selincam
selurusnya
semakin
semaksimal mungkin
semaksimal-maksimalnya
semaksimalnya
semanis-manisnya
semasih
semata
semata-mata
semau-maunya
sembunyi-sembunyi
sememangnya
semena-mena
semengga-mengga
semerdeka-merdekanya
semestinya
semoga
sempat-sempatnya
semu
semu-semu
semua-muanya
semuanya
senantiasa
sendiri
sendiri-sendiri
sendirinya, dng sendiri
sengked
seolah-olah
sepala-pala
sepantasnya
sepatutnya
sepelaung
sepemakan
seperlunya
sepertegak
sepinggang
sepintas
sepraktis-praktisnya
sepuas-puasnya
serba, serba-serbi
serejang
serela, serelanya
seresam (dng)
sering
sering-sering
serta-merta
sesanggup
sesayup-sayup
sesebentar
sesegera
sesekali
sesuang-suang
sesudah-sudahnya
sesuka-sukanya
sesukanya
sesungguhnya
setahu
setelah
setempat-setempat
setengah-setengah
seterusnya
setidak-tidaknya
setidaknya
seulang
seulas
seumumnya
seutuhnya
sewajarnya
sewajibnya
sewaktu-waktu
sewenang-wenang
seyogianya
sontak
suak
suang-suang
sudah
suka-suka
sungguh-sungguh
suntuk
taajul
tahu-tahu
takut-takut
tampaknya
tanpa
tas
telah
telentang
tempo-tempo
tengah
teramat
terkadang
terkadang-kadang
terkesot-kesot
terlalu
terlampau
terlebih
terlebih-lebih
terlebur
terputus-putus
tersipu
tersipu-sipu
terus-menerus
terus-terusan
tiba-tiba
tidak
tidak-tidak
tingkrang
trusa
tubi
tuji
tukung
tulang-tulangan
tunai
tunggang langgang
untung-untung
