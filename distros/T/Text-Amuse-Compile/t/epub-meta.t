#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 17;
use File::Spec;
use Text::Amuse::Compile;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Temp;
use Text::Amuse::Compile::Utils qw/read_file write_file/;

my $c = Text::Amuse::Compile->new(epub => 1);
my $target_base = File::Spec->catfile(qw/t testfile epub-meta/);
$c->compile($target_base . '.muse');
my $epub = $target_base . '.epub';
die "No epub produced, cannot continue!" unless -f $epub;
my $zip = Archive::Zip->new;
die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);

diag "Using " .$tmpdir->dirname;

$zip->extractTree('OPS', $tmpdir->dirname);

my $opf = read_file(File::Spec->catfile($tmpdir->dirname,
                                        'content.opf'));
my $expected = <<OPF;
<dc:creator opf:role="aut">Pippo</dc:creator>
<dc:creator opf:role="aut">"Pallino"</dc:creator>
<dc:creator opf:role="aut">'pinco' &amp; pallino</dc:creator>
<dc:creator opf:role="aut">&gt;pincu&lt;</dc:creator>
<dc:creator opf:role="aut">&lt;pinco&gt;</dc:creator>
<dc:creator opf:role="aut">'mauuu"</dc:creator>
<dc:subject>first</dc:subject>
<dc:subject>second</dc:subject>
<dc:subject>third</dc:subject>
<dc:subject>fourth</dc:subject>
<dc:subject>fifth</dc:subject>
<dc:subject>sixth</dc:subject>
<dc:subject>seventh</dc:subject>
<dc:subject>'five'</dc:subject>
<dc:subject>&amp;eight&amp;</dc:subject>
<dc:subject>my, &lt;precious&gt;</dc:subject>
<dc:subject>your, precious</dc:subject>
OPF

foreach my $string (split(/\n/, $expected)) {
    like $opf, qr{\Q$string\E}, "Found $string in the content.opf";
}
