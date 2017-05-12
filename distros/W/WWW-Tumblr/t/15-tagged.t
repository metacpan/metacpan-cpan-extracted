use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $t = WWW::Tumblr::Test::tumblr();

my $tagged = $t->tagged( tag => 'perl' );

ok $tagged,     'tagged was ok';

done_testing();


