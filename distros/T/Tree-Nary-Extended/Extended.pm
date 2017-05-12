# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

require 5.005_62; use strict; use warnings;

use Tree::Nary;

use DBI;

use SQL::Generator;

package Tree::Nary::Extended;

our @ISA = qw(Tree::Nary);

our $DEBUG = 0;

use Data::Dumper;

our $VERSION = '0.01';

=pod

=head1 NAME

Tree::Nary::Extended - Tree::Nary with substantial load/save from/to sql/hash

=head1 SYNOPSIS

 use Tree::Nary::Extended;

   Tree::Nary->to_hash( $ntree )

   Tree::Nary->from_dbi_to_hash( $dbh, $table_name )

   Tree::Nary->from_dbi_to_tree( $dbh, $table_name )

   Tree::Nary->to_dbi( $tree, $dbh, $table_name )
 
   Tree::Nary->bread_crumb_trail( $node )

   Tree::Nary->depth( $node )

   Tree::Nary->type( $node )

   my $href_nodes = Tree::Nary->from_dbi( $dbh, $table_name );

   my $nary = Tree::Nary->from_hash( $href_nodes );

   Tree::Nary->depth( $nary->{children} );

   my $found = Tree::Nary->find( $nary, $Tree::Nary::IN_ORDER, $Tree::Nary::TRAVERSE_ALL, 'foobar' );

   my $aref_trail = Tree::Nary->bread_crumb_trail( $found );

   Tree::Nary->append( $found, new Tree::Nary( 'Dummy' ) );

   Tree::Nary->traverse( $nary, $Tree::Nary::PRE_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&Tree::Nary::Extended::_callback_textout );

   my $href_nodes = Tree::Nary->to_hash( $nary );

   Tree::Nary->to_dbi( $href_nodes, $dbh, $table_name );

=head1 DESCRIPTION

This module is not inheriting from Tree::Nary, but adds service methods to the namespace. So it an be seen as an "extended", but a bit "fishy" replacement for Tree::Nary. It loads C<Tree::Nary> in the background and relies on some private innerts, which risks future compability. But noteworthy it works very well and does a good job for its author so far.

=head1 Tree::Nary

You should understand C<Tree::Nary> (from CPAN) concepts first, before you proceed with this module.

=head1 METHODS

=over 1

=item from_hash( $href_all_nodes [, $root_id (default: -1) ] )

Creates a Nary Tree from a hash. The keys must be id, parent_id and data.

=cut

sub from_hash
{
	my $this = shift;

	my $all = shift;

	my $root_id = shift || -1;

		my $href_parents = {};

			# 1. Step) first we connect child >> parent
			#
			# nearby we create a hashtable parent => [children] for the 2. Step

		foreach my $id ( keys %$all )
		{
			my $obj = bless $all->{$id}, 'Tree::Nary';

			if( $root_id != $id )
			{
				$obj->{parent} = undef;

				if( $obj->{parent_id} != $root_id )
				{
					$obj->{parent} = $all->{ $obj->{parent_id} };
				}

				$href_parents->{ $obj->{parent_id} } = [] unless $href_parents->{ $obj->{parent_id} };

				push @{ $href_parents->{ $obj->{parent_id} } }, $obj;
			}

			delete @$obj{ qw(level parent_id) };
		}
			# 2. Step) connect parent >> child and child >> child

		foreach my $parent_id ( keys %$href_parents )
		{
			my $children = $href_parents->{$parent_id};

			my $prev;

			foreach my $child ( @$children )
			{
				$prev->{next} = $child if $prev;

				$child->{prev} = $prev;

				$prev = $child;
			}

			$all->{$parent_id}->{children} = $children->[0];
		}

return $all->{0};
}

=pod

=item to_hash( $nary )

Produces a hash from Nary Tree. Returns a reference to it.

=cut

sub to_hash
{
	my $this = shift;

	my $nary = shift;

		my $href_all = {};

		my ( $highest_id, $unique_id );

		$this->traverse( $nary, $Tree::Nary::PRE_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&_callback_find_highest, \$highest_id );

		print "HIGHEST ID ", $highest_id, "\n" if $DEBUG;

		$unique_id = $highest_id + 1 if defined($highest_id);

		$this->traverse( $nary, $Tree::Nary::PRE_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&_callback_give_id, \$unique_id );

		$this->traverse( $nary, $Tree::Nary::PRE_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&_callback_convert_with_idkeys, $href_all );

return $href_all;
}

