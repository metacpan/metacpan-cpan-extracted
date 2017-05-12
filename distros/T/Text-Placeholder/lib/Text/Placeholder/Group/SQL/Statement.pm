package Text::Placeholder::Group::SQL::Statement;

use strict;
use warnings;
#use Carp qw();
#use Data::Dumper;
use parent qw(
	Object::By::Array);

sub THIS() { 0 }

sub ATR_PLACEHOLDER_RE() { 0 }
sub ATR_FIELDS() { 1 }

sub _init {
	my ($this) = @_;

	$this->[ATR_PLACEHOLDER_RE] = undef;
	$this->[ATR_FIELDS] = [];
	return;
}

sub P_PLACEHOLDER_RE() { 1 }
sub placeholder_re {
	if(exists($_[P_PLACEHOLDER_RE])) {
		my $placeholder_re = $_[P_PLACEHOLDER_RE];
		if(ref($placeholder_re) eq '') {
			$placeholder_re = eval "sub {
				\$_[0] =~ m,$placeholder_re,s;  };";
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
	return(undef) unless($_[THIS][ATR_PLACEHOLDER_RE]->($_[P_PLACEHOLDER]));
	push(@{$_[THIS][ATR_FIELDS]}, $_[P_PLACEHOLDER]);
	return([$questionmark, undef]);
}

sub fields {
	return($_[THIS][ATR_FIELDS]);
}

1;
