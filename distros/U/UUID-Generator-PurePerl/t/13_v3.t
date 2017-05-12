use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

plan tests => 3;

eval q{ use UUID::Generator::PurePerl; };
die if $@;

my $g = UUID::Generator::PurePerl->new();

# example in RFC 4122 is wrong
#   ng: e902893a-9d22-3c7e-a7b8-d6e313b71d9f
#   ok: 3d813cbb-47fb-32ba-91df-831e1593ac29

my $uuid = $g->generate_v3(uuid_ns_dns(), 'www.widgets.com');

is( lc($uuid->as_string), '3d813cbb-47fb-32ba-91df-831e1593ac29', 'RFC 4122 example' );

is( $uuid->variant, 2, 'variant = 2' );
is( $uuid->version, 3, 'version = 3' );
