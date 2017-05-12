
package Xmldoom::ORB::Transport::JSON;

use JSON qw/ objToJson /;
use strict;

sub new
{
	bless {}, shift;
}

sub get_mime_type
{
	return "text/plain";
}

sub write_object
{
	my ($self, $object) = (shift, shift);

	print objToJson($object);
}

sub write_object_list
{
	my ($self, $rs, $count) = (shift, shift, shift);

	#
	# NOTE: kind of a hack so that we can do this progressively.
	#

	print "{'result':[";
	my $first = 1;
	while ( 1 )
	{
		if ( $rs->next() )
		{
			if ( $first )
			{
				$first = 0;
			}
			else
			{
				print ",";
			}

			$self->write_object( $rs->get_row() );
		}
		else
		{
			# outta here, homes!
			last;
		}
	}
	print "]";

	if ( defined $count )
	{
		print ",'count':$count";
	}

	print "}";
}

sub write_count
{
	my ($self, $count) = (shift, shift);

	print "{'count':$count}";
}

1;

