use strict; use warnings;

use Test::More tests => 24;
use URI ();
use URI::WithBase ();
use URI::Signature::Tiny ();

sub _notary { URI::Signature::Tiny->new( secret => 'hmac_placeholder', @_ ) }

isa_ok _notary, 'URI::Signature::Tiny', 'Constructor return value';

is _notary->signature( 'http://foo?zip=yes;a=param&bar=baz#pagetop' ), '0hailVTktajSl1lTB2pDTSWUhhSETCunSa5deGpPyEo',
	'The defaults seem to work';

is _notary->signature( '?foo=1;bar=1' ), _notary->signature( '?bar=1;foo=1' ),
	'Canonicalization works';

is _notary->signature( '?foo=1&bar=1' ), _notary->signature( '?bar=1;foo=1' ),
	'... including normalizing query parameter separators';

is _notary( sort_params => 0 )->signature( '?bar=1&foo=1' ), _notary->signature( '?bar=1;foo=1' ),
	'... even when not normalizing query parameter order';

is _notary( function => sub { "@_" } )->signature( 'womp womp' ), 'womp womp hmac_placeholder',
	'Passing a different function works';

is _notary( function => sub { '==/+/==' } )->signature( '!' ), '==_-_',
	'... and recodes base64 to base64url';

is _notary( function => sub { '==/+/==' }, recode_base64 => 0 )->signature( '!' ), '==/+/==',
	'... but that can be turned off';

is _notary->signature( URI->new_abs( '../quux', 'http://foo/bar/baz' ) ), _notary->signature( 'http://foo/quux' ),
	'URI objects are correctly supported';

is _notary->signature( URI::WithBase->new( '../quux', 'http://foo/bar/baz' ) ), _notary->signature( 'http://foo/quux' ),
	'URI::WithBase objects are correctly supported';

is _notary->signature( URI::WithBase->new( 'http://possum', 'http://foo/bar' ) ), _notary->signature( 'http://possum' ),
	'... in various constellations';

my ( $uri, $sig ) = qw( foo -vfYMW4SFqrGUg38qZgYu5XkpiDqY79gl1QqqxbgwUw );

is _notary( after_sign => sub { join '!', @_ } )->sign( 'foo' ), "$uri!$sig",
	'Signing works';

ok _notary( before_verify => sub { split '!', shift, 2 } )->verify( "$uri!$sig" ),
	'Verifying works';

ok ! _notary( before_verify => sub { ( shift, undef ) }, function => sub { undef } )->verify( $uri ),
	'... and does not consider undef a valid signature';

my ( $ret, $fn, $ln, $e );
my $zefram = eval { Carp->VERSION('1.25') } ? '.' : '';

$e = do { local $@; eval { ( undef, $fn, $ln ) = caller; $ret = URI::Signature::Tiny->new }; $@ };
is $ret, undef, 'Constructing an instance without a secret throws an exception';
is $e, "Missing secret for URI::Signature::Tiny at $fn line $ln$zefram\n",
	'... with the expected message';

$e = do { local $@; eval { ( undef, $fn, $ln ) = caller; $ret = _notary->signature( undef ) }; $@ };
is $ret, undef, 'Passing undef to the signature method throws an exception';
is $e, "Cannot compute the signature of an undefined value at $fn line $ln$zefram\n",
	'... with the expected message';

$e = do { local $@; eval { ( undef, $fn, $ln ) = caller; $ret = _notary->signature }; $@ };
is $ret, undef, '... and so does passing nothing';
is $e, "Cannot compute the signature of an undefined value at $fn line $ln$zefram\n",
	'... also with the expected message';

$e = do { local $@; eval { ( undef, $fn, $ln ) = caller; $ret = _notary->sign( 1 ) }; $@ };
is $ret, undef, 'Signing without a after_sign throws an exception';
is $e, "No after_sign callback specified at $fn line $ln$zefram\n",
	'... with the expected message';

$e = do { local $@; eval { ( undef, $fn, $ln ) = caller; $ret = _notary->verify( 1 ) }; $@ };
is $ret, undef, 'Signing without a before_verify throws an exception';
is $e, "No before_verify callback specified at $fn line $ln$zefram\n",
	'... with the expected message';
