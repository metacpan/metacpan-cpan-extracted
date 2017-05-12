#!perl

use Test::More tests => 7;
use Test::Exception;
use Test::Deep;

use WWW::Session storage => [ File => { path => "."} ], serialization => 'JSON', autosave => 0;

{
	my %session;
	
	tie %session, WWW::Session, 'tie_session', { a => 1, b => 2 };
	
	is($session{a},1,'Value for a set ok');
	is($session{b},2,'Value for b set ok');
	
	cmp_bag([keys %session],['a','b'],"Session keys as expected");
	
	is(delete $session{b},2,"Delete works");
	
	cmp_bag([keys %session],['a'],"Session keys as expected after deleting b");
	
	$session{c} = 3;
	
	is($session{c},3,'Value for c set ok');
	
	cmp_bag([keys %session],['a','c'],"Session keys as expected after adding c");
}