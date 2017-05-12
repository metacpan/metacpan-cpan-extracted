#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
    io->file("./lib/Test/Run/Plugin/BreakOnFailure.pm")->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my $mod_name = 'Test-Run-Plugin-BreakOnFailure';

my @cmd = (
    "hg", "tag", "-m",
    "Tagging $mod_name as $version",
    "releases/modules/plugins/backend/$mod_name/$version",
);

print join(" ", map { /\s/ ? qq{"$_"} : $_ } @cmd), "\n";
exec(@cmd);
