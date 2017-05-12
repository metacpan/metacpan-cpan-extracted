
package Xmldoom::Definition::Link;
use base qw(Exporter);

use strict;

use Data::Dumper;

our @EXPORT_OK = qw(
	ONE_TO_ONE,
	MANY_TO_ONE,
	ONE_TO_MANY,
	MANY_TO_MANY
);

our $ONE_TO_ONE   = 'one-to-one';
our $MANY_TO_ONE  = 'many-to-one';
our $ONE_TO_MANY  = 'one-to-many';
our $MANY_TO_MANY = 'many-to-many';

sub new
{
	my $class = shift;
	my $args  = shift;

	if ( not defined $args )
	{
		$args = [ ];
	}
	elsif ( ref($args) ne 'ARRAY' )
	{
		$args = [ $args ];
	}

	my $relationship;

	if ( scalar @$args > 1 )
	{
		# TODO: is this really that simple?
		$relationship = $MANY_TO_MANY;
	}
	else
	{
		my $fn = $args->[0];

		my $local_key = $fn->get_table()->get_column_names({ primary_key => 1 });
		my $foreign_key = $fn->get_reference_table()->get_column_names({ primary_key => 1 });

		# check if the local or foreign connection has the complete table key
		my $has_local_key = $fn->is_local_column_names( $local_key );
		my $has_foreign_key = $fn->is_foreign_column_names( $foreign_key );

		# look-up the appropriate relationship
		if ( not $has_local_key and $has_foreign_key )
		{
			$relationship = $MANY_TO_ONE;
		}
		elsif ( $has_local_key and not $has_foreign_key )
		{
			$relationship = $ONE_TO_MANY;
		}
		elsif ( $has_local_key and $has_foreign_key )
		{
			$relationship = $ONE_TO_ONE;
		}
		else
		{
			$relationship = $MANY_TO_MANY;
		}
	}

	my $self =
	{
		foreign_keys => $args,
		relationship => $relationship
	};

	bless  $self, $class;
	return $self;
}

sub get_foreign_keys       { return shift->{foreign_keys}; }
sub get_count              { return scalar @{shift->{foreign_keys}}; }
sub get_start              { return shift->{foreign_keys}->[0]; }
sub get_end                { return shift->{foreign_keys}->[-1]; }
sub get_start_column_names { return shift->get_start()->get_local_column_names(); }
sub get_end_column_names   { return shift->get_end()->get_foreign_column_names(); }
sub get_start_table_name   { return shift->get_start()->get_table_name(); }
sub get_end_table_name     { return shift->get_end()->get_reference_table_name(); }
sub get_relationship       { return shift->{relationship}; }

sub is_start_column_names
{
	my ($self, $column_names) = @_;
	return $self->get_start()->is_local_column_names( $column_names );
}

sub is_end_column_names
{
	my ($self, $column_names) = @_;
	return $self->get_end()->is_foreign_column_names( $column_names );
}

# NOTE: a convenience function for when you *know* it is or can only accept a link
# with a single foreign in it.
sub get_foreign_key
{
	my $self = shift;

	if ( $self->get_count() > 1 )
	{
		die "Link contains a chain of foreign keys rather than a single than a single foreign key which is what we expected.  Could be a bug in Xmldoom!";
	}

	return $self->get_foreign_keys()->[0];
}

# convenience functions that work like get_foreign_key().
sub get_column_names { return shift->get_foreign_key()->get_column_names(); }

sub equals
{
	my ($self, $link) = @_;

	if ( $self->get_count() != $link->get_count() )
	{
		return 0;
	}

	for( my $i = 0; $i < $self->get_count(); $i++ )
	{
		if ( not $self->{foreign_keys}->[$i]->equals( $link->{foreign_keys}->[$i] ) )
		{
			return 0;
		}
	}

	return 1;
}

sub contains
{
	my ($self, $link) = @_;

	if ( $link->get_count() > $self->get_count() )
	{
		return 0;
	}
	
	my $offset = ($self->get_count() - $self->get_count());

	# attempt to locate the correct offset
	while ( $offset >= 0 )
	{
		if ( $self->{foreign_keys}->[$offset]->equals( $link->{foreign_keys}->[0] ) )
		{
			# this is it, yo!
			last;
		}

		$offset --;
	}

	# couldn't locate the appropriate offset, so it couldn't possibly contain it.
	if ( $offset < 0 )
	{
		return 0;
	}

	# count up from the offset and make sure the rest is equal
	for( my $i = 1; $i < $link->get_count(); $i++ )
	{
		if ( not $self->{foreign_keys}->[$i+$offset]->equals( $link->{foreign_keys}->[$i] ) )
		{
			return 0;
		}
	}

	return 1;
}

# this is a static function.
sub reduce_longest
{
	my $link_list = shift;

	my @longest;

	foreach my $link1 ( @$link_list )
	{
		my $is_contained = 0;

		foreach my $link2 ( @$link_list )
		{
			if ( $link1 == $link2 )
			{
				next;
			}
			
			if ( $link2->contains( $link1 ) )
			{
				$is_contained = 1;
				last;
			}
		}

		if ( not $is_contained )
		{
			push @longest, $link1;
		}
	}

	return \@longest;
}

# this is a static function.
sub reduce_shortest
{
	my $link_list = shift;

	my @shortest;

	foreach my $link1 ( @$link_list )
	{
		my $is_container = 0;

		foreach my $link2 ( @$link_list )
		{
			if ( $link1 == $link2 )
			{
				next;
			}
			
			if ( $link1->contains( $link2 ) )
			{
				$is_container = 1;
				last;
			}
		}

		if ( not $is_container )
		{
			push @shortest, $link1;
		}
	}

	return \@shortest;
}

sub clone_reverse
{
	my $self = shift;

	my @foreign_keys;
	foreach my $fkey ( @{$self->{foreign_keys}} )
	{
		unshift @foreign_keys, $fkey->clone_reverse();
	}

	return Xmldoom::Definition::Link->new( \@foreign_keys );
}

1;

