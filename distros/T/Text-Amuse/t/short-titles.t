#!perl

use utf8;
use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

plan tests => 2;

my $doc = Text::Amuse->new(file => catfile(qw/t testfiles titles-short.muse/));

is_deeply([$doc->raw_html_toc],
          [
           {
            'index' => 1,
            'level' => '1',
            'string' => 'Short',
           },
           {
            'string' => 'Short',
            'level' => '2',
            'index' => 2
           },
           {
            'index' => 3,
            'level' => '3',
            'string' => 'Short',
           },
           {
             'index' => 4,
             'level' => '1',
             'string' => '| &lt;Weird&gt; &quot;\\\\one&quot;'
           },
           {
             'string' => '',
             'level' => '2',
             'index' => 5
           },
          ],
          "ToC is OK");

unlike $doc->toc_as_html, qr{\#toc5};
