use strict;
use warnings;
use Test::More;
use URL::Signature;

my $obj;

eval {
    $obj = URL::Signature->new;
};
like $@, qr{you must specify a secret key!} => 'key is required by contructor';

eval {
    $obj = URL::Signature->new( key => {} );
};
like $@, qr{you must specify a secret key!} => 'key must be a valid string';

eval {
    $obj = URL::Signature->new( key => 'foo' );
};
ok !$@ => 'valid key creates object' . ' --> ' . $@;

can_ok $obj, qw( new sign validate code_for_uri extract append );

my $uri = $obj->sign( 'example.com/foo/bar' );

ok defined $uri => 'sign() returns something';
isa_ok $uri, 'URI' => 'sign() returns an URI object';

is "$uri",
   'example.com/1RBcy0FMGFnrkp1shXH3lZYxzH8/foo/bar'
    => "sign() returns properly signed path: $uri";


my $valid =  $obj->validate( "$uri" );
ok $valid => 'validate() returns true for valid uri';
is "$valid", 'example.com/foo/bar' => 'valid uri is stripped of mac';

$uri = $obj->sign( 'example.com/meep/moop?language=perl&answer=42' );
is "$uri",
   'example.com/iOAL5YwtNCCZgz7QiEir-RgrNMY/meep/moop?answer=42&language=perl'
   => "sign() also works for paths with query strings: $uri";

$valid = $obj->validate( "$uri" );
ok $valid => 'validate() returns true for valid paths with query strings';
is "$valid",
   'example.com/meep/moop?answer=42&language=perl'
   => 'valid uri is valid (for path with query strings)';

$valid = $obj->validate( 'example.com/iOAL5YwtNCCZgz7QiEir-RgrNMY/meep/moop?language=perl&answer=42' );
ok $valid => 'query order not relevant for validation';
is "$valid",
   'example.com/meep/moop?answer=42&language=perl'
   => 'valid uri is valid (for path with query strings - round 2)';




## same thing, as a query variable
eval {
    $obj = URL::Signature->new(
            key    => 'foo',
            format => 'query',
    );
};
ok !$@ => 'object creation ok (with query format)';

$uri = $obj->sign( 'example.com/foo/bar' );

ok defined $uri => 'sign() returns something (query mode)';
isa_ok $uri, 'URI' => 'sign() returns an URI object (query mode)';

is "$uri",
   'example.com/foo/bar?k=1RBcy0FMGFnrkp1shXH3lZYxzH8',
   => 'sign() returns properly signed path (query mode)';

$uri = $obj->sign( 'example.com/foo/bar?baz=meep&ping=pong' );
ok defined $uri => 'sign() return something (query mode 2)';
isa_ok $uri, 'URI' => 'sign() returns an URI object (query mode 2)';

my %q = $uri->query_form;
is_deeply \%q,
          {
              baz  => 'meep',
              ping => 'pong',
              k    => 'ICd7iQUOjxMXcevs4Ht8dC1SHnc',
          },
          => 'sign() returns properly signed path (query mode 2)';

$valid = $obj->validate("$uri");
ok $valid => "validate() returns true for valid uri '$uri' (query mode)";

$uri->query_form( map { $_ => $q{$_} } sort { $b cmp $a } keys %q );
$valid = $obj->validate("$uri");
ok $valid => "validate() doesn't care about query order in '$uri' (query mode)";


done_testing;
