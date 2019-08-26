#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    ( map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
        io->file('lib/XML/Grammar/Fortune/Synd.pm')->getlines() );

if ( !defined($version) )
{
    die "Version is undefined!";
}

my @cmd = (
    "git", "tag", "-m",
    "Tagging the XML-Grammar-Fortune-Synd release as $version",
    "releases/XML-Grammar-Fortune-Synd/cpan/$version",
);

print join( " ", map { /\s/ ? qq{"$_"} : $_ } @cmd ), "\n";
exec(@cmd);

