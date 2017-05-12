#!perl

use strict;
use warnings;
use File::Temp;
use File::Basename qw/basename/;
use File::Spec;
use File::Copy qw/copy/;
use Test::More tests => 174;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Text::Amuse::Compile;
use Data::Dumper;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my @valid = ('test.png', 't-a-test.jpg', 't-a-test.jpeg');
my @valid_in_option = map
  { File::Spec->rel2abs(File::Spec->catfile(qw/t resources/, $_)) }
  @valid;
my @invalid = ('a test', '/etc/passwd', 'blabla', '../../blah', '<script>', 'blablabla.pdf');

foreach my $cover (@valid) {
    diag "Testing $cover";
    my $wd = File::Temp->newdir(CLEANUP => 1);
    my $file = File::Spec->catfile($wd, "test.muse");
    copy(File::Spec->catfile(qw/t resources/, $cover),
         File::Spec->catfile($wd, $cover)) or die $!;
    diag "Creating and processing $file";
    my $muse = <<"MUSE";
#title Test
#cover $cover
#lang en

Hello there
MUSE
    write_file($file, $muse);
    my $c = Text::Amuse::Compile->new(tex => 1, zip => 1, epub => 1);
    $c->compile($file);
    my $zip = my $tex = my $epub = $file;
    $zip =~ s/\.muse/.zip/;
    $tex =~ s/\.muse/.tex/;
    $epub =~ s/\.muse/.epub/;
    ok (-f $zip, "Zip found");
    ok (-f $tex, "TeX found");
    ok (-f $epub, "EPUB found");
    my $body = read_file($tex);
    like $body, qr/includegraphics/;
    like $body, qr{\Q$cover\E}, "Found $cover in the body";
    my $zipobj = Archive::Zip->new;
    $zipobj->read($zip);
    ok ($zipobj->memberNamed("test/$cover"), "Found the cover in the zip");
    my $epubobj = Archive::Zip->new;
    $epubobj->read($epub);
    ok ($epubobj->memberNamed("OPS/$cover"), "Found the cover in the epub");
    $c = Text::Amuse::Compile->new(tex => 1, zip => 1, epub => 1, extra => { cover => 0 });
    $c->compile($file);
    $body = read_file($tex);
    unlike $body, qr/includegraphics/;
    $zipobj = Archive::Zip->new;
    $zipobj->read($zip);
    ok (!$zipobj->memberNamed("test/$cover"), "No cover in the zip");
    $epubobj = Archive::Zip->new;
    $epubobj->read($epub);
    ok (!$epubobj->memberNamed("OPS/$cover"), "No cover in the epub");
}

foreach my $file (@valid_in_option) {
    my $cover = $file;
    my $wd = File::Temp->newdir(CLEANUP => 1);
    my $file = File::Spec->catfile($wd, "test.muse");
    diag "Creating and processing $file";
    my $muse = <<"MUSE";
#title Test
#lang en
#cover ignored.png

Hello there
MUSE
    copy(File::Spec->catfile(qw/t resources/, 'test.png'),
         File::Spec->catfile($wd, 'ignored.png')) or die $!;
    write_file($file, $muse);
    my $c = Text::Amuse::Compile->new(tex => 1, zip => 1, epub => 1,
                                      extra => { cover => $cover });
    my $basename = basename($cover);
    diag "Testing $cover ($basename)";
    $c->compile($file);
    my $zip = my $tex = my $epub = $file;
    $zip =~ s/\.muse/.zip/;
    $tex =~ s/\.muse/.tex/;
    $epub =~ s/\.muse/.epub/;
    ok (-f $zip, "Zip found");
    ok (-f $tex, "TeX found");
    ok (-f $epub, "EPUB found");
    my $body = read_file($tex);
    $cover =~ s!\\!/!g;
    like $body, qr{\Q$cover\E}, "Found $cover in the body";
    unlike $body, qr{ignored\.png}, "Ignored file cover in the body";
    my $zipobj = Archive::Zip->new;
    $zipobj->read($zip);
    ok ($zipobj->memberNamed("test/$basename"), "Found the cover in the zip");
    ok (!$zipobj->memberNamed("test/ignored.png"), "Ignored file the cover in the zip");
    my $epubobj = Archive::Zip->new;
    $epubobj->read($epub);
    ok ($epubobj->memberNamed("OPS/$basename"), "Found the cover in the epub");
    ok (!$zipobj->memberNamed("OPS/ignored.png"), "Ignored file cover in the epub");
}

