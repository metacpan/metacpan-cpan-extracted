package WordList::ID::Common::Wikipedia::Top500;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-11'; # DATE
our $DIST = 'WordLists-ID-Common'; # DIST
our $VERSION = '0.006'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_whitespace",0,"num_words_contains_nonword_chars",0,"longest_word_len",13,"avg_word_len",6.134,"num_words_contains_unicode",0,"num_words_contain_whitespace",0,"num_words_contain_unicode",0,"num_words_contain_nonword_chars",0,"shortest_word_len",2,"num_words",500); # STATS

our $SORT = 'frequency';

1;
# ABSTRACT: Top 300 words from Wikipedia Indonesia pages

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::Common::Wikipedia::Top500 - Top 300 words from Wikipedia Indonesia pages

=head1 VERSION

This document describes version 0.006 of WordList::ID::Common::Wikipedia::Top500 (from Perl distribution WordLists-ID-Common), released on 2020-10-11.

=head1 SYNOPSIS

 use WordList::ID::Common::Wikipedia::Top500;

 my $wl = WordList::ID::Common::Wikipedia::Top500->new;

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
Case-insensitively, words were then extracted from these files and merged to
become a single file. Then the list is manually curated to get the final 500 top
words (false positives, misspellings removed).

Note that Wikipedia article pages do not represent general Indonesian text, some
words are overrepresented e.g. "lagu" (in articles about particular songs) or
"filum".

Some words are derivative forms (not-root words), e.g. "makanannya" or
"berdasarkan".

=head1 WORDLIST STATISTICS

 +----------------------------------+-------+
 | key                              | value |
 +----------------------------------+-------+
 | avg_word_len                     | 6.134 |
 | longest_word_len                 | 13    |
 | num_words                        | 500   |
 | num_words_contain_nonword_chars  | 0     |
 | num_words_contain_unicode        | 0     |
 | num_words_contain_whitespace     | 0     |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 0     |
 | shortest_word_len                | 2     |
 +----------------------------------+-------+

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
kategori
ini
ke
dengan
dalam
untuk
adalah
tahun
web
oleh
sebagai
film
alih
juga
tidak
berkas
nama
kabupaten
merupakan
kota
menjadi
ia
atau
referensi
membuat
bagian
pengalihan
negara
sebuah
desa
itu
daftar
bahasa
spesies
orang
luar
tersebut
perubahan
pranala
telah
mereka
barat
selatan
dapat
satu
timur
karena
pengguna
kecamatan
kosmetika
utara
pertama
genus
memiliki
templat
provinsi
besar
ada
bahwa
lebih
seperti
album
serikat
akan
status
dunia
setelah
seorang
baru
lain
tengah
saat
lagu
secara
famili
beberapa
nasional
halaman
negeri
wilayah
tanggal
dia
kemudian
bola
salah
atas
dua
stasiun
kelas
daerah
para
artikel
jiwa
partai
banyak
tokoh
antara
musim
sepak
air
tempat
sekolah
penduduk
anak
raja
utama
robot
kayu
pemain
sejarah
hari
kali
tetapi
anggota
kelurahan
tim
kepada
perang
udara
pulau
data
musik
menurut
kedua
piala
kumbang
sama
hanya
hingga
lalat
luas
biasanya
bangsa
menggunakan
namun
menteri
republik
universitas
hal
sendiri
tinggi
digunakan
bulan
sampai
umum
penghargaan
selama
yaitu
masa
sekarang
lainnya
ketika
hidup
tentang
history
waktu
presiden
bersama
raya
laut
terbaik
volume
tergolong
pembicaraan
domain
resmi
serta
isi
sungai
situs
sumber
sejak
rumah
karya
sangat
internasional
kembali
pendidikan
abad
episode
bawah
perusahaan
biologi
logo
kerajaan
terletak
sudah
mulai
bandar
sekitar
bisa
lihat
grup
gereja
kode
masih
program
tiga
mengalihkan
jalan
sistem
dikenal
kepala
panjang
berada
dewan
jenis
peta
kereta
liga
media
jumlah
pula
disebut
semua
melalui
video
tanah
saya
api
termasuk
terhadap
pusat
televisi
keuskupan
masyarakat
sehingga
sementara
filum
bagi
suku
berasal
planet
awal
diakses
bicara
kapal
suatu
kepulauan
agung
pemerintahan
label
kapital
laki
pernah
ganda
kecil
suara
departemen
memindahkan
distrik
sebelum
pemerintah
politik
terdapat
kepadatan
berbagai
putra
baik
rakyat
buku
catatan
tenggara
teks
kata
gunung
gambar
ibu
selain
tak
agama
harus
diri
acara
paling
hasil
bintang
menambah
putri
angkatan
jalur
pemilihan
lagi
pesawat
tumbuhan
museum
editor
asal
manusia
ketua
versi
lahir
seluruh
menyebabkan
akhir
diterbitkan
pemimpin
alkitab
seri
terjadi
keluarga
melakukan
hukum
bidang
final
drama
militer
berisi
lama
setiap
mana
terdiri
nomor
ekonomi
terakhir
ilmiah
serial
batang
wanita
olahraga
otoritas
ilmu
batu
sebelumnya
jika
dasar
stadion
muda
babak
bentuk
berdasarkan
sebagian
organisasi
memperbaiki
main
bumi
bernama
kelahiran
masing
perempuan
pengawasan
wakil
dilakukan
sering
pasukan
penyanyi
pilihan
maka
tanpa
kelompok
lalu
anda
budaya
akhirnya
pemeran
hubungan
perdana
laba
matahari
muslim
masuk
ketiga
festival
cukup
empat
penulis
kematian
didirikan
panas
bupati
sebesar
dirilis
memberikan
proses
cinta
berhasil
juta
periode
posisi
berita
dekat
gelar
bermain
sosial
klub
saja
judul
meskipun
khusus
kejuaraan
jenderal
tingkat
aktor
berikut
tetap
disediakan
badan
pangeran
seni
kerusakan
belum
surat
permainan
mengenai
lokasi
alam
umumnya
meninggal
sedang
area
gubernur
sultan
unit
jaya
migrasi
hak
lima
bukan
kaisar
bangunan
apa
kehidupan
peran
juara
agar
pun
berbeda
masjid
pertandingan
bank
radio
mempunyai
dibuat
pantai
cara
produksi
modern
novel
langsung
lisensi
ruang
tanjung
sutradara
studio
mungkin
tanda
bahan
model
total
karier
jabatan
perjanjian
penting
jadi
pembangunan
teknologi
tentara
kitab
kaki
kekaisaran
pendek
tanduk
mesin
pasar
taman
mendapatkan
informasi
undang
bekerja
maupun
genre
mata
stadium
keamanan
kiri
ditemukan
kementerian
berubah
makanan
tinggal
sedangkan
zaman
kita
terkenal
baris
digital
sebelah
cerita
sang
putih
ditebang
bantuan
mencapai
operasi
kawasan
