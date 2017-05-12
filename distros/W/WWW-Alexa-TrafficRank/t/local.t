#!perl -w

use strict;
use warnings;
use Test;
BEGIN { plan tests => 1 }

use WWW::Alexa::TrafficRank; 
my $tr = WWW::Alexa::TrafficRank->new();

my $rank = $tr->get('filedir.com');

ok($rank);

exit;
__END__
