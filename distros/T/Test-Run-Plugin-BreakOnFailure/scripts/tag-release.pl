#!/usr/bin/perl

use strict;
use warnings;

use Path::Tiny qw/ path /;

my ($version) =
    ( map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
        path('lib/Test/Run/Plugin/BreakOnFailure.pm')->lines_utf8() );

if ( !defined($version) )
{
    die "Version is undefined!";
}

my $mod_name = 'Test-Run-Plugin-BreakOnFailure';
my @cmd      = (
    "git", "tag", "-m",
    "Tagging the $mod_name release as $version",
    "releases/modules/$mod_name/$version",
);

print join( " ", map { /\s/ ? qq{"$_"} : $_ } @cmd ), "\n";
exec(@cmd);
