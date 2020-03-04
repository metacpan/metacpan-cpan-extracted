#!perl

use utf8;
use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

plan tests => 14;

{
    my $doc = Text::Amuse->new(file => catfile(qw/t testfiles titles-anchors.muse/));

    is_deeply [$doc->raw_html_toc], [
                                     {
                                      'level' => '1',
                                      'named' => 'text-amuse-label-named1',
                                      'index' => 1,
                                      'string' => 'Part with an anchor'
                                     },
                                     {
                                      'string' => 'A chapter',
                                      'index' => 2,
                                      'level' => '2',
                                      'named' => 'text-amuse-label-again2'
                                     },
                                     {
                                      'index' => 3,
                                      'level' => '3',
                                      'named' => 'text-amuse-label-top1',
                                      'string' => 'A chapter'
                                     },
                                     {
                                      'level' => '4',
                                      'named' => 'text-amuse-label-top2',
                                      'index' => 4,
                                      'string' => 'A Section'
                                     }
                                    ], "Internal tok ok";

    my $html_toc = $doc->toc_as_html;
    my $body_html = $doc->as_html;
    while ($html_toc =~ m/href="\#(.*?)">/g) {
        my $anchor = $1;
        like $anchor, qr{^text-amuse-label-}, "Using custom label";
        like $body_html, qr{id="\Q$anchor\E"}, "$anchor found in body";
    }
}
{
    my $doc = Text::Amuse->new(file => catfile(qw/t testfiles titles-anchors-2.muse/));

    diag Dumper([$doc->raw_html_toc]);


    is_deeply [$doc->raw_html_toc], [
                                     {
                                      'level' => '1',
                                      'string' => 'Part without an anchor',
                                      'index' => 1
                                     },
                                     {
                                      'index' => 2,
                                      'string' => 'A chapter',
                                      'level' => '2',
                                      'named' => 'text-amuse-label-again2'
                                     },
                                     {
                                      'named' => 'text-amuse-label-top1',
                                      'string' => 'A chapter',
                                      'level' => '3',
                                      'index' => 3
                                     },
                                     {
                                      'string' => 'A Section',
                                      'level' => '4',
                                      'index' => 4
                                     }
                                    ], "Internal toc OK";
    my $html_toc = $doc->toc_as_html;
    my $body_html = $doc->as_html;
    while ($html_toc =~ m/href="\#(.*?)">/g) {
        my $anchor = $1;
        like $body_html, qr{id="\Q$anchor\E"}, "$anchor found in body";
    }
}
