use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use HTTP::Request::Common;
use Whelk;
use JSON::PP;

use lib 't/lib';

my $app = Whelk->new(mode => 'multi');
my $t = Kelp::Test->new(app => $app);

################################################################################
# This checks whether two resources with different formats can coexist together
# (yaml + json)
################################################################################

# JSON

$t->request(GET '/test')
	->code_is(200)
	->json_cmp({success => JSON::PP::true, data => 'hello, world!'});

# YAML

$t->request(GET '/deep')
	->code_is(200)
	->yaml_cmp({success => JSON::PP::true, data => 'hello, world!'});

done_testing;

