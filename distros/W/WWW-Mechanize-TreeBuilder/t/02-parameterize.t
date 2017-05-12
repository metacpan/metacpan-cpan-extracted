use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../t/lib";

use Test::More tests => 9;

BEGIN { 
  use_ok 'WWW::Mechanize::TreeBuilder';
  use_ok 'MockMechanize';
};

my $mech = MockMechanize->new;

WWW::Mechanize::TreeBuilder->meta->apply(
  $mech, 
  tree_class => 'MockTreeBuilder'
);

can_ok($mech, "some_other_method" );
$mech->get_ok('/', 'Request ok');

# Check we can use normal TWMC methods
$mech->content_contains('A para');

ok($mech->has_tree, 'We have a HTML tree');

isa_ok($mech->tree, 'MockTreeBuilderEle');
is($mech->some_other_method, "I exist in MockTreeBuilderEle", "Delegated to subclass ok" );

is($mech->look_down(_tag => 'p')->as_trimmed_text, 'A para', "Got the right <p> out");

