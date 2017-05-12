#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 7;
use Text::Amuse::Functions qw/muse_to_html
                              muse_to_tex
                              muse_to_object
                             /;

use Data::Dumper;

{
    my $muse =<<'MUSE';

  C. test

Hello there

                         a. pinco

                         Signed.<br>
                         A. Pallino
MUSE

    my $html = muse_to_html($muse);
    unlike ($html, qr{list-style-type}, "Not a list");
    my $doc = muse_to_object($muse);
    # parse
    my @parsed = grep { $_->type ne 'null' } $doc->document->elements;
    is (scalar(@parsed), 13, "Found 13 elements");
    my $false_list = $parsed[0];
    is ($false_list->type, 'startblock');
    is ($false_list->block, 'quote');
}

{
    my $muse =<<'MUSE';

  Signed.

  A. Prova

     A. Prova

        A. Prova

           A. Prova      
   
              viii. Prova

                    A. Pallinox

        A. Prova

           A. Prova      


MUSE
    my $html = muse_to_html($muse);
    like ($html, qr{list-style-type}, "It's a list");
    my $doc = muse_to_object($muse);
    my @parsed = grep { $_->type ne 'null' } $doc->document->elements;
    # print Dumper(\@parsed);
    my $list = $parsed[3];
    is ($list->type, 'startblock', "list is ok");
    is ($list->block, 'olA', "block is ok");
}