=item from_dbi_to_hash( $dbh, $table_name )

Reads a table from a DBI $dbh and produces a hash and returns the hashref to it.

=cut

sub from_dbi_to_hash : method
{
	my $this = shift;

	my $dbh = shift;

	my $table_name = shift;

		my $tree_hash = {};

		if( $dbh )
		{
			my $statement = sprintf 'SELECT id, parent_id, data FROM %s ORDER BY id', $table_name;

			print "Load with DBI from table '$table_name':\n" if $DEBUG;

			foreach my $aref ( @{ $dbh->selectall_arrayref($statement) } )
			{
				my $obj;

				@$obj{qw(id parent_id data)} = @$aref;

				printf "\t%d %d %s\n", @$obj{qw(id parent_id data)} if $DEBUG;
				
				$tree_hash->{ $obj->{id} } = $obj;
			}
		}

		print Dumper $tree_hash if $DEBUG;
		
return $tree_hash;
}

=item from_dbi_to_tree( $dbh, $table_name )

Produces a Tree::Nary::Extended tree out of a DBI table. 

Note: Read the C<DESCRIPTION> from C<DBIx::Tree> for the format of the sql table. The columns names must be "id", "parent_id" and "data"

=cut

sub from_dbi_to_tree : method
{
	my $this = shift;

	my $dbh = shift;

	my $table_name = shift;
	
return Tree::Nary::Extended->from_hash( Tree::Nary::Extended->from_dbi_to_hash( $dbh, $table_name ) );
}

=item to_dbi( $tree, $dbh, $table_name )

Write a C<Tree::Nary::Extended> tree to a DBI table. See Note of C<from_dbi_to_tree> for the format. Only the
three node attributes id, parent_id, data are saved.

Note: The written sql table can be read with C<from_dbi_to_tree> method.

=cut

sub to_dbi : method
{
	my $this = shift;

	my $tree = shift;

	my $dbh = shift;

	my $table_name = shift;

		my $sql = new SQL::Generator( historysize => 10*1000 );

		my %types = ( id => 'INTEGER NOT NULL', parent_id => 'INTEGER', data => 'VARCHAR(80)' );

		eval
		{
			$sql->DROP( TABLE => $table_name ) if Tree::Nary::Extended::tables( $dbh )->{ $table_name };

			$sql->CREATE( TABLE => $table_name, COLS => \%types, PRIMARYKEY => 'id' );

			foreach ( keys %$tree )
			{
				$tree->{$_}->{id} = $_;

				$sql->INSERT( SET => bless( $tree->{$_}, 'HASH' ) , INTO => $table_name );
			}
		};
		if( $@ )
		{
			die;
		}
		else
		{
			foreach ( @{ $sql->history() } )
			{
				print "deploy: $_\n" if $DEBUG;
				
				$dbh->do( $_ ) or die;
			}
		}

return $sql->history();
}

=item bread_crumb_trail( $node )

Traverses the anchestrol tree (partent->to->parent) upwards and collects all parents to an array.
A reference to it is returned. This can be used for building a "bread crumb trail" in website navigation.

=cut

sub bread_crumb_trail : method
{
	my $this = shift;

	my $node = shift || return undef;

		my @nodes;

		do
		{
			push @nodes, $node;
		}
		while( $node = $node->{parent} );

		@nodes = reverse @nodes;

return \@nodes;
}

=item depth( $node )

Returns the depth of a node, which is the distance to the root parent as an integer value.

=cut

sub depth
{
	my ($self, $node) = (shift, shift);

	my $depth = 0;

	while( UNIVERSAL::isa( $node, "Tree::Nary" ) )
	{
		$depth++;

		if( ( $node || 0 ) == ( $node->{parent} || 0 ) )
		{
			die sprintf 'malicious circular reference detected (%s)', $node->{data};
		}

		$node = $node->{parent};
	}

return($depth);
}

=item type( $node )

Returns the node "type". 'root' if it is the root node. 'leaf' if it is a leaf node.

=cut

