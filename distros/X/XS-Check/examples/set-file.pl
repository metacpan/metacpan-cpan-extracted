#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use XS::Check;
my $check = XS::Check->new ();
my $xs = "Perl_croak (\"frog\")\n";
$check->check ($xs);
$check->set_file ('Yabadabado');
$check->check ($xs);
$check->set_file ('');
$check->check ($xs);
