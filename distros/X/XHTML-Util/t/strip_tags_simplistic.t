#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;

ok( my $xu = XHTML::Util->new,
    "XHTML::Util->new " );

my $src = join"",<DATA>;

ok( my $strip = $xu->strip_tags($src),
    "strip_tags() the test text"
    );

is( $strip, $src,
    "strip_tags() without strip list returns unmodified content");

dies_ok( sub { $xu->strip_tags($src, ["a"]) },
         "strip_tags() dies with incorrect strip list"
         );

ok( $xu->strip_tags($src, "wrong"),
    "Running on 'wrong' tag"
    );

is( $strip, $src,
    "strip_tags() returns unmodified with non-existent tag" );

ok( $strip = $xu->strip_tags($src, "a"),
    "strip_tags(...'a')"
    );

is( $strip, _fixed(),
    "strip_tags() took <a/> out correctly"
    );

diag("Stripped: $strip") if $ENV{TEST_VERBOSE};

sub _fixed {
    q{<span>May <i>all</i> shoes thrown ever connect : منتظر الزيدي</span>}
}


__DATA__
<span><a title="May all shoes thrown ever connect : منتظر الزيدي" href="http://sedition.com/">May <i>all</i> shoes thrown ever connect : منتظر الزيدي</a></span>