sub type : method
{
	my $this = shift;

	my $node = shift;

		my $root;
		my $leaf;

		$root = 'root' if $this->is_root( $node );

		$leaf = 'leaf' if $this->is_leaf( $node );

return $root || $leaf || 'dir';
}

=back

=head1 CALLBACKS

C<Tree::Nary> heavily uses callbacks for doing something. C<Tree::Nary::Extended> ships with some
preconfectioned callbacks usefull for various things.

=over 1

=item _callback_find_highest( $sref_highest_id )

Fills the scalarref with the highest node id number of the tree.

=cut

sub _callback_find_highest
{
	my $node = shift;

	my $sref_highest_id = shift;

		if( exists $node->{id} )
		{
			if( $node->{id} > ( $$sref_highest_id || 0 ) )
			{
				$$sref_highest_id = $node->{id};
			}
		}

return $Tree::Nary::FALSE;
}

=item _callback_give_id( $sref_unique )

Overwrite the node ids with primary key ids (linear (+1) unique id).

=cut

sub _callback_give_id
{
	my $node = shift;

	my $sref_unique = shift;

		unless( exists $node->{id} )
		{
			$node->{id} = $$sref_unique++;
		}

return $Tree::Nary::FALSE;
}

=item _callback_convert_with_idkeys( $ref_arg )

Internal use. Cannot remember what is was.

=cut

sub _callback_convert_with_idkeys
{
	my $node = shift;

	my $ref_arg = shift;

		my $parent_id = exists $node->{parent}->{id} ? $node->{parent}->{id} : -1 ;

		$ref_arg->{ $node->{id} } =
		{
			parent_id => $parent_id,

			data => $node->{data},
		};

return $Tree::Nary::FALSE;
}

=item _callback_find_id( $aref_args = [ $id ] )

Returns the first node with a given id. $aref_args[1] will contain the resulting node.

=cut

sub _callback_find_id
{
	my $node = shift;
	
	my $aref_args = shift;
	
	die "callback parameters mismatch" unless ref $aref_args eq 'ARRAY';
	
	printf "Searching %d at %s (will put into %s)\n", $aref_args->[0], $node->{data}, $aref_args->[1] if $DEBUG;
	
		if( exists $node->{id} )
		{
			if( $aref_args->[0] == $node->{id} )
			{
				${ $aref_args->[1] } = $node;

				return $Tree::Nary::TRUE;
			}
		}

return $Tree::Nary::FALSE;
}

=item _callback_textout( $ref_args )

Dumps a textual printout of the node structure. Helps debugging.

=cut

sub _callback_textout
{
	my $node = shift;

	my $ref_arg = shift;

		my $depth = Tree::Nary::Extended->depth( $node );

		print " " x 3 x $depth;

		#println "BUGGGG" if( $node->{data} eq 'Perl' && defined($node->{parent}) );

		my $parent_data;

		if( exists $node->{parent} )
		{
			$parent_data = $node->{parent}->{data} if exists $node->{parent}->{data};
		}

		printf( " %s %s (depth %d, children: %d, parent: %s) %s\n",

			Tree::Nary::Extended->type( $node ),

			$node->{data},

			$depth,

			Tree::Nary::Extended->n_children( $node ),

			$parent_data || 'none',

			exists $node->{id} ? $node->{id} : ''
		);

		print $$ref_arg || '' if defined $ref_arg;

return $Tree::Nary::FALSE;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=back

=head1 FUNCTIONS

=over 1

=item tables( $dbh )

Returns a hash of tablenames from a DBI $dbh. Values are 1.

=cut

sub tables
{
	my $dbh = shift;

	my %tables;

	my $aref_result = $dbh->selectcol_arrayref( q{SHOW TABLES} ) or die $DBI::errstr;

	@tables{ @$aref_result } = 1;

return \%tables;
}

=head1 BUGS

Because Tree::Nary isnt that clean OO, i had to use some dirty tricks on the innerts of the private hash objects. Thats why 
this module relies somehow on Tree::Nary Version 1.21 and may be broken on future updates of Tree::Nary.

=head2 EXPORT

None by default.

=head1 AUTHOR

M. Ünalan, muenalan@cpan.org

=head1 SEE ALSO

Tree::Nary, DBIx::Tree

=cut
