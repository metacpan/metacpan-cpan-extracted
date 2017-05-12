
package Thread::Shared;

use threads::shared '1.02', qw/ share is_shared /;

use Thread::Shared::Hash;
use Thread::Shared::Array;
use strict;

use Data::Dumper;

# returns true if this is one of our tied objects.
sub one_of_us
{
	my $value = shift;
	
	if ( defined $value and ref($value) )
	{
		if ( ref($value) eq 'ARRAY' )
		{
			my $tied = tied @$value;
			if ( ref($tied) eq 'Thread::Shared::Array' )
			{
				return $tied;
			}
		}
		else
		{
			my $tied = tied %$value;
			if ( ref($tied) eq 'Thread::Shared::Hash' )
			{
				return $tied;
			}
		}
	}

	return undef;
}

# returns if this is shared, one of our tied objects, or an rvalue.
sub sharable
{
	my $value = shift;

	if ( ref($value) )
	{
		if ( is_shared $value or one_of_us $value )
		{
			return 1;
		}
	}
	else
	{
		return 1;
	}

	return 0;
}

# takes an already shared hash or array and wraps it in our tied objects.
sub wrap
{
	my $value = shift;

	if ( one_of_us $value )
	{
		return $value;
	}

	if ( not ref($value) )
	{
		die "Cannot wrap a non-reference.";
	}

	if ( not is_shared $value )
	{
		die "Cannot wrap a non-shared value.";
	}

	if ( ref($value) eq 'ARRAY' )
	{
		tie my @array, 'Thread::Shared::Array', $value;
		return \@array;
	}
	else
	{
		tie my %hash, 'Thread::Shared::Hash', $value, ref($value);
		my $ref = \%hash;
		if ( ref($value) ne 'HASH' )
		{
			bless $ref, ref($value);
		}
		return $ref;
	}
}

# returns the shared data from a tied reference
sub unwrap
{
	my $value = shift;

	if ( is_shared $value )
	{
		return $value;
	}

	my $tied = one_of_us $value;
	if ( $tied )
	{
		return $tied->get_shared_value;
	}

	return undef;
}

# returns a value that is capable to be put into a shared array or hash.
sub make_sharable
{
	my $value = shift;

	if ( is_shared $value )
	{
		return $value;
	}
	
	if ( ref($value) )
	{
		my $tied = one_of_us($value);

		if ( defined $tied )
		{
			return $tied->get_shared_value();
		}
		elsif ( ref($value) eq 'SCALAR' )
		{
			return share($$value);
		}
		elsif ( ref($value) eq 'ARRAY' )
		{
			my $array = &share([]);
			foreach my $value ( @$value )
			{
				push @$array, make_sharable($value);
			}
			return $array;
		}
		else
		{
			my $hash = &share({});
			while( my ($key, $value) = each %$value )
			{
				$hash->{$key} = make_sharable($value);
			}
			if ( ref($value) ne 'HASH' )
			{
				bless $hash, ref($value);
			}
			return $hash;
		}
	}

	return $value;
}

# takes a normal value and returns a "shared" version, either standard or enhanced
# by our tied objects.
sub convert
{
	my $value = shift;

	if ( ref($value) )
	{
		if ( one_of_us($value) )
		{
			return $value;
		}
		elsif ( ref($value) eq 'SCALAR' )
		{
			return share($$value);
		}
		elsif ( ref($value) eq 'ARRAY' )
		{
			# create a new tied array
			tie my @hash, 'Thread::Shared::Array';
			foreach my $item ( @$value )
			{
				push @hash, $item;
			}
			return \@hash;
		}
		else
		{
			my $bless = ref($value);

			# create a new tied object
			tie my %hash, 'Thread::Shared::Hash', undef, $bless;

			# copy values
			while ( my ($key, $item) = each %$value )
			{
				$hash{$key} = $item;
			}

			# make reference, bless if necessary, and return.
			my $ref = \%hash;
			if ( $bless and $bless ne 'HASH' )
			{
				bless $ref, $bless;
			}
			return \%hash;
		}
	}

	return share($value);
}

1;

__END__

=pod

=head1 NAME

Thread::Shared -- Utilities to help manage thread shared memory.

