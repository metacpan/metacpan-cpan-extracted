package Text::Placeholder::Group::_;

use strict;
use warnings;

sub THIS() { 0 }
sub ATR_PLACEHOLDERS() { 0 }

sub P_PLACEHOLDER() { 1 }
sub lookup {
	return(exists($_[THIS][ATR_PLACEHOLDERS]{$_[P_PLACEHOLDER]})
		? [$_[THIS][ATR_PLACEHOLDERS]{$_[P_PLACEHOLDER]}, $_[THIS]]
		: undef);
}

sub P_FORMATTER() { 2 }
sub add_placeholder {
	$_[THIS][ATR_PLACEHOLDERS]{$_[P_PLACEHOLDER]} = $_[P_FORMATTER];
}

1;
