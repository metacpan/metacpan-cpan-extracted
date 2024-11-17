use strict;
use warnings;
use utf8;

use Encode 'encode';
use Test2::V0 -target => 'UserAgent::Any';

my $fake = bless {}, 'LWP::UserAgent';

my $ua1 = CLASS()->new($fake);
my $ua2 = CLASS()->new($ua1);

DOES_ok($ua1, ['UserAgent::Any']);
DOES_ok($ua2, ['UserAgent::Any']);

isnt($ua1->_impl, exact_ref($fake), 'real constructor');
is($ua2->_impl, exact_ref($ua1), 'passthrough constructor');

todo "unimplemented" => sub {
  is($ua2, exact_ref($ua1), 'real passthrough constructor');
};

done_testing;
