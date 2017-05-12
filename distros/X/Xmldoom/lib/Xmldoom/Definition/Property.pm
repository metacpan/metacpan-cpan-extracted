
package Xmldoom::Definition::Property;

use Xmldoom::Object::Property;
use Scalar::Util qw(weaken);
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $parent;
	my $name;
	my $description;
	my $hints;
	my $reportable = 1;
	my $searchable = 1;
	my $shared = 0;

	if ( ref($args) eq 'HASH' )
	{
		$parent      = $args->{parent};
		$name        = $args->{name};
		$description = $args->{description};
		$hints       = $args->{hints};
		$reportable  = $args->{reportable} if defined $args->{reportable};
		$searchable  = $args->{searchable} if defined $args->{searchable};
		$shared      = $args->{shared}     if defined $args->{shared};
	}
	else
	{
		$parent = $args;
		$name   = shift;
	}

	my $self = {
		parent      => $parent,
		name        => $name,
		description => $description || undef,
		hints       => $hints       || { },
		reportable  => $reportable  || 0,
		searchable  => $searchable  || 0,
	};
	bless $self, $class;

	# we have to do this before any weak references are manipulated
	# because copies of weak references are strong references.
	$self = Xmldoom::Threads::make_shared($self, $shared);

	# weaken reference to parent
	if ( defined $self->{parent} )
	{
		weaken( $self->{parent} );
	}

	return $self;
}

sub get_parent      { return shift->{parent}; }
sub get_name        { return shift->{name}; }
sub get_description { return shift->{description}; }
sub get_reportable  { return shift->{reportable}; }
sub get_searchable  { return shift->{searchable}; }

sub get_hint 
{
	my ($self, $name) = @_;
	return $self->{hints}->{$name};
}

# NOTE: you need to override for any property which forces to join
# with another table, to ensure that the table gets on the from list
# of the query.
sub get_tables
{
	my $self = shift;

	return [ $self->get_parent()->get_table_name() ];
}

sub get_autoload_get_list
{
	die "Abstract.";
}

sub get_autoload_set_list
{
	die "Abstract.";
}

sub get_type
{
	die "Abstract.";
}

sub get_data_type
{
	die "Abstract.";
}

sub get
{
	die "Abstract.";
}

sub set
{
	die "Abstract.";
}

sub get_query_lval
{
	die "Abstract.";
}

sub get_query_rval
{
	die "Abstract.";
}

sub autoload
{
	die "Abstract.";
}

1;

