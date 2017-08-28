use strict;
use warnings;

use Test::More tests => 3;


BEGIN { use_ok('WebService::Europeana') || BAIL_OUT("Can't use WebService::Europeana"); }

my $Europeana = WebService::Europeana->new(wskey=>"BADKEY");
my $result = $Europeana->search(query=>'Austria', rows=> 1);

is($result->{success},0,"search is not successful without an API key..");
like($result->{error_msg},qr/401 Unauthorized/,"search is forbidden without an API key..");


