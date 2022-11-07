use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Spy;

sub check_if_imitates
{
	my ($obj, $pkg) = @_;

	isa_ok $obj, $pkg;
	ok $obj->does($pkg), "does $pkg ok";
	ok $obj->DOES($pkg), "DOES $pkg ok";
}

subtest 'testing imitating (string)' => sub {
	my $spy = Test::Spy->new(imitates => 'Some::Package');

	my $obj = $spy->object;

	check_if_imitates($obj, 'Some::Package');
};

subtest 'testing imitating (array)' => sub {
	my @packages = ('TestPackage1', 'TestPackage2');
	my $spy = Test::Spy->new;
	$spy->set_imitates([@packages]);

	my $obj = $spy->object;

	foreach my $pkg (@packages) {
		check_if_imitates($obj, $pkg);
	}
};

done_testing;

