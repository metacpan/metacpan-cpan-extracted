package Time::Checkpoint;

use 5.12.0;

use feature qw{ state };

use Time::HiRes      qw{ time };
use Params::Validate qw{ :all };

use constant IDX_CALLBACK => 0;
use constant IDX_CKPOINTS => 1;

sub new {
	my $package = shift;

	state $val = {
		callback   => {
			type     => CODEREF,
			optional => 1,
		},
	};
	validate( @_, $val );

	my $self = [ ];

	if (defined { @_ }->{callback}) {
		$self->[IDX_CALLBACK] = { @_ }->{callback};
	}

	$self->[IDX_CKPOINTS] = { };

	return bless $self, $package;
}

sub checkpoint {
	state $val = [
		{ isa  => 'Time::Checkpoint', },
		{ type => SCALAR,             },
	];
	validate_pos( @_, @$val );

	my ($self, $cp) = (@_);

	if (not defined $self->[IDX_CKPOINTS]->{$cp}) {
		my $ot = undef;
		my $nt = time;
		if ($self->[IDX_CALLBACK]) {
			$self->[IDX_CALLBACK]->( $cp, $ot, $nt );
		}
		$self->[IDX_CKPOINTS]->{$cp} = $nt;
		return 0;
	}
	elsif (defined $self->[IDX_CKPOINTS]->{$cp}) {
		my $ot = $self->[IDX_CKPOINTS]->{$cp};
		my $nt = time;
		if ($self->[IDX_CALLBACK]) {
			$self->[IDX_CALLBACK]->( $cp, $self->[IDX_CKPOINTS]->{$cp}, $nt );
		}
		$self->[IDX_CKPOINTS]->{$cp} = $nt;
		return $nt - $ot;
	}
}

sub cp { checkpoint( @_ ) }

sub list_checkpoints {
	state $val = [
		{ isa => 'Time::Checkpoint' },
	];
	validate_pos( @_, @$val );
	my ($self) = (@_);
	my $points = $self->[IDX_CKPOINTS];
	return $points;
}

sub lscp { list_checkpoints( @_ ) }

sub checkpoint_status {
	state $val = [
		{ isa  => 'Time::Checkpoint', },
		{ type => SCALAR,             },
	];
	validate_pos( @_, @$val );

	my ($self, $cp) = (@_);

	return $self->[IDX_CKPOINTS]->{$cp};
}

sub cpstat { checkpoint_status( @_ ) }

sub checkpoint_remove {
	state $val = [
		{ isa  => 'Time::Checkpoint', },
		{ type => SCALAR,             },
	];
	validate_pos( @_, @$val );

	my ($self, $cp) = (@_);

	if (defined $self->[IDX_CKPOINTS]->{$cp}) {
		return delete $self->[IDX_CKPOINTS]->{$cp};
	}
	else {
		return undef;
	}
	return undef;
}

sub cprm { checkpoint_remove( @_ ) }

sub flush {
	state $val = [
		{ isa  => 'Time::Checkpoint', },
		{ type => SCALAR,             },
	];
	validate_pos( @_, @$val );

	my ($self)= (@_);

	$self->[IDX_CKPOINTS] = { };
}

1;

=pod

=head1 NAME

Time::Checkpoint

=head1 ABSTRACT

Simple module to report deltas between waypoints in code, with extensible
reactions.

=head1 SYNOPSIS

  my $t = Time::Checkpoint->new( );
  $t->checkpoint( 'Start' );

  # Code elapses ...

  my $delta = $t->checkpoint( 'Start' );

  # With callback

  my $t = Time::Checkpoint->new(
    callback => \&print_delta
  );

  $t->checkpoint( 'foo' );

  sub print_delta {
    my ($checkpoint, $old_time, $new_time) = (@_);
    my $delta = $new_time - $old_time;
    $LOG->debug( "$checkpoint: delta $delta seconds" );
  }

  # More code elapses...

  $t->checkpoint( 'foo' ); # print_delta is called

=head1 METHODS

=over 2

=head2 Constructor

=item B<new( )>

=over 2

The constructor takes either no arguments or a hash with one key: I<callback>.
If a callback is passed (a code ref), that code will be called with the arguments
$name_of_checkpoint, $old_timestamp, $new_timestamp. Returns a Time::Checkpoint object.

=back

=item B<checkpoint( $name )>

=item B<cp( $name )>

=over 2

Takes one argument, the name of the checkpoint reached. When called, it will perform
a hash lookup to determine when it was called last. It will return the delta between
the two. It will also call the 'callback' code, as mentioned above, provided it exists.

=back

=item B<list_checkpoints( )>

=item B<lscp( )>

=over 2

Takes no arguments. Returns a hash of checkpoints and their timestamps.

=back

=item B<checkpoint_status( $name )>

=item B<cpstat( $name )>

=over 2

Returns the timestamp for a given checkpoint, or undef.

=back

=item B<checkpoint_remove( $name )>

=item B<cprm( $name )>

=over 2

Removes the specified checkpoint, returning its value if it had one.

=back

=item B<flush( )>

=over 2

Removes all checkpoints.

=back

=head1 AUTHOR

  Jane A. Avriette <jane@cpan.org>

=head1 BUGS

Yep.

=cut

# jaa // vim:tw=80:ts=2:noet
