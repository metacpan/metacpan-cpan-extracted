
package Xmldoom::Schema;

use Xmldoom::Schema::Table;
use Xmldoom::Threads;
use Exception::Class::TryCatch;
use strict;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $self = {
		tables => { }
	};

	bless  $self, $class;
	return Xmldoom::Threads::make_shared($self, $args->{shared});
}

sub get_tables { return shift->{tables}; }
sub get_table
{
	my ($self, $name) = @_;

	if ( not defined $self->{tables}->{$name} )
	{
		die "Unknown table named '$name'";
	}

	return $self->{tables}->{$name};
}
sub has_table
{
	my ($self, $name) = @_;
	return defined $self->{tables}->{$name};
}

sub create_table
{
	my ($self, $name) = @_;

	if ( exists $self->{tables}->{$name} )
	{
		die "Table name \"$name\" already exists";
	}

	my $table = Xmldoom::Schema::Table->new({
		parent => $self,
		name   => $name,
	});
	$self->{tables}->{$name} = $table;
	return $table;
}

1;

