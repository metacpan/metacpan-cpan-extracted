package Tree::Persist::DB::SelfReferential;

use strict;
use warnings;

use base qw( Tree::Persist::DB );

use Module::Runtime;

use Scalar::Util qw( blessed refaddr );

our $VERSION = '1.13';

my(%defaults) =
(
	id_col        => 'id',
	parent_id_col => 'parent_id',
	value_col     => 'value',
#	class_col     => 'class',
);

# ----------------------------------------------

sub _init
{
	my($class)   = shift;
	my($opts)    = @_;
	my($self)    = $class -> SUPER::_init( $opts );
	$self->{_id} = $opts->{id};

	while ( my ($name, $val) = each %defaults )
	{
		$self->{ "_${name}" } = $opts->{ $name } ? $opts->{ $name } : $val;
	}

	if ( exists $opts->{class_col} )
	{
		$self->{_class_col} = $opts->{class_col};
	}

	return $self;

} # End of _init.

# ----------------------------------------------

sub _reload
{
	my($self) = shift;
	my(%sql)  = $self->_build_sql;
	my($sth)  = $self->{_dbh} -> prepare( $sql{ fetch } );

	$sth -> execute( $self->{_id} );

	my ($id, $parent_id, $value, $class) = $sth -> fetchrow_array();

	$sth -> finish;

	my($tree)     = Module::Runtime::use_module($class) -> new( $value );
	my($ref_addr) = refaddr $self;

	$tree->meta->{$ref_addr}{id}        = $id;
	$tree->meta->{$ref_addr}{parent_id} = $parent_id;

	my(@parents) = ( $tree );

	my($node);
	my($sth_child);

	while ( my $parent = shift @parents )
	{
		$sth_child = $self->{_dbh} -> prepare( $sql{ fetch_children } );

		$sth_child -> execute( $parent -> meta->{$ref_addr}{id} );

		$sth_child -> bind_columns( \my ($id, $value, $class) );

		while ($sth_child -> fetch)
		{
			$node = Module::Runtime::use_module($class) -> new( $value );

			$parent -> add_child( $node );

			$node->meta->{$ref_addr}{id}        = $id;
			$node->meta->{$ref_addr}{parent_id} = $parent_id;

			push @parents, $node;
		}

		$sth_child -> finish;
	}

	$self -> _set_tree( $tree );

	return $self;

} # End of _reload.

# ----------------------------------------------

sub _create
{
	my($self)    = shift;
	my($tree)    = shift;
	$tree        = $self -> tree if (! $tree);
	my($dbh)     = $self->{_dbh};
	my(%sql)     = $self->_build_sql;
	my($next_id) = do
	{
		my($sth) = $dbh->prepare( $sql{next_id} );

		$sth->execute;
		$sth->fetchrow_array;
	};
	my($ref_addr) = refaddr $self;
	my($sth)      = $dbh->prepare( $sql{create_node} );
	my $traversal = $tree -> traverse( $tree -> LEVEL_ORDER );

	my($node_id);
	my($parent_id);

	while ( my $node = $traversal->() )
	{
		$node_id
			= $node -> meta->{$ref_addr}{id}
			= $next_id++;

		$parent_id
			= $node -> meta->{$ref_addr}{parent_id}
			= eval { $node -> parent -> meta->{$ref_addr}{id} };

		if ( $self->{_class_col} )
		{
			$sth->execute($node_id, $parent_id, $node->value, blessed( $node ) );
		}
		else {
			$sth->execute($node_id, $parent_id, $node->value);
		}
	}

	$sth -> finish;

	return $self;

} # End of _create.

# ----------------------------------------------

sub _commit
{
	my($self)     = shift;
	my($dbh)      = $self->{_dbh};
	my(%sql)      = $self -> _build_sql;
	my($ref_addr) = refaddr $self;

	my($sth);

	for my $change ( @{$self->{_changes}} )
	{
		if ( $change->{action} eq 'change_value' )
		{
			$sth = $dbh->prepare_cached( $sql{set_value} );

			$sth -> execute($change->{new_value}, $change->{node}->meta->{$ref_addr}{id});
			$sth -> finish;
		}
		elsif ( $change->{action} eq 'add_child' )
		{
			for my $child ( @{$change->{children}} )
			{
				$self -> _create( $child );
			}
		}
		elsif ( $change->{action} eq 'remove_child' )
		{
			for my $child ( @{$change->{children}} )
			{
				$sth = $dbh -> prepare_cached( $sql{set_parent} );

				$sth -> execute(undef, $child -> meta->{$ref_addr}{id});
				$sth -> finish;
			}
		}
	}

	return $self;

} # End of _commit.

