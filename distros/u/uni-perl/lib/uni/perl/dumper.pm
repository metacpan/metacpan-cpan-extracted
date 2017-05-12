package uni::perl::dumper;

use uni::perl;
m{
use strict;
use warnings;
}x;

sub dumper_uni(@) {
	eval {
		require uni::dumper;
	1} or do {
		goto &dumper_dd;
	};
	no strict 'refs';
	*{ caller().'::dumper' } = \&uni::dumper::dumper;
	goto &{ caller().'::dumper' };
}

sub dumper_dd (@) {
	require Data::Dumper;
	no strict 'refs';
	*{ caller().'::dumper' } = sub (@) {
		my $s = Data::Dumper->new([@_])
			#->Maxdepth(3)
			->Freezer('DUMPER_freeze')
			->Terse(1)
			->Indent(1)
			->Purity(0)
			->Useqq(1)
			->Quotekeys(0)
			->Dump;
		$s =~ s/\\x\{([a-f0-9]{1,4})\}/chr hex $1/sge;
		$s;
	};
	goto &{ caller().'::dumper' };
}

sub import {
	my $me = shift;
	my $caller = shift || caller;
	$me->load($caller);
	@_ = ('uni::perl');
	goto &uni::perl::import;
}

sub load {
	my $me = shift;
	my $caller = shift;
	no strict 'refs';
	*{ $caller .'::dumper' } = \&dumper_uni;
	return;
}

1;