=head1 SYNOPSIS

  use threads;
  use threads::shared;

  use Thread::Shared;
  use MyCustomClass;

  # Attempt to move an instance of a custom class into shared memory.
  my $obj = Thread::Shared::convert( MyCustomClass->new() );

  # Continue to call functions normally, now operating in shared memory!
  $obj->callMyMethod();

  # Get the actual shared hash out, which is necessary in order to pass it 
  # to another thread.
  my $hash = Thread::Shared::unwrap( $obj );

  # 
  # Lower-level utility functions:
  #

  # Recursively copy a hash or list into shared memory.
  my $hash = Thread::Shared::make_sharable({ 
  	value1 => 1,
	value2 => 2
  });
  my $array = Thread::Shared::make_sharable([
  	'value1',
	'value2'
  ]);

  # Wrap an shared array or hash in a tie()'d version which automatically
  # converts new members into sharable versions.
  my $magic = Thread::Shared::wrap( $hash );
  $magic->{value3} = { value4 => 4 };

  # Get the shared value back out.
  my $shared = Thread::Shared::unwrap( $magic );

  # Create an empty tie()'d hash.
  my $magic = Thread::Shared::convert({});

  # Determine whether a variable is sharable or one of our magic values.
  print "sharable"   if Thread::Shared::sharable($shared);
  print "ONE OF US!" if Thread::Shared::one_of_us($magic);

=head1 DESCRIPTION

Perl has a unique threading model, in that each thread gets a copy of all the data that
was in the spawning interpretter --- it doesn't share memory with the other thread by default.
This is more like using fork() than threading as used under most programming enironments.
In fact, shared memory is really the only reason to use threads in environments where 
fork()'ing isn't a prohibitively expensive operation.

Perl does allow you to share memory between threads using the threads::shared module, 
however its use is far from convenient.  threads::shared works by creating a seperate
interpretter that all the threads have access to, and tie()'ing local thread variables
to access this interpretter.

For example:

  use threads;
  use threads::shared;

  # create a shared hash
  my $data = &shared({});

  # add some data to it
  $data->{value1} = 1;
  $data->{value2} = 2;

This is all fun and happy, but you can only add references a shared data structure that is
also shared.  So:

  my $data = &shared({});

  # Won't work!  Kills the thread!
  $data->{value3} = { value4 => 4 };

  # You have to do this...
  $data->{value3} = &share({});
  $data->{value3}->{value4} = 4;

Now, see what you can do with Thread::Shared.

  use Thread::Shared;

  # Recursively copies the hash into a shared hash.
  my $data = Thread::Shared::make_sharable({
  	value1 => 1,
	value2 => 2,
	value3 => {
		value4 => 4
	}
  });

  # Or, alternatively, use our special tied variables which
  # will automatically convert when encountering un-shared data.
  my $data2 = Thread::Shared::create_hash({
  	value1 => 1,
	value2 => 2
  });
  # converts on the fly
  $data2->{value3} = { value4 => 4 };

  # We need the actual shared hash inorder to pass this to another thread.
  my $shared = Thread::Shared::unwrap($data2);

The convenience added here is minor.  However, it is critical, if you are passing references
into functions that expect normal hash or array references, not shared ones.  This is especially
important if you want one of your custom classes to be able to operate while stored in shared
memory.  If you class anywhere puts a non-shared array or hash onto $self, the thread will be
killed.

We make this really simple:

  use Thread::Shared;
  use MyCustomClass;

  # create an instance of my custom class.
  my $obj = MyCustomClass->new();

  # convert the object to our custom tie()'ed hash.
  $obj = Thread::Shared::convert( $obj );

  # continue to call functions normally, now operating in shared memory!
  $obj->callMyMethod();

  # get the actual shared hash out in order to pass it to another thread.
  my $hash = Thread::Shared::unwrap( $obj );

=head1 FUNCTIONS

=over 4

=item one_of_us $value

Returns an instance of Thread::Shared::Array or Thread::Shared::Hash if $value is one of our
magic tie()'d references.  Returns undef otherwise.

=item sharable $value

Returns true if this value is shared, one of our tie()'d references, or not a reference at all.
Returns false otherwise.

=item wrap $value

Takes a shared array or hash and returns one of our magic tie()'d references.

=item unwrap $value

Returns shared data from one of our tie()'d references.

=item make_sharable $value

Returns a value that is capable to be added to a shared hash or array with data copied
from $value.

=item convert $value

Creates one of our magic tie()'d references with data copied from some local variable.  Will
work perfectly fine with bless()'d references.

=back

=head1 LIMITATIONS

Only really works for references of type ARRAY, HASH and bless references based on ARRAY.  Circular references will break any of the functions that recurse.  But, you can use recursive references in our tie()d objects just fine, so long as they are created as you go, and not convert()d in.

=cut

