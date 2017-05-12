use warnings;
use strict;

use Test::MockModule;
use Test::More;

@Bar::ISA = 'Foo';
@Baz::ISA = 'Bar';

sub Foo::motto { 'Foo!' };

is(Foo->motto(), "Foo!", "pre-mock: Foo original motto is correct");
is(Bar->motto(), "Foo!", "pre-mock: Bar inherit's Foo's motto");
is(Baz->motto(), "Foo!", "pre-mock: Baz inherit's Bar's inheritance of Foo's motto");

{
	my $mock_bar = Test::MockModule->new('Bar', no_auto => 1);
	$mock_bar->mock('motto', sub { 'Bar!' });
	is(Foo->motto(), "Foo!", "Foo motto is unchanged post-Bar mock");
	is(Bar->motto(), "Bar!", "Bar motto has been mocked");
	is(Baz->motto(), "Bar!", "Baz inherits from Bar's mocked motto");
	is($mock_bar->original("motto")->(), "Foo!", "Bar's original function can still be reached correctly");
	ok($mock_bar->is_mocked("motto"), "Baz's motto is really mocked");

	my $mock_baz = Test::MockModule->new('Baz', no_auto => 1);
	$mock_baz->mock('motto', sub { 'Baz!' });
	is(Foo->motto(), "Foo!", "Foo motto is unchanged post-Baz mock");
	is(Bar->motto(), "Bar!", "Bar motto is unchanged post-Baz mock");
	is(Baz->motto(), "Baz!", "Baz motto has been mocked");

	is($mock_baz->original("motto")->(), "Bar!", "Baz's original function is Bar's mocked function");
	ok($mock_baz->is_mocked("motto"), "Baz's motto is really mocked");

	$mock_bar->unmock("motto");
	is(Bar->motto, "Foo!", "Bar's motto is unmocked");
	is($mock_baz->original("motto")->(), "Foo!", "Baz's original function is now magically inherited up to Foo");
}

is(Foo->motto(), "Foo!", "post-unmock: Foo original motto is correct");
is(Bar->motto(), "Foo!", "post-unmock: Bar inherit's Foo's motto");
is(Baz->motto(), "Foo!", "post-unmock: Baz inherit's Bar's inheritance of Foo's motto");
done_testing;
