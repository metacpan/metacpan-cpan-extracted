#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use XS::Check;
my $rchecker = XS::Check->new (reporter => \& reporter);
$rchecker->check ("Perl_croak ('croaking');\n");
sub reporter
{
    my %rstuff = @_;
    print "$rstuff{message} at $rstuff{line}.\n";
}

