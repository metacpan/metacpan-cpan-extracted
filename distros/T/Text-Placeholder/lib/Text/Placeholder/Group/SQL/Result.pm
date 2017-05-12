package Text::Placeholder::Group::SQL::Result;

use strict;
use warnings;
use Carp qw();
use Data::Dumper;
use parent qw(
	Object::By::Array);

sub THIS() { 0 }

sub ATR_PLACEHOLDER_RE() { 0 }
sub ATR_FIELDS() { 1 }
sub ATR_SUBJECT() { 2 }

sub _init {
	my ($this) = @_;

	$this->[ATR_PLACEHOLDER_RE] = undef;
	$this->[ATR_FIELDS] = [];
	$this->[ATR_SUBJECT] = [];
	return;
}

sub P_PLACEHOLDER_RE() { 1 }
sub placeholder_re {
	if(exists($_[P_PLACEHOLDER_RE])) {
		my $placeholder_re = $_[P_PLACEHOLDER_RE];
		if(ref($placeholder_re) eq '') {
			$placeholder_re = eval "sub {
				return((\$_[0] =~ m,$placeholder_re,s) ? \$1 : undef)  };";
		}
		$_[THIS][ATR_PLACEHOLDER_RE] = $placeholder_re;
		return;
	} else {
		return($_[THIS][ATR_PLACEHOLDER_RE]);
	}

}

my $questionmark = sub { return('?') };

sub P_PLACEHOLDER() { 1 }
sub lookup {
	my $placeholder = $_[THIS][ATR_PLACEHOLDER_RE]->($_[P_PLACEHOLDER]);
	return(undef) unless(defined($placeholder));
	push(@{$_[THIS][ATR_FIELDS]}, $placeholder);

	my $position = $#{$_[THIS][ATR_FIELDS]};
	my $formatter = eval "sub { return(\$_[THIS][ATR_SUBJECT][$position]) };";
	Carp::confess($@) if ($@);

	return([$formatter, $_[THIS]]);
}

sub fields {
	return($_[THIS][ATR_FIELDS]);
}

sub P_ROW() { 1 }
sub subject {
	if(exists($_[P_ROW])) {
		$_[THIS][ATR_SUBJECT] = $_[P_ROW];
		return;
	} else {
		return($_[THIS][ATR_SUBJECT]);
	}

}

1;
