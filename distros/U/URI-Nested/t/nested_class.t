#!/usr/bin/perl -w

use strict;
use Test::More;
use utf8;
use URI;
use URI::QueryParam;

SUBCLASS: {
    package URI::_blah;
    use base 'URI::_login';

    package URI::blah;
    use base 'URI::Nested';
    sub prefix       { 'blah' }
    sub nested_class { 'URI::_blah' }
}


isa_ok my $uri = URI->new('blah:'), 'URI::blah', 'Opaque BLAH URI';
is $uri->scheme, 'blah', 'BLAH URI with no engine should have scheme "blah"';

# Try changing the scheme.
is $uri->scheme('Blah'), 'blah', 'Change scheme to "Blah"';
isa_ok $uri, 'URI::blah';
is $uri->scheme, 'blah', 'New scheme should still be "blah"';
is $uri->as_string, 'Blah:', 'Should stringify with the new scheme';

# Change the scheme to something other than blah.
eval { $uri->scheme('foo') };
ok my $err = $@, 'Should get error changing to non-BLAH scheme';
like $err, qr/Cannot change URI::blah scheme/, 'Should be the proper error';

# Now use a non-blah-qalified URI.
isa_ok $uri = URI->new('nonesuch:'), 'URI::_foreign', 'Opaque Nonesuch URI';
is $uri->scheme, 'nonesuch', 'Nonesuch URI scheme should be "nonesuch"';

# Try constructor.
isa_ok $uri = URI::blah->new('nonesuch:'), 'URI::blah', 'nonesuch URI';
isa_ok $uri->nested_uri, 'URI::_blah', 'nonesuch URI URI';
is $uri->as_string, 'blah:nonesuch:', 'nonesuch URI should be correct';

# Should convert non-blah URI to a blah URI.
isa_ok $uri = URI::blah->new('foo:'), 'URI::blah', 'foo URI';
isa_ok $uri->nested_uri, 'URI::_blah', 'foo URI URI';
is $uri->as_string, 'blah:foo:', 'foo URI should be correct';

# Should pay attention to base URI.
isa_ok $uri = URI::blah->new('foo', 'nonesuch:'), 'URI::blah', 'blah URI with nonesuch base';
isa_ok $uri->nested_uri, 'URI::_blah', 'blah:nonesuch URI';
is $uri->as_string, 'blah:nonesuch:foo', 'blah URI with nonesuch: base should be correct';

# Should pay attention to blah: base URI.
isa_ok $uri = URI::blah->new('foo', 'blah:'), 'URI::blah', 'blah URI with blah base';
isa_ok $uri->nested_uri, 'URI::_blah', 'blah base URI';
is $uri->as_string, 'blah:foo', 'blah URI with blah: base should be correct';

# Should pay attention to blah:nonesuch base URI.
isa_ok $uri = URI::blah->new('foo', 'blah:nonesuch'), 'URI::blah', 'blah URI with blah:nonesuch base';
isa_ok $uri->nested_uri, 'URI::_blah', 'blah:nonesuch base URI';
is $uri->as_string, 'blah:foo', 'blah URI with blah:nonesuch base should be correct';

# Try with a blah:nonesuch base.
my $base = URI->new('blah:nonesuch');
isa_ok $uri = URI::blah->new('foo', $base), 'URI::blah', 'blah URI with obj base';
isa_ok $uri->nested_uri, 'URI::_blah', 'obj base URI';
is $uri->as_string, 'blah:foo', 'blah URI with obj base should be correct';
isa_ok $base, 'URI::blah', 'base URI';

# Try with a blah: base.
$base = URI->new('blah:');
isa_ok $uri = URI::blah->new('foo', $base), 'URI::blah', 'blah URI with blah obj base';
isa_ok $uri->nested_uri, 'URI::_blah', 'blah obj base URI';
is $uri->as_string, 'blah:foo', 'blah URI with blah obj base should be correct';
isa_ok $base, 'URI::blah', 'base URI';

# Try blah:unknown.
$base = URI->new('blah:unknown:');
isa_ok $uri = URI::blah->new('foo', $base), 'URI::blah', 'blah URI with obj base';
isa_ok $uri->nested_uri, 'URI::_blah', 'obj base URI';
is $uri->as_string, 'blah:unknown:foo', 'blah URI with obj base should be correct';
isa_ok $base, 'URI::blah', 'base URI';

# Try with some other base.
$base = URI->new('bar:');
isa_ok $uri = URI::blah->new('foo', $base), 'URI::blah', 'blah URI with obj base';
isa_ok $uri->nested_uri, 'URI::_blah', 'obj base URI';
is $uri->as_string, 'blah:bar:foo', 'blah URI with obj base should be correct';
isa_ok $base, 'URI', 'bar base URI';

# Try new_abs.
isa_ok $uri = URI::blah->new_abs('foo', 'nonesuch:'), 'URI::_foreign';
is $uri->as_string, 'nonesuch:/foo', 'Should have nonesuch: URI';
isa_ok $uri = URI::blah->new_abs('foo', 'blah:nonesuch:'), 'URI::blah';
is $uri->as_string, 'blah:nonesuch:/foo', 'Should have blah:nonesuch: URI';
isa_ok $uri = URI::blah->new_abs('foo', 'blah:'), 'URI::blah';
is $uri->as_string, 'blah:foo', 'Should have blah: URI';
isa_ok $uri = URI::blah->new_abs('foo', 'bar:'), 'URI::_generic';
isa_ok $uri = URI::blah->new_abs('foo', 'file::'), 'URI::file';
isa_ok $uri = URI::blah->new_abs('nonesuch:foo', 'nonesuch:'), 'URI::_foreign';
is $uri->as_string, 'nonesuch:foo', 'Should have nonesuch:foo URI';
isa_ok $uri = URI::blah->new_abs('blah:foo', 'blah:'), 'URI::blah';
is $uri->as_string, 'blah:foo', 'Should have blah:foo URI';
isa_ok $uri = URI::blah->new_abs('blah:nonesuch:foo', 'blah:nonesuch:'), 'URI::blah';
is $uri->as_string, 'blah:nonesuch:foo', 'Should have blah:nonesuch:foo URI';

# Test abs.
isa_ok $uri = URI->new('blah:nonesuch:'), 'URI::blah';
is overload::StrVal( $uri->abs('file:/hi') ),
   overload::StrVal($uri),
    'abs should return URI object itself';

# Test rel.
is overload::StrVal( $uri->rel('file:/hi') ),
   overload::StrVal($uri),
    'rel should return URI object itself';

# Test clone.
is $uri->clone, $uri, 'Clone should return dupe URI';
isnt overload::StrVal( $uri->clone ), overload::StrVal($uri),
    'Clone should not return self';

# Test eq.
can_ok $uri, 'eq';
ok $uri->eq($uri), 'URI should equal itself';
ok $uri->eq($uri->as_string), 'URI should equal itself stringified';
ok $uri->eq(URI->new( $uri->as_string )), 'URI should equal equiv URI';
ok $uri->eq($uri->clone), 'URI should equal itself cloned';
ok !$uri->eq('nonesuch:'), 'URI should not equal non-BLAH URI';

done_testing;
