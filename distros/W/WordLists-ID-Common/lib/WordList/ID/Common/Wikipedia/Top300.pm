package WordList::ID::Common::Wikipedia::Top300;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-11'; # DATE
our $DIST = 'WordLists-ID-Common'; # DIST
our $VERSION = '0.006'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_whitespace",0,"num_words_contains_nonword_chars",0,"longest_word_len",12,"avg_word_len",5.91333333333333,"num_words_contain_whitespace",0,"num_words_contains_unicode",0,"num_words_contain_unicode",0,"num_words_contain_nonword_chars",0,"shortest_word_len",2,"num_words",300); # STATS

our $SORT = 'frequency';

1;
# ABSTRACT: Top 300 words from Wikipedia Indonesia pages

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::Common::Wikipedia::Top300 - Top 300 words from Wikipedia Indonesia pages

=head1 VERSION

This document describes version 0.006 of WordList::ID::Common::Wikipedia::Top300 (from Perl distribution WordLists-ID-Common), released on 2020-10-11.

=head1 SYNOPSIS

 use WordList::ID::Common::Wikipedia::Top300;

 my $wl = WordList::ID::Common::Wikipedia::Top300->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Iterate
 my $first_word = $wl->first_word;
 while (defined(my $word = $wl->next_word)) { ... }

 # Get all the words
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

This module contains 300 most frequently used Indonesian words in Wikipedia
Indonesian pages.

Here's how the list is produced: First the Wikipedia Indonesia's XML.bz2 [1] was
downloaded (last downloaded: Oct 11, 2020). Then a couple of ad-hoc, rather
simplistic Perl scripts were used to process this large file: one script to
split the file to a per-page basis, and the other to strip Wikimedia markup.
Words were then extracted from these files and merged to become a single file.
Then the list is manually curated to get the final 300 top words (false
positives, misspellings removed).

Note that Wikipedia article pages do not represent general Indonesian text, some
words are overrepresented e.g. "lagu" (in articles about particular songs) or
"filum".

Some words are derivative forms (not-root words), e.g. "makanannya" or
"berdasarkan".

=head1 WORDLIST STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 5.91333333333333 |
 | longest_word_len                 | 12               |
 | num_words                        | 300              |
 | num_words_contain_nonword_chars  | 0                |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 0                |
 | num_words_contains_nonword_chars | 0                |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 0                |
 | shortest_word_len                | 2                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordLists-ID-Common>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordLists-ID-Common>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordLists-ID-Common>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
dan
yang
di
dari
pada
ini
ke
dengan
adalah
untuk
dalam
tahun
oleh
sebagai
juga
tidak
merupakan
film
menjadi
atau
nama
itu
bagian
tersebut
sebuah
luar
telah
dapat
orang
satu
mereka
ia
negara
memiliki
karena
bahwa
pertama
lebih
kota
akan
ada
bahasa
seorang
seperti
besar
secara
saat
atas
kemudian
tanggal
jiwa
beberapa
salah
antara
bola
banyak
setelah
dua
baru
kepada
kali
penduduk
lagu
para
tetapi
tempat
menggunakan
anak
biasanya
sama
hingga
luas
sendiri
yaitu
hanya
tergolong
sampai
lainnya
hari
serta
dia
tentang
isi
hidup
utama
sekarang
dunia
sangat
bersama
bulan
masa
musik
artikel
kedua
kembali
daerah
terletak
selama
bawah
bisa
sudah
dikenal
sekitar
mulai
berada
menurut
masih
disebut
membuat
waktu
pula
pemain
umum
terhadap
termasuk
abad
melalui
sekolah
air
sejak
berasal
tinggi
ketika
sehingga
bagi
nasional
panjang
pernah
memindahkan
suatu
rumah
api
bicara
tiga
awal
peta
karya
berbagai
baik
laki
harus
semua
masyarakat
kecil
menyebabkan
sumber
kode
ganda
diterbitkan
perusahaan
paling
diri
lagi
terjadi
melakukan
sistem
tumbuhan
terdapat
saya
berisi
teks
terdiri
mana
sebelum
suara
sementara
kata
asal
jumlah
bernama
seluruh
terakhir
namun
masing
dilakukan
pemimpin
sejarah
pengawasan
kapal
sering
akhir
versi
manusia
barat
raja
kereta
grup
bentuk
tak
cukup
laut
setiap
acara
bidang
sebesar
tanah
pesawat
tanpa
berhasil
jenis
memberikan
timur
buku
tokoh
negeri
perempuan
masuk
bermain
juta
utara
akhirnya
pemerintahan
saja
dekat
selatan
maka
keluarga
disediakan
berdasarkan
didirikan
dasar
dirilis
putra
muda
sebagian
lalu
batang
gambar
serial
matahari
kerusakan
pendidikan
udara
daftar
ibu
perang
pemerintah
Anda
tetap
lama
agama
mengenai
pun
umumnya
ketiga
mempunyai
tengah
kelompok
dibuat
suku
agar
jalan
proses
sedang
main
pasukan
empat
langsung
pusat
kepala
belum
hasil
laba
berbeda
penting
pilihan
media
meninggal
wanita
maupun
mendapatkan
tanduk
jika
bekerja
bintang
program
gelar
berubah
ditemukan
ditebang
mengebor
mungkin
mencapai
pulau
terkenal
pendek
kaki
penulis
bukan
tinggal
berita
menyatakan
stasiun
posisi
penyanyi
bumi
dianggap
muncul
Allah
seri
