
package Xmldoom::Threads;

use Module::Runtime qw(use_module);
use strict;

BEGIN
{
	if ( $threads::threads )
	{
		use_module 'Thread::Shared';
	}
}

sub make_shared
{
	my $value  = shift;
	my $shared = shift;

	if ( $shared )
	{
		if ( $threads::threads )
		{
			return Thread::Shared::convert($value);
		}
		else
		{
			print "WARNING: Unable to copy this value into shared memory because threading is not enabled.  Use module 'threads' as close to the beginning of your script as possible to enable.";
		}
	}

	return $value;
}

sub is_shared
{
	my $value = shift;

	if ( $threads::threads and Thread::Shared::one_of_us($value) )
	{
		return 1;
	}

	return 0;
}

1;

