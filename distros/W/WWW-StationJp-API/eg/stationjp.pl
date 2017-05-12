use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::StationJp::API;
use Data::Dumper;

my $station = new WWW::StationJp::API();

my $pref_list = $station->line({linecode => 11302});

print Dumper $pref_list;
