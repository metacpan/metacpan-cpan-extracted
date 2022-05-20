#!/usr/bin/perl

use strict;
use warnings;

use Path::Tiny qw/ path /;

my ($version) =
    ( map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
        path('lib/XML/LibXSLT.pm')->lines_utf8() );

if ( !defined($version) )
{
    die "Version is undefined!";
}

my $DIST = "XML-LibXSLT";
my @cmd  = (
    "git", "tag", "-m", "Tagging the $DIST release as $version",
    "${DIST}-$version",
);

print join( " ", map { /\s/ ? qq{"$_"} : $_ } @cmd ), "\n";
exec(@cmd);
