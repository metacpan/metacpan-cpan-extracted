#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 27;

use Tie::Scalar::MarginOfError;

{
	tie my $val, 'Tie::Scalar::MarginOfError', { tolerance => 0.1, initial_value => 1 };
	eval { $val = 1.01 };
	ok !$@, "inside margin of error (bigger than original)";
	is $val, 1.01, "Value set correctly";
	eval { $val = 2 };
	like $@, qr/outside/, "opps, outside margin of error";
}

{
	tie my $val, 'Tie::Scalar::MarginOfError', { tolerance => 0.1, initial_value => 1 };
	eval { $val = 0.99 };
	ok !$@, "inside margin of error (less than original)";
	is $val, 0.99, "Value set correctly";
	eval { $val = 0 };
	like $@, qr/outside/, "opps, outside margin of error";
}

{
	tie my $val, 'Tie::Scalar::MarginOfError', { tolerance => 0.1, initial_value => 1 };
	for (my $i = 1; $i < 1.1; $i += 0.025) {
		eval { $val = $i };
		ok ! $@, "$i inside margin of error (value getting bigger)";
		is $val, $i, "value set to $i";
	} 
}

{
	tie my $val, 'Tie::Scalar::MarginOfError', { tolerance => 0.1, initial_value => 1 };
	for (my $i = 1; $i > 0.9; $i -= 0.025) {
		eval { $val = $i };
		ok ! $@, "$i inside margin of error (value getting smaller)";
		is $val, $i, "value set to $i";
	} 
}

# An example of a callback. Totally contrived. What is does is reset to
# the initial value if the margin of error is exceeded. Yes, to make it
# work properly I had to rebless it back in. Ugh.

{
	tie my $val, 'Tie::Scalar::MarginOfError', 
		{ 
			tolerance => 0.1, 
			initial_value => 1, 
			callback => sub { 
				my $self = shift;
				warn sprintf "RESETTING TO %s", $$self->{initial_value}; 
				$$self->{value} = $$self->{initial_value};
				$self = $$self->{initial_value};
				return bless { tolerance => $$self->{tolerance}, initial_value => $$self->{initial_value} }, ref $self;
			} 
		};
	eval { $val = 0.99 };
	ok !$@, "inside margin of error (using callback)";
	is $val, 0.99, "Value set correctly";
	eval { $val = 0 };
	is $val, 1, 
		"reset to original value via a callback when outside the margin of error";
}
