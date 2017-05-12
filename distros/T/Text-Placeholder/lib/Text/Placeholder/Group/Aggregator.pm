package Text::Placeholder::Group::Aggregator;

use strict;
use warnings;
use parent qw(
	Object::By::Array);

sub THIS() { 0 }

sub ATR_GROUPS() { 0 }

sub _init {
	my ($this) = @_;

	$this->[ATR_GROUPS] = [];

	return;
}

sub add_group {
	my $this = shift;

	foreach my $group (@_) {
		if(ref($group) eq '') {
			unless($group =~ m,^((|::)(\w+))+$,) {
				Carp::confess("Invalid package name '$group'.");
			}
			if(substr($group, 0, 2) eq '::') {
				$group = 'Text::Placeholder::Group'."$group";
			}
			eval "use $group;";
			Carp::confess($@) if ($@);
			$group = $group->new;
		}
		push(@{$this->[ATR_GROUPS]}, $group);
	}
	return;
}

sub subject {
	my $this = shift;

	foreach my $group (@{$this->[ATR_GROUPS]}) {
		$group->subject(@_);
	}
	return;
}

sub lookup {
	my $this = shift;

	foreach my $group (@{$this->[ATR_GROUPS]}) {
		my $collector = $group->lookup(@_);
		return($collector) if(defined($collector));
	}
	return;
}

1;
