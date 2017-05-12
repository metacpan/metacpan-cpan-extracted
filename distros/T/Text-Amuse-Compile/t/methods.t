#!perl

use strict;
use warnings;
use Test::More tests => 19;
use Text::Amuse::Compile;
use Text::Amuse::Compile::File;
use Data::Dumper;
use File::Temp;
use File::Spec;
use Text::Amuse::Compile::Utils qw/write_file/;

my $c = Text::Amuse::Compile->new(pdf => 1);

is_deeply([$c->compile_methods], [ qw/pdf/ ]);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1);

is_deeply([$c->compile_methods], [ qw/epub pdf/ ]);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1);

is_deeply([$c->compile_methods], [ qw/epub tex  pdf/ ]);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1, slides => 1);

is_deeply([$c->compile_methods], [ qw/epub tex  pdf sl_pdf/ ]);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1, sl_pdf => 1);

is_deeply([$c->compile_methods], [ qw/epub tex  pdf sl_pdf/ ]);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1, sl_pdf => 1, slides => 0);

is_deeply([$c->compile_methods], [ qw/epub tex  pdf sl_pdf/ ]);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1, sl_pdf => 0, slides => 1);

is_deeply([$c->compile_methods], [ qw/epub tex  pdf sl_pdf/ ]);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1, sl_pdf => 1, slides => 1);

is_deeply([$c->compile_methods], [ qw/epub tex  pdf sl_pdf/ ]);


is $c->_suffix_for_method('bare_html'), '.bare.html';
is $c->_suffix_for_method('tex'), '.tex';
is $c->_suffix_for_method('a4_pdf'), '.a4.pdf';
is $c->_suffix_for_method('sl_pdf'), '.sl.pdf';
is $c->_suffix_for_method('pdf'), '.pdf';

my $wd = File::Temp->newdir;

my $stale = File::Spec->catfile($wd->dirname, "test.html");
sleep 2;
my $testfile = File::Spec->catfile($wd->dirname, "test.muse");
write_file($testfile, ".\n");
sleep 2;
foreach my $ext (qw/tex pdf epub/) {
    write_file(File::Spec->catfile($wd->dirname, "test.$ext"), ".\n");
}

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, html => 1);

is ( $c->file_needs_compilation($testfile), 1,
     "$testfile need compile, html stale" ) or inspect_wd($wd->dirname);

$c = Text::Amuse::Compile->new(pdf => 1, epub => 1, tex => 1);

is ( $c->file_needs_compilation($testfile), 0,
     "$testfile is already compiled for pdf, epub, tex" )
  or inspect_wd($wd->dirname);;

$c = Text::Amuse::Compile->new(pdf => 1, tex => 1);

is ( $c->file_needs_compilation($testfile), 0,
     "$testfile is already compiled for pdf and tex" ) or inspect_wd($wd->dirname);

$c = Text::Amuse::Compile->new(pdf => 1, tex => 1, zip => 1);

is ( $c->file_needs_compilation($testfile), 1,
     "$testfile is not fully compiled for pdf, tex, zip" )
  or inspect_wd($wd->dirname);

write_file(File::Spec->catfile($wd->dirname, "test.zip"), "blkasdf");

is ( $c->file_needs_compilation($testfile), 0,
     "$testfile is ok now for pdf, tex, zip" ) or inspect_wd($wd->dirname);

sub inspect_wd {
    my $wd = shift;
    die "Missing arg" unless $wd;
    die "$wd is not a dir" unless -d $wd;
    opendir my $dh, $wd or die $!;
    my @files = grep { -f File::Spec->catfile($wd, $_) } readdir $dh;
    closedir $dh;
    my %out;
    foreach my $file (@files) {
        $out{$file} = (stat(File::Spec->catfile($wd, $file)))[9];
    }
    diag Dumper(\%out);
}

my @expected = (
                '.pdf',
                '.a4.pdf',
                '.lt.pdf',
                '.tex',
                '.log',
                '.nav',
                '.snm',
                '.tuc',
                '.vrb',
                '.out',
                '.aux',
                '.toc',
                '.ok',
                '.html',
                '.bare.html',
                '.epub',
                '.zip',
                '.sl.tex',
                '.sl.pdf',
                '.sl.log',
                '.sl.nav',
                '.sl.toc',
                '.sl.aux',
                '.sl.vrb',
                '.sl.tuc',
                '.sl.snm',
                '.sl.out'
               );
is_deeply([ sort Text::Amuse::Compile::File->purged_extensions ],
          [ sort @expected ],
          "Purged extensions ok");

