use strict;
use warnings;

use Test::More;
use Web::Feed;


plan tests => 1;

my $wf = Web::Feed->new;
isa_ok $wf, 'Web::Feed';