# ----------------------------------------------

sub _build_sql
{
	my($self) = shift;
	my(%sql)  =
	(
		next_id => <<"__END_SQL__",
SELECT coalesce(MAX($self->{_id_col}),0) + 1
  FROM $self->{_table}
__END_SQL__
		set_value => <<"__END_SQL__",
UPDATE $self->{_table}
   SET $self->{_value_col} = ?
 WHERE $self->{_id_col} = ?
__END_SQL__
		set_parent => <<"__END_SQL__",
UPDATE $self->{_table}
   SET $self->{_parent_id_col} = ?
 WHERE $self->{_id_col} = ?
__END_SQL__
	);

	if ( $self->{_class_col} )
	{
		$sql{fetch} = <<"__END_SQL__";
SELECT $self->{_id_col}		AS id
	  ,$self->{_parent_id_col} AS parent_id
	  ,$self->{_value_col}	 AS value
	  ,$self->{_class_col}	 AS class
  FROM $self->{_table} AS tree
 WHERE tree.$self->{_id_col} = ?
__END_SQL__

		$sql{fetch_children} = <<"__END_SQL__";
SELECT $self->{_id_col}		AS id
	  ,$self->{_value_col}	 AS value
	  ,$self->{_class_col}	 AS class
  FROM $self->{_table} AS tree
 WHERE tree.$self->{_parent_id_col} = ?
__END_SQL__

		$sql{create_node} = <<"__END_SQL__";
INSERT INTO $self->{_table} (
	$self->{_id_col}
   ,$self->{_parent_id_col}
   ,$self->{_value_col}
   ,$self->{_class_col}
) VALUES ( ?, ?, ?, ? )
__END_SQL__
	}
	else
	{
		$sql{fetch} = <<"__END_SQL__";
SELECT $self->{_id_col}		AS id
	  ,$self->{_parent_id_col} AS parent_id
	  ,$self->{_value_col}	 AS value
	  ,'$self->{_class}'	   AS class
  FROM $self->{_table} AS tree
 WHERE tree.$self->{_id_col} = ?
__END_SQL__

		$sql{fetch_children} = <<"__END_SQL__";
SELECT $self->{_id_col}		AS id
	  ,$self->{_value_col}	 AS value
	  ,'$self->{_class}'	   AS class
  FROM $self->{_table} AS tree
 WHERE tree.$self->{_parent_id_col} = ?
__END_SQL__

		$sql{create_node} = <<"__END_SQL__";
INSERT INTO $self->{_table} (
	$self->{_id_col}
   ,$self->{_parent_id_col}
   ,$self->{_value_col}
) VALUES ( ?, ?, ? )
__END_SQL__
	}

	return %sql;

} # End of _build_sq.

# ----------------------------------------------

1;

__END__

=head1 NAME

Tree::Persist::DB::SelfReferential - A handler for Tree persistence

=head1 SYNOPSIS

See L<Tree::Persist/SYNOPSIS> or scripts/xml.demo.pl for sample code.

=head1 DESCRIPTION

This module is a plugin for L<Tree::Persist> to store a L<Tree> to a
self-referential DB table. This is where a table contains an id column for the
row and a parent_id column that refers back to another row's id (which is the
parent row).

This is the simplest way to store a tree datastructure in a database, but it
has performance penalties.

=head1 PARAMETERS

Parameters are used in the call to L<Tree::Persist/connect({%opts})> or L<Tree::Persist/create_datastore({%opts})>.

In addition to any parameters required by its parent L<Tree::Persist::DB>, the following
parameters are used by C<connect()> or C<create_datastore()>:

=over 4

=item * id (required)

This is the id for the root node of the tree. By specifying this, you can both
store more that one tree in a table as well as only load a subtree.

=item * id_col (optional)

This is the column name for the id field. It defaults to "id".

=item * parent_id_col (optional)

This is the column name for the parent_id field. It defaults to "parent_id".

=item * value_col (optional)

This is the column name for the value field. It defaults to "value".

=item * class_col (optional)

This is the column name for the class field.

=back

=head1 Methods

Tree::Persist::DB::SelfReferential is a sub-class of L<Tree::Persist::DB>, and inherits all its methods.

=head1 TODO

=over 4

=item *

Provide for a way to default the class to 'Tree' if no class_col is provided.
Also, allow for the classname to be passed into the constructor.

=back

=head1 CODE COVERAGE

Please see the relevant section of L<Tree::Persist>.

=head1 SUPPORT

Please see the relevant section of L<Tree::Persist>.

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

Co-maintenance since V 1.01 is by Ron Savage <rsavage@cpan.org>.
Uses of 'I' in previous versions is not me, but will be hereafter.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
