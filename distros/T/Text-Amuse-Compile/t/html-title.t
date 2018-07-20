#!perl

use strict;
use warnings;
use utf8;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Spec::Functions qw/catfile/;
use Test::More tests => 1;

my $c = Text::Amuse::Compile->new(html => 1);
$c->compile(catfile(qw/t testfile html-title.muse/));
my $html = read_file(catfile(qw/t testfile html-title.html/));
my $exp = "<title>This is my title &amp;&amp; &quot;another&quot;</title>";
like $html, qr{\Q$exp\E};




