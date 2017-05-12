use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../t/lib";

use Test::More tests => 14;

BEGIN { 
  use_ok 'WWW::Mechanize::TreeBuilder';
  use_ok 'MockMechanize';
};

my $mech = MockMechanize->new;

WWW::Mechanize::TreeBuilder->meta->apply( $mech );

# Check that the clone come from WWW::Mech, not HTML::TreeBuilder
my @meths = $mech->meta->find_all_methods_by_name('clone');

is( 
  grep( { $_->{code}{delegate_to_method} }  $mech->meta->find_all_methods_by_name('clone')),
  0,
  "clone not delegated to tree"
);

$mech->get_ok('/', 'Request ok');

# Check we can use normal TWMC methods
$mech->content_contains('A para');

ok($mech->has_tree, 'We have a HTML tree');


isa_ok($mech->tree, 'HTML::Element');

is($mech->look_down(_tag => 'p')->as_trimmed_text, 'A para', "Got the right <p> out");

isa_ok($mech->find('h1'), 'HTML::Element', 'Can find an H1 tag');
like($mech->find('title')->as_trimmed_text, qr/\x{2603}/, 'Copes properly with utf8 encoded data'); # Snowman utf8 test

$mech->get_ok('/image', "Get image okay");
ok(!$mech->has_tree, "No tree for an image request");

$mech->get_ok('/plain', "Request plain text resource");

ok( !$mech->has_tree, "Plain text content-type has no tree");

