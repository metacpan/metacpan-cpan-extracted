use strict;
use Test::More tests => 2;
use Trigger;

ok( my $obj = Trigger->new(
		heap		=> {}, 
		init		=> sub {
			my $heap = shift;
		},
		process		=>	sub {
			my $heap = shift;
			my @args = @_;
		},
		trigger_and_action => [
			sub { # trigger
				my $heap = shift;
				my @args = @_;
			} => sub { # action
				my $heap = shift;
				my @args = @_;
			},
			sub { # trigger
			} => sub { # action
			},
		],
		end		=>	sub {
			my $heap = shift;
		},
	)
);

is(ref $obj , 'Trigger' );

