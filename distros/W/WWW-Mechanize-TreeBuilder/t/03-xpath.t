use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../t/lib";
use Test::More;

eval { require HTML::TreeBuilder::XPath; };

if ($@) {
 plan skip_all => "This test needs HTML::TreeBuilder::XPath";
} else {
 plan tests => 6
}

use_ok 'WWW::Mechanize::TreeBuilder';
use_ok 'MockMechanize';

my $mech = MockMechanize->new;

WWW::Mechanize::TreeBuilder->meta->apply(
  $mech,
  tree_class => 'HTML::TreeBuilder::XPath'
);

can_ok($mech, "find_xpath" );
$mech->get_ok('/', 'Request ok');

# Check we can use normal TWMC methods
$mech->content_contains('A para');

is( $mech->find_xpath('//h1')->string_value, 'It works', 'find_xpath works');
