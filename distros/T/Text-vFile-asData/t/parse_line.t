#!/usr/bin/perl -w
use strict;
use Test::More;
use Text::ParseWords ();
use Text::vFile::asData ();


if (eval "require Test::Differences") {
    no warnings 'redefine';
    *is_deeply = \&Test::Differences::eq_or_diff;
}

sub same {
    is_deeply( [[ Text::vFile::asData::parse_line( @_ ) ]],
               [[ Text::ParseWords::parse_line( @_ ) ]],
               "same( " .( join ", ", map { "'$_'" } @_ ) ." )");
}

for my $string ( 'foo', 'foo:', 'foo:bar', 'foo:bar:' ) {
    for my $keep (0, 1) {
        same( ':', $keep, $string );
    }
}

done_testing();
