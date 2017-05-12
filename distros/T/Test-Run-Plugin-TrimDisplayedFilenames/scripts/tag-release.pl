#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
    io->file('lib/Test/Run/Plugin/TrimDisplayedFilenames.pm')->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my $mod_name = 'Test-Run-Plugin-TrimDisplayedFilenames';
my @cmd = (
    "hg", "tag", "-m",
    "Tagging the $mod_name release as $version",
    "releases/modules/$mod_name/$version",
);

print join(" ", map { /\s/ ? qq{"$_"} : $_ } @cmd), "\n";
exec(@cmd);

