package Tie::Hash::Expire;

use strict;

use POSIX qw/ceil/;
use Carp;

use vars qw($VERSION $HI_RES_AVAILABLE);

$VERSION = '0.03';

BEGIN {
	eval "use Time::HiRes qw/time/";
	unless($@){
		$HI_RES_AVAILABLE = 1;
	}
}

$Tie::Hash::Expire::clean_int = 180; # Maybe later, the user can set this.

sub TIEHASH {
	my $class = shift;
	my $args = shift || {};

	# TODO: What do we do without $args->{expire_seconds}
	unless(exists $args->{expire_seconds}){
		carp "hash tied to Tie::Hash::Expire without specifying expire_seconds.  Hash keys will not expire.";
	}
	if(!$HI_RES_AVAILABLE and $args->{expire_seconds} =~ /\.\d+/){
		carp "expire_seconds appears to be a decimal number, but Time::HiRes is not available.";
	}

	my $self = {
		'last_clean'	=>	time,
		'clean_int'	=>	$Tie::Hash::Expire::clean_int,
		'hash'		=>	{},
		'array'		=>	[],
		'lifespan'	=>	$args->{expire_seconds},
	};
	bless $self, $class;
	return $self;
}

sub STORE {

	my $self = shift;
	my $key = shift;
	my $value = shift;

	my $time = time;

	$self->maybe_clean();

	$self->DELETE($key);

	# Insert it on the end.
	push @{$self->{array}}, [$time,$key,$value];
	$self->{hash}->{$key} = $#{$self->{array}};

}

sub FETCH {

	my $self = shift;
	my $key = shift;

	$self->maybe_clean();

	if(exists $self->{hash}->{$key}){
		# It exists, but may be expired.
		my $time = time;

		my $index = $self->{hash}->{$key};
		if((defined $self->{lifespan}) and $time - $self->{array}->[$index]->[0] >= $self->{lifespan}){
			# It is expired.
			$self->chop_hash($index);
			return undef;
		}
		# It is not expired.
		return $self->{array}->[$index]->[2];
	} else {
		return undef;
	}
}

sub EXISTS {

	my $self = shift;
	my $key = shift;

	$self->maybe_clean();

	if(exists $self->{hash}->{$key}){
		# It exists, but may be expired.
		my $time = time;

		my $index = $self->{hash}->{$key};
		if(defined $self->{lifespan} and $time - $self->{array}->[$index]->[0] >= $self->{lifespan}){
			# It is expired.
			$self->chop_hash($index);
		}
	}

	return exists $self->{hash}->{$key};

}

sub DELETE {

	my $self = shift;
	my $key = shift;

	$self->maybe_clean();

	if(exists($self->{hash}->{$key})){
		splice @{$self->{array}}, $self->{hash}->{$key},1;
		$self->rebuild_hash();
	}
}

sub CLEAR {

	my $self = shift;

	$self->{hash} = {};
	$self->{array} = [];
	$self->{last_clean} = time;

}

sub FIRSTKEY {

	my $self = shift;
	$self->clean_house();

	if(scalar @{$self->{array}}){
		my $key = $self->{array}->[0]->[1];
		$self->{curr_key} = 0;
		return $key;
	} else {
		return undef;
	}
}

sub NEXTKEY {

	my $self = shift;

	my $chopped = $self->clean_house();

	# First, update $self->{curr_key}
	$self->{curr_key}++;

	if(defined $chopped){	# The hash has changed while iterating.
		if($self->{curr_key} <= $chopped){	# Start over
			$self->{curr_key} = 0;
		} else {				# Adjust number
			$self->{curr_key} = ($self->{curr_key}-$chopped)-1;
		}
	}

	# Return the right thing:
	if($self->{curr_key} <= $#{$self->{array}}){
		return $self->{array}->[$self->{curr_key}]->[1];
	} else {
		return undef;
	}
}

sub clean_house {

	my $self = shift;

	# Locate the first expired datum and chop there.
	# Return the index of the first chopped key, or undef if no chop
	# occurred.

	unless(defined $self->{lifespan}){
		return undef;
	}

	my $max = $#{$self->{array}};
	my $min = -1;
	my $time = time;
 	$self->{last_clean} = $time;

	while($max > $min){
		my $try = ceil(($max+$min)/2);
		if($time - $self->{array}->[$try]->[0] >= $self->{lifespan}){
			$min = $try;
		} else {
			$max = $try-1;
		}
	}
	if($min>=0){
		$self->chop_hash($min);
		return $min;
	} else {
		return undef;
	}

}

sub maybe_clean {

	my $self = shift;

	my $time = time;
	if($time - $self->{last_clean} >= $self->{clean_int}){
		$self->clean_house();
	}
}

sub chop_hash {

	my $self = shift;
	my ($index) = @_;

	# Eliminate all entries from the array at $index and before.

	if($index >= $#{$self->{array}}){
		@{$self->{array}} = ();
	} else {
		@{$self->{array}} = @{$self->{array}}[($index+1) .. $#{$self->{array}}];
	}

	$self->rebuild_hash();
}

sub rebuild_hash {

	my $self = shift;

	$self->{hash} = {
		map {$self->{array}->[$_]->[1], $_} (0..$#{$self->{array}})
	};
}
1;

__END__

=head1 NAME

Tie::Hash::Expire - Hashes with keys that expire after a user-set period.

=head1 SYNOPSIS

  use Tie::Hash::Expire;

  my %test;
  tie %test, 'Tie::Hash::Expire', {'expire_seconds' => 10};

  $test{'dog'} = 'doghouse';
  sleep 5;
  $test{'bird'} = 'nest';
  sleep 6;

  print keys %test, "\n";	# The only key is 'bird'

  my %hi_res;
  tie %hi_res, 'Tie::Hash::Expire', {'expire_seconds' => 5.21};
	# Decimal number of seconds works if you have Time::HiRes

=head1 ABSTRACT

Hashes tied to Tie::Hash::Expire have keys that cease to exist 'expire_seconds' after their most recent modification or their creation.

=head1 DESCRIPTION

Hashes tied to Tie::Hash::Expire behave like normal hashes in all respects except that when a key is added or the value associated with a key is changed, the current time is stored, and after 'expire_seconds' the key and value are removed from the hash.

Resolutions finer than seconds are available if the module finds access to Time::HiRes.  If Time::HiRes is available, you can expect expiration to be accurate to 0.001 seconds.  You may specify 'expire_seconds' to be decimal numbers like 5.12 .  If Time::HiRes is available, this number will be used precisely.  If you specify a decimal number and don't have access to Time::HiRes, a warning is generated and the code will function as though you specified the next higher integer.

The number of seconds specified by 'expire_seconds' is taken to mean an absolute maximum lifespan for the key, at the resolution described above.  In other words, if you set 'expire_seconds' to 1 second, and do not have Time::HiRes, keys could expire as quickly as the next machine instruction, but will not last longer than 1 second.

=head1 AUTHOR

Jeff Yoak, E<lt>jeff@yoak.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeff Yoak

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
