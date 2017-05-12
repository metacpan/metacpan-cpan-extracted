#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 81;
use File::Spec;
use Text::Amuse::Compile;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Temp;
use Data::Dumper;
use Text::Amuse;
use Text::Amuse::Compile::Utils qw/read_file write_file/;

my $testnotoc =<<'MUSE';
#lang en
#title helloooo <&!"'title>

Hello

MUSE

my $test_no_intro =<<'MUSE';
#lang en
#title Hullllooooo <&!"'title>

*** subsection

* Part

** Chap 1

** Chap 2

**** Subsection
MUSE

my $testbody =<<'MUSE';
#title hello world <&!"'title>

Hello world!

**** Intro

Introduction

* Part 1

**** subsection before chapter

** Chapter *1*

Chapter body

*** Section *1.1*

Section body

*** Section **1.2**

Section body

** Chapter *2*

Chapter body

**** subsection of chapter 2

*** Section **2.1**

Section body

**** Subsection 2.1.1 & test

Subsection body

**** Subsection 2.1.1

Subsection body 2

** Chapter 3

Section 

**** Subsection 3.0.1 [1]

Subsection

[1] example

Subsection

***** Subsubsection

Subsub section

* Part 2

Part again

*** Section of second part

** Chapter of second part

**** Subsection of chap 1 of part 2.

* Part 3

**** Subsection of part 3

** Chapter 1 of part 3

**** Subsection of part 3, chap 1

** Chapter 2 of part 3

** Chapter 3 of part 3

MUSE

my @tests = (
             {
              body => $testnotoc,
              name => 'notoc',
              out_of_sec => 1,
             },
             {
              body => $test_no_intro,
              name => 'nointro',
              out_of_sec => 0,
             },
             {
              body => $testbody,
              name => 'full',
              out_of_sec => 1,
             }
            );

foreach my $muses (@tests) {
    my $body = $muses->{body};
    my $tmpdir = File::Temp->newdir(CLEANUP => 1);
    my $tmpdirname = $tmpdir->dirname;

    my $c = Text::Amuse::Compile->new(epub => 1);

    my $musefile = File::Spec->catfile($tmpdirname, 'test.muse');
    my $epub = File::Spec->catfile($tmpdirname, 'test.epub');

    write_file($musefile, $body);

    ok(-f $musefile, "$musefile generated");

    $c->compile($musefile);

    ok(-f $epub, "$epub generated");

    my $muse = Text::Amuse->new(file => $musefile);

    # diag Dumper ($muse->raw_html_toc);


    my $zip = Archive::Zip->new;
    die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;

    $zip->extractTree('OPS', $tmpdirname) == AZ_OK
      or die "Couldn't extract $epub OPS into $tmpdirname" ;
    my $indexfile = File::Spec->catfile($tmpdirname, 'toc.ncx');
    ok (-f $indexfile, "$indexfile found");
    my $toc = read_file($indexfile);

    # diag $toc;
    my $current_toc = 0;
    while ($toc =~ m/playOrder="(\d+)"/g) {
        my $playorder = $1;
        is ($playorder, $current_toc + 1, "Order ok: $playorder");
        $current_toc = $playorder;
    }

    my $countpart = 1 + $muses->{out_of_sec}; # with the title and the intro material
    $countpart++ while $body =~ m/^\*{1,4}\s/gm;
    is $current_toc, $countpart, "Found all $countpart parts";

    # check the order of the file, even if it should be good:
    my $piececounter = 1 - $muses->{out_of_sec};
    my @files = ('titlepage.xhtml');
    while ($piececounter < $countpart) {
        push @files, sprintf('piece%06d.xhtml', $piececounter);
        $piececounter++;
    }

    while ($toc =~ m/src="(.*?)"/g) {
        my $got = $1;
        my $expected = shift @files;
        is $got, $expected, "Found $expected in file list";
    }
    if ($toc =~ m{docTitle>\s*<text>(.*?)</text>\s*</docTitle>}s) {
        my $titlestring = $1;
        like $toc, qr{playOrder="1">\s*<navLabel>\s.*<text>\Q$titlestring\E}, "Found the title $titlestring";
    }
    else {
        ok(0, "No docTitle found");
    }
}