foreach my $cover (@valid_in_option) {
    my $wd = File::Temp->newdir(CLEANUP => 1);
    my $file = File::Spec->catfile($wd, "test.muse");
    diag "Creating and processing $file";
    my $muse = <<"MUSE";
#title Test
#lang en
#cover $cover

Hello there
MUSE
    ok (-f $cover, "$cover exists");
    write_file($file, $muse);
    my $c = Text::Amuse::Compile->new(tex => 1, zip => 1, epub => 1);
    $c->compile($file);
    my $zip = my $tex = my $epub = $file;
    $zip =~ s/\.muse/.zip/;
    $tex =~ s/\.muse/.tex/;
    $epub =~ s/\.muse/.epub/;
    ok (-f $zip, "Zip found");
    ok (-f $tex, "TeX found");
    ok (-f $epub, "EPUB found");
    my $basename = basename($cover);
    my $body = read_file($tex);
    unlike $body, qr/includegraphics/;
    my $zipobj = Archive::Zip->new;
    $zipobj->read($zip);
    my $epubobj = Archive::Zip->new;
    $epubobj->read($epub);
    ok (!$zipobj->memberNamed("test/$basename"), "Ignored file $basename the cover in the zip");
    ok (!$epubobj->memberNamed("OPS/$basename"), "Ignored file $basename the cover in the epub");
}

foreach my $cover (@invalid) {
    for my $inoption (0,1) {
        my $wd = File::Temp->newdir(CLEANUP => 1);
        my $file = File::Spec->catfile($wd, "test.muse");
        diag "Creating and processing $file with cover $cover (in option: $inoption)";
        copy(File::Spec->catfile(qw/t resources/, 'test.png'),
             File::Spec->catfile($wd, 'ignored.png')) or die $!;
        my $embedded = $inoption ? 'ignored.png' : $cover;
        my $muse = <<"MUSE";
#title Test
#lang en
#cover $embedded

Hello there
MUSE
        write_file($file, $muse);
        my %args = (tex => 1, zip => 1, epub => 1);
        if ($inoption) {
            $args{extra} = { cover => $cover };
        }
        my $c = Text::Amuse::Compile->new(%args);
        $c->compile($file);
        my $zip = my $tex = my $epub = $file;
        $zip =~ s/\.muse/.zip/;
        $tex =~ s/\.muse/.tex/;
        $epub =~ s/\.muse/.epub/;
        ok (-f $zip, "Zip found");
        ok (-f $tex, "TeX found");
        ok (-f $epub, "EPUB found");
        my $body = read_file($tex);
        if ($inoption and $cover =~ m/\A[a-z0-9A-Z]\z/) {
            
        }
        if (($cover eq 'blablabla.pdf' or $cover eq 'blabla') and $inoption) {
            like $body, qr/includegraphics/;
        }
        else {
            unlike $body, qr/includegraphics/;
        }

        my $zipobj = Archive::Zip->new;
        $zipobj->read($zip);
        my $epubobj = Archive::Zip->new;
        $epubobj->read($epub);
        my $basename = basename($cover);
        
        ok (!$zipobj->memberNamed("test/$basename"), "Ignored file $basename the cover in the zip");
        ok (!$epubobj->memberNamed("OPS/$basename"), "Ignored file $basename the cover in the epub");
        ok (!$zipobj->memberNamed("test/ignored.png"), "Ignored file the cover in the zip");
        ok (!$epubobj->memberNamed("OPS/ignored.png"), "Ignored file the cover in the epub");
    }
}
