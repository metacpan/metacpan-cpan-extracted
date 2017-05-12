#!/usr/bin/env perl

use YAML::XS;
use File::Basename;
use FindBin qw($Bin $Script);

use Data::Dumper;

my %hash;

for( grep{ $_ !~ /$Script/}glob("$Bin/*"))
{
    $hash{basename $_} = YAML::XS::LoadFile $_;
};
print YAML::XS::Dump \%hash;
