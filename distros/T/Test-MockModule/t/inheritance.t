use warnings;
use strict;

use Test::MockModule;
use Test::More;
use Test::Warnings;

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

{
	BEGIN {
		$INC{'Mother.pm'} = '__MOCKED__';
		$INC{'InvalidChild.pm'} = '__MOCKED__';
		$INC{'ValidChild.pm'} = '__MOCKED__';
	}
	package Mother;

	sub do_something { 1 }

	package InvalidChild;

	sub abcd { 1 }

	package ValidChild;

	use parent q{Mother};

	sub abcd { 1 }
}

package main;

{
	my $mock_child = Test::MockModule->new( 'InvalidChild' );

	local $@;
	ok ! eval { $mock_child->redefine( 'do_something', sub { 42 } ); 1 }, "cannot redefine do_something";
	like $@, qr{InvalidChild::do_something does not exist!}, "throw a die";
}

{
	my $mock_child = Test::MockModule->new( 'ValidChild' );

	local $@;
	ok eval { $mock_child->redefine( 'do_something', sub { 42 } ); 1 }, "cann redefine do_something when parent define this function";
	is $@, '', 'no warnings';

	my $object = bless {}, 'ValidChild';
	is $object->do_something(), 42, "mocked value from do_something";

	$mock_child->unmock( 'do_something' );
	is $object->do_something(), 1, "do_something is now unmocked";
}


done_testing;
