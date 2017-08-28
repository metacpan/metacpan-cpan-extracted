#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use XS::Check;
my $check = XS::Check->new ();
$check->check_file ("$Bin/synopsis.xs");
