#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
	use_ok('Validate::Yubikey');
}

can_ok('Validate::Yubikey', ('new'));

my $did_update = 0;
my $did_log = 0;

my $y = Validate::Yubikey->new(
	callback => sub {
		is(shift, 'nednerfbfclb', 'pid matches');
		return {
			iid => '935f19d93120',
			key => '751d7ee66131350cfffb4fb6c05df1af',
			count => 0,
			use => 0,
			lastuse => 0,
			lastts => 0,
		};
	},
	update_callback => sub {
		$did_update++;
	},
	log_callback => sub {
		note(shift);
		$did_log++;
	},
);

isa_ok($y, 'Validate::Yubikey');

can_ok($y, ('validate'));

my $success = $y->validate('nednerfbfclbfjilhkuijcungegkchdbtkfgrfhkluec');

isnt($success, 0, 'validation successful');
isnt($did_update, 0, 'update callback called');
isnt($did_log, 0, 'logging callback called');

1;
