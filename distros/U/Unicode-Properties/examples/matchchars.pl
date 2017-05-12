#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Unicode::Properties ':all';
my $type = 'InCJKUnifiedIdeographs';
my $matching = matchchars ($type);
printf "There are %d characters of type %s.\n", scalar (@$matching), $type;

