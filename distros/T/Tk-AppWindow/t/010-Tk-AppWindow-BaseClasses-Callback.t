
use strict;
use warnings;

use Test::More tests => 57;
BEGIN { use_ok('Tk::AppWindow::BaseClasses::Callback') };

{
	package Blobber;
	
	use strict;
	
	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {
 			VAL => 0
		};
		bless ($self, $class);
	}
	
	sub Get {
		return $_[0]->{VAL}
	}
	
	sub Plus {
		my ($self, $par) = @_;
		$self->Put($self->Get + $par);
		return $self->Get
	}

	sub Put {
		my ($self, $val) = @_;
		$self->{VAL} = $val;
	}
	
	sub Reset {
		$_[0]->{VAL} = 0;
	}
	1;
}


my $blob = Blobber->new;

my $value = 0;

sub AddValue {
	my $add = shift;
	$value = $value + $add;
	return $value
}

sub Clear {
	my $key = shift;
	if ($key eq 'OO') {
		$blob->Reset
	} else {
		$value = 0;
	}
}

my %callbacks = (
	OO => ['Plus', $blob],
	AN => [\&AddValue],
);

for (sort keys %callbacks) {
	my $call = $_;
	&Clear($call);
	my $opt = $callbacks{$call};
	my $callback = Tk::AppWindow::BaseClasses::Callback->new(@$opt);
	ok(defined $callback, "$call can create");

	ok(($callback->execute(0) eq "0"), "$call execute");

	my $ub = $callback->{HOOKSBEFORE};
	my $vb = @$ub;
	ok(($vb eq 0), "$call $vb hooks before, expected 0");

	my $ua = $callback->{HOOKSAFTER};
	my $va = @$ua;
	ok(($va eq 0), "$call $va hooks after, expected 0");

	#adding before hooks
	my @resultsb = (2, 10, 32);
	for (1 .. 3) {
		$callback->hookBefore(@$opt, $_);
		my $ub = $callback->{HOOKSBEFORE};
		my $got = @$ub;
		ok(($got eq $_), "$call got $got hooks before, expected $_");
		my $val = $callback->execute(1);
		my $expected = $resultsb[$_ - 1];
		ok (($val eq $expected), "$call Execute got $val, expected $expected");
	}

	&Clear($call);

	#adding after hooks
	my @resultsa = (16, 53, 133);
	for (1 .. 3) {
		$callback->hookAfter(@$opt, $_ + 3);
		my $ua = $callback->{HOOKSAFTER};
		ok((@$ua eq $_), "$call $_ hooks after");
		my $val = $callback->execute(1);
		my $expected = $resultsa[$_ - 1];
		ok (($val eq $expected), "$call Execute got $val, expected $expected");
	}

	&Clear($call);

	#removing before hooks
	my @xresultsb = (25, 71, 87);
	my $count = 3;
	for (1 .. 3) {
		$callback->unhookBefore(@$opt, $_);
		my $ub = $callback->{HOOKSBEFORE};
		my $expected = $count - 1;
		my $got = @$ub;
		ok(($expected eq $got), "$call got $got, expected $expected hooks UnHookBefore");
		my $val = $callback->execute(1);
		$expected = $xresultsb[$_ - 1];
		ok (($val eq $expected), "$call Execute got $val, expected $expected");
		$count --;
	}

	&Clear($call);

	#removing after hooks
	my @xresultsa = (12, 19, 20);
	$count = 3;
	for (1 .. 3) {
		$callback->unhookAfter(@$opt, $_ + 3);
		my $ua = $callback->{HOOKSAFTER};
		my $expected = $count - 1;
		my $got = @$ua;
		ok(($expected eq $got), "$call got $got, expected $expected hooks UnHookAfter");
		my $val = $callback->execute(1);
		$expected = $xresultsa[$_ - 1];
		ok (($val eq $expected), "$call Execute got $val, expected $expected");
		$count --;
	}
}
