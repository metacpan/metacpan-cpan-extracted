use strict;

use Test::More tests => 2;
use Data::Dumper;

use Yahoo::Search AppId => "Perl API install test",
                  Count => 1;

my @Results = Yahoo::Search->Results(Doc => 'Larry Wall');
#warn Dumper(\@Results);

is @Results, 1;

like $Results[0]->Url, qr{^https?://};
