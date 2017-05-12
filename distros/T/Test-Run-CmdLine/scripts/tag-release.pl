#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
    io->file('lib/Test/Run/CmdLine.pm')->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my @cmd = (
    "hg", "tag", "-m",
    "Tagging the Test-Run-CmdLine release as $version",
    "releases/modules/Test-Run-CmdLine/$version",
);

print join(" ", map { /\s/ ? qq{"$_"} : $_ } @cmd), "\n";
exec(@cmd);

