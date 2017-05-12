#!perl -T
use strict;
use warnings;

use Test::More;
use Test::Proto ':all'; # i.e. p pArray pHash pCode pObject pSeries pRepeatable pAlternation c cNumeric

isa_ok(p, 'Test::Proto::Base');

isa_ok(pArray, 'Test::Proto::ArrayRef');
isa_ok(pHash, 'Test::Proto::HashRef');
isa_ok(pObject, 'Test::Proto::Object');
isa_ok(pCode, 'Test::Proto::CodeRef');

isa_ok(pSeries, 'Test::Proto::Series');
isa_ok(pRepeatable, 'Test::Proto::Repeatable');
isa_ok(pAlternation, 'Test::Proto::Alternation');

isa_ok(p(1), 'Test::Proto::Base');
ok(p(1)->validate(1));
ok(!(p(1)->validate(2)));

isa_ok(p([]), 'Test::Proto::ArrayRef');
isa_ok(pArray([]), 'Test::Proto::ArrayRef');
isa_ok(p({}), 'Test::Proto::HashRef');
isa_ok(pHash({}), 'Test::Proto::HashRef');

isa_ok(c, 'Test::Proto::Compare');
isa_ok(cNumeric, 'Test::Proto::Compare::Numeric');

{
	package Test::Proto::Acme::ArrayRefObject;
	sub new {
		bless ['foo'], shift;
	}
	1;
}
{
	package Test::Proto::Acme::HashRefObject;
	sub new {
		bless {foo=>'bar'}, shift;
	}
	1;
}
package main;

my $aro = Test::Proto::Acme::ArrayRefObject->new;
my $hro = Test::Proto::Acme::HashRefObject->new;

isa_ok(pObject([]), 'Test::Proto::Object');
isa_ok(pObject({}), 'Test::Proto::Object');
isa_ok(pObject('IO::Handle'), 'Test::Proto::Object');
ok(pObject($aro)->validate($aro), 'refaddr comparison works');
ok(pObject(['foo'])->validate($aro), 'pObject([\'foo\']) works');
ok(! ( pObject(['foo'])->validate(['foo'] ) ), 'pObject([\'foo\']) fails correctly');
ok(pObject({foo=>'bar'})->validate($hro), 'pObject({foo=>\'bar\'}) works');
ok(! ( pObject({foo=>'bar'})->validate({foo=>'bar'} ) ), 'pObject({foo=>\'bar\'}) fails correctly');
use Data::Dumper; 
ok(pObject('Test::Proto::Acme::ArrayRefObject')->validate($aro), 'pObject($class) passes');


done_testing();

