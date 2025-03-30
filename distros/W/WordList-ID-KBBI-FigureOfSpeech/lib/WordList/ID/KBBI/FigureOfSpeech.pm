package WordList::ID::KBBI::FigureOfSpeech;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-20'; # DATE
our $DIST = 'WordList-ID-KBBI-FigureOfSpeech'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::RandomSeekPick';

our %STATS = ("num_words_contains_unicode",0,"num_words_contains_nonword_chars",253,"num_words",253,"num_words_contain_nonword_chars",253,"num_words_contain_unicode",0,"avg_word_len",17.4782608695652,"num_words_contain_whitespace",253,"num_words_contains_whitespace",253,"shortest_word_len",10,"longest_word_len",143); # STATS

1;
# ABSTRACT: Indonesian figure of speech (kiasan) entries from Kamus Besar Bahasa Indonesia (KBBI), 3e

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::KBBI::FigureOfSpeech - Indonesian figure of speech (kiasan) entries from Kamus Besar Bahasa Indonesia (KBBI), 3e

=head1 VERSION

This document describes version 0.001 of WordList::ID::KBBI::FigureOfSpeech (from Perl distribution WordList-ID-KBBI-FigureOfSpeech), released on 2024-11-20.

=head1 SYNOPSIS

 use WordList::ID::KBBI::FigureOfSpeech;

 my $wl = WordList::ID::KBBI::FigureOfSpeech->new;

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

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 17.4782608695652 |
 | longest_word_len                 | 143              |
 | num_words                        | 253              |
 | num_words_contain_nonword_chars  | 253              |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 253              |
 | num_words_contains_nonword_chars | 253              |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 253              |
 | shortest_word_len                | 10               |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ID-KBBI-FigureOfSpeech>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ID-KBBI-FigureOfSpeech>.

=head1 SEE ALSO

L<ArrayData::Lingua::Word::ID::KBBI::FigureOfSpeech> contains the same data.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-ID-KBBI-FigureOfSpeech>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
ada berair juga rupanya
akal bulus
asalnya dr kubang
ayam kebiri meskipun tidak dipupuk , gemuk juga
baju songsong barat
basah kerongkongan
becermin bangkai
beradu buku tangan
beradu kening
beradu lengan
beradu lidah
beradu mulut
berair rongkong
beralam lapang
beralih haluan
beranggar lidah
beranggar pena
beranggar pikiran
berangin-angin ke telinga
berat pinggul
bercemar kain
bercemar kaki
berdiri sama tinggi
berdiri sendiri
berganjur-ganjur surut
bergelanggang di mata orang banyak
bergendang lutut
bergetah bibirnya
bergoyang kaki
bergoyang lidah
bergoyang lutut
bergulung dng utang
berhabis air
berilmu lintabung
berilmu padi
berjalan di atas rel
berjantung pisang
berkata menentang benar
berkepala dua
berkisar angan
berlaga kasih
berlayar ke pulau kapuk
berlipat perut
berpangku tangan
berpegangan tangan
berpeluh darah
berpeluk tubuh
berpumpun abu
berputar lidah
berserah diri
berserah jiwa raga
bertanam kasih
bertangan besi
bertelau-telau spt panas di belukar
bertelinga lembut
bertelinga merah
bertelinga tebal
berteras ke dalam
bertimba karang
bertongkat senduk
bertongkat tebu
berulas tangan
berulat mata melihat
berurat berumbi
beternak uang
bintangnya mengiri
dapur tidak berasap
darahnya mendidih
dilapih kelembai
ditebuk tikus
ditimang alun asmara
eram, mengeram v 1 duduk mendekam untuk memanaskan telur agar menetas (tt ayam, burung): beberapa ekor ayamnya sedang eram; selama enggang eram
hidup menentang mati
ibarat menuang minyak ke api
ilmu lintabung
kambing perahan; sapi perahan
kehilangan muka
kehilangan nama baik
kepecahan telur sebutir
ketinggian budi
kupu-kupu malam
lampung pukat
lembaran hitam
lidah tergalang
limau masak seulas
mabuk cinta
makan keringat orang
mata wayang
melembungkan dada
melepaskan dahaga
melepaskan ikatan
melepaskan lapar
melepaskan lelah
melepaskan malu
melepaskan untung
melilit pinggang
melintah darat
memasang kuda-kuda
membakar janggut
membanting harga
membanting tulang
membawa kakinya
membawa tempurung
memberi muka
memberi telinga
memecahkan (anak) telinga
memecahkan otak
memecahkan telur
memedaskan hati
memegang batang
memegang batang leher
memegang besi panas
memegang cempurit
memegang ekor
memegang kemudi
memegang kitab
memelihara hati
memelihara lidah
memelihara mulut
memelihara tangan
memeluk sengsara
memenggal leher
memenggal lidah
memeras keringat
memeras otak
memicit rakyat
memperhujankan garamnya
memperlebar sayap
mempertajam sanding
mempertebarkan kecek
memutar lidah
memutar otak
memutihkan mata
menabur biji di atas batu
menadah matahari
menakik rezeki
menangkap angin
menangkap basah
menangkap bayang-bayang
menapakkan kaki
menarik bayangan
menarik jiwa
mencabik arang
mencabut nyawa
mencarak benak
mencarikan perut (yg tidak berisi)
mencucurkan keringat
mendaging ayam
mendarah daging
mendaun kunyit
menelur burung
menepak-nepak paha
menepik mata pedang
menepuk dada
mengalit perut
mengambil hati
mengambil muka
mengarungi hidup baru
mengasah bakat
mengasah budi
mengasah hati
mengasah otak
mengasah pikiran
mengejar waktu
mengelus dada
mengembangkan hati
mengembuskan napas terakhir
mengerami telur orang
mengetuk hati
menggalangkan batang leher
menggantang anak ayam
menggantang asap
menggantung talak
menggaruk-garuk kepala
menggeli induk ayam
menggenggam rahasia
menggerekkan tutur kata ke telinga
menggetah bawang
menggigit jari
menggigit lidah
menggigit pangsa
menggores hati
menggoyangkan lidah
menghunjamkan lutut nan dua
mengikat tidak bertali
mengisap benak
mengisap darah
mengukir dl hati
mengukur jalan
mengulur lidah
mengurut hati
mengurut kuduk
meninggikan diri
meniti buih
menjadi air
menjadi air mandi
menjadi bumi langit
menjemput bola
menjengkal dada
menjengkal muka
menjilat bibir
menjilat ludah
menjilat pantat
menjual petai hampa
menungkup menelentang
menunjukkan belangnya
menunjukkan bulu
menyaringkan telinga
merajut badan
merajut perut
merambakkan uang
merampat papan
meratakan jalan
merem-merem, merem ayam
orang ombak
pakaian hidup
panjang urat belikat
patah batu hatinya
paut tidak bertali
pemuda tawon
penawar hati
pengarang jantung
penuh sudah bagai menggantang
perah keringat
perah otak
petani gurem
pikirannya mengawang
pinggang ramping bagai ketiding
pipinya spt pauh dilayang
pukulan berat
selapik seketiduran
selebar kangkang kera
sempit akal
sepertiga malam
sudah melaut mendarat
tahu menimbang rasa
takaran sudah hampir penuh
tangan-tangan siluman
tatahan negara
tautan hati
tepatan jiwa
tepercik peluh(nya)
tepian mata
terban bumi tempat berpijak
tergores dl hati
terkunyah di batu
terlampau tinggi patah, terlampau panggang angus
tertawa membawa roboh
terulur lidah
tetesan pena
tidak mengetahui daratan lagi
tidak menghangat mendingin
tumpuan arus
