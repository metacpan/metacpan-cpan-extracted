package Text::Placeholder::Group::Counter;

use strict;
use warnings;
#use Carp qw();
#use Data::Dumper;
use parent qw(
	Text::Placeholder::Group::_
	Object::By::Array);

sub THIS() { 0 }

sub ATR_PLACEHOLDERS() { 0 }
sub ATR_COUNTER() { 1 }

my $PLACEHOLDERS = {
	'counter' => sub { return($_[THIS][ATR_COUNTER]++)},
	'counter_alphabetically' => sub {
		return(chr(95+$_[THIS][ATR_COUNTER]++))},
	'counter_ALPHABETICALLY' => sub {
		return(chr(63+$_[THIS][ATR_COUNTER]++))},
};

sub _init {
	my ($this) = @_;

	$this->[ATR_PLACEHOLDERS] = $PLACEHOLDERS;
	$this->[ATR_COUNTER] = 1;

	return;
}

sub reset {
	$_[THIS][ATR_COUNTER] = 1;
	return;
}

1;
