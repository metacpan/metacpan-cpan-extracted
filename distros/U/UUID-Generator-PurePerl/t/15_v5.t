use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

eval q{ use Digest };
plan skip_all => "Digest is not installed." if $@;

eval { Digest->new('SHA-1') };
plan skip_all => "Digest for SHA-1 is not installed." if $@;

plan tests => 3;

eval q{ use UUID::Generator::PurePerl;
        use UUID::Object; };
die if $@;

my $g = UUID::Generator::PurePerl->new();

my $uuid = $g->generate_v5(uuid_ns_dns(), 'www.widgets.com');

is( lc($uuid->as_string), '21f7f8de-8051-5b89-8680-0195ef798b6a', 'RFC 4122 example' );

is( $uuid->variant, 2, 'variant = 2' );
is( $uuid->version, 5, 'version = 5' );
