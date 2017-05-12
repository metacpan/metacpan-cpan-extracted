package Tree::DAG_Node::Persist;

use strict;
use warnings;

use Moo;

use Scalar::Util 'refaddr';

use Tree::DAG_Node;

use Types::Standard qw/Any Str/;

has context =>
(
	default  => sub{return '-'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has context_col =>
(
	default  => sub{return 'context'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has dbh =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has id_col =>
(
	default  => sub{return 'id'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has mother_id_col =>
(
	default  => sub{return 'mother_id'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has name_col =>
(
	default  => sub{return 'name'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has table_name =>
(
	default  => sub{return 'trees'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has unique_id_col =>
(
	default  => sub{return 'unique_id'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.12';

# --------------------------------------------------

sub read
{
	my($self, $extra) = @_;
	my($table_name)   = $self -> table_name;
	my($sql)          =
		"select * from $table_name where " .
		$self -> context_col .
		' = ? order by ' .
		$self -> unique_id_col;
	my($record) = $self -> dbh -> selectall_arrayref($sql, {Slice => {} }, $self -> context);

	if (! $extra)
	{
		$extra = [];
	}

	my($id);
	my($mother_id);
	my($node);
	my($row, $root_id);
	my(%seen);

	for $row (@$record)
	{
		$id                        = $$row{$self -> id_col};
		$mother_id                 = $$row{$self -> mother_id_col};
		$node                      = Tree::DAG_Node -> new();
		$seen{$id}                 = $node;
		${$node -> attributes}{id} = $id;
		${$node -> attributes}{$_} = $$row{$_} for @$extra;

		$node -> name($$row{$self -> name_col});

		if ($seen{$mother_id})
		{
			$seen{$mother_id} -> add_daughter($node);
		}
		elsif (! $mother_id)
		{
			$root_id = $id;
		}
	}

	return $seen{$root_id};

} # End of read.

# --------------------------------------------------

sub write_node
{
	my($node, $opt) = @_;

	$$opt{unique_id}++;

	my($mother)  = $node -> mother;
	my($mum_ref) = $mother ? refaddr $mother : 0;
	my($mum_id)  = $$opt{id}{$mum_ref} || 0;

	$$opt{sth} -> execute
		(
		 $mum_id,
		 $$opt{unique_id},
		 $$opt{context},
		 $node -> name,
		 map{${$node -> attributes}{$_} } @{$$opt{extra} },
		);

	my($id)             = $$opt{dbh} -> last_insert_id(undef, undef, $$opt{table_name}, undef);
	my($refaddr)        = refaddr $node;
	$$opt{id}{$refaddr} = $id;

	return 1;

} # End of write_node.

# --------------------------------------------------

sub write
{
	my($self, $tree, $extra) = @_;
	my($table_name) = $self -> table_name;
	my($sql)        = "delete from $table_name where " . $self -> context_col . ' = ?';
	my($sth)        = $self -> dbh -> prepare_cached($sql);

	$sth -> execute($self -> context);

	$sql = "insert into $table_name (" .
		$self -> mother_id_col .
		', ' .
		$self -> unique_id_col .
		', ' .
		$self -> context_col .
		', ' .
		$self -> name_col;

	if ($extra && @$extra)
	{
		$sql .= ', ' . join(', ', @$extra);
	}

	$sql .= ') values (?, ?, ?, ?';

	if ($extra && @$extra)
	{
		$sql .= ', ?' x @$extra;
	}

	$sql .= ')';

	$tree -> walk_down
		({
			callback   => \&write_node,
			context    => $self -> context,
			dbh        => $self -> dbh,
			_depth     => 0,
			extra      => $extra || [],
			id         => {},
			self       => $self,
			sth        => $self -> dbh -> prepare_cached($sql),
			table_name => $self -> table_name,
			unique_id  => 0,
		 });

} # End of write.

# -----------------------------------------------

1;

=pod

=head1 NAME

Tree::DAG_Node::Persist - Persist multiple trees in a single db table, preserving child order

=head1 Synopsis

	my($master) = Tree::DAG_Node::Persist -> new
	(
	 context       => 'Master',
	 context_col   => 'context',
	 dbh           => $dbh,
	 id_col        => 'id',
	 mother_id_col => 'mother_id',
	 name_col      => 'name',
	 table_name    => $table_name,
	 unique_id_col => 'unique_id',
	);

	my($tree) = build_tree; # Somehow... See the FAQ for help.

	$master -> write($tree);

	my($shrub) = $master -> read;

	# Prune $shrub by adding/deleting its nodes...

	my($offshoot) = Tree::DAG_Node::Persist -> new
	(
	 context => 'Offshoot', # Don't use Master or it'll overwrite $tree in the db.
	 dbh     => $dbh,
	);

	$offshoot -> write($shrub);

=head1 Description

L<Tree::DAG_Node::Persist> reads/writes multiple trees from/to a single database table, where those
trees are built using L<Tree::DAG_Node>.

See the L</FAQ> for details of the table structure.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installing the module

Install L<Tree::DAG_Node::Persist> as you would for any C<Perl> module:

Run:

	cpanm Tree::DAG_Node::Persist

or run:

	sudo cpan Tree::DAG_Node::Persist

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake)
	make test
	make install

=head1 Method: context([$new_value])

Get or set the value to be used in the 'context' column when the tree is written to or read from
the database.

=head1 Method: context_col([$new_value])

Get or set the value to be used as the name of the 'context' column when the tree is written to or
read from the database.

=head1 Method: dbh([$new_value])

Get or set the value to be used as the database handle when the tree is written to or read from the
database.

=head1 Method: id_col([$new_value])

Get or set the value to be used as the name of the 'id' column when the tree is written to or read
from the database.

=head1 Method: mother_id_col([$new_value])

Get or set the value to be used as the name of the 'mother_id' column when the tree is written to
or read from the database.

=head1 Method: name_col([$new_value])

Get or set the value to be used as the name of the 'name' column when the tree is written to or
read from the database.

=head1 Method: new({...})

Returns a new object of type C<Tree::DAG_Node::Persist>.

Key-value pairs in the hashref:

=over 4

=item context => $a_string

This is the value to be used in the 'context' column when the tree is written to or read from the
database.

This key is optional.

It defaults to '-'.

=item context_col => $a_string

This is the name to be used for the 'context' column when the tree is written to or read from the
database.

This key is optional.

If defaults to 'context'.

=item dbh => A database handle

This is the database handle to use.

This key-value pair is mandatory.

There is no default.

=item id_col => $a_string

This is the name to be used for the 'id' column when the tree is written to or read from the
database.

This key is optional.

If defaults to 'id'.

=item mother_id_col => $a_string

This is the name to be used for the 'mother_id' column when the tree is written to or read from the
database.

This key is optional.

If defaults to 'mother_id'.

=item name_col => $a_string

This is the name to be used for the 'name' column when the tree is written to the database.

This key is optional.

If defaults to 'name'.

=item table_name => $a_string

This is the name of the database table used for reading and writing trees.

This key is optional.

If defaults to 'trees'.

=item unique_id_col => $a_string

This is the name to be used for the 'unique_id' column when the tree is written to or read from the
database.

This key is optional.

If defaults to 'unique_id'.

=back

=head1 Method: table name([$new_value])

Get or set the value to be used as the name of the table when the tree is written to or read from
the database.

=head1 Method: unique_id_col([$new_value])

Get or set the value to be used as the name of the 'unique_id' column when the tree is written to
or read from the database.

=head1 Method: read([$extra])

Returns a tree of type L<Tree::DAG_Node> read from the database.

If the optional parameter $extra is provided, then it is assumed to be an arrayref of field names.

C<read($extra)> is used in conjunction with C<write($tree, $extra)>. See that method for more
details.

This code shows how to save and restore an attribute of each node called 'page_id'.

Note: In this code, the [] indicate an arrayref, not optional parameters.

	$object -> write($tree, ['page_id']);

	$shrub = $object -> read(['page_id']);

The test program t/test.t demonstrates usage of this feature.

=head1 Method: write_node($node, {...})

This method is called by write(), and - naturally - you'll never call it directly.

=head1 Method: write($tree[, $extra])

Writes a tree of type L<Tree:DAG_Node> to the database.

If the optional parameter $extra is provided, then it is assumed to be an arrayref of field names:

=over 4

=item o Each field's name is the name of a column in the table

=item o Each field's value is extracted from the attributes of the node, via the field's name

=item o The (field name => field value) pairs are written to each record in the table

=back

In particular note that you can store - in a single table - trees which both do and don't have extra
fields.

Just ensure the definition of each extra column is flexible enough to handle these alternatives.

The test program t/test.t demonstrates usage of this feature.

This method does not return a meaningful value.

=head1 FAQ

=over 4

=item What is the required table structure?

Firstly, note that the column names used here are the defaults. By supplying suitable parameters
to C<new()>, or calling the appropriate method, you can use any column names you wish.

As a minimum, you must have these fields in the table used to hold the trees:

	id $primary_key,
	mother_id integer not null,
	unique_id integer not null,
	context varchar(255) not null,
	name varchar(255) not null

You can generate the $primary_key text using L<DBIx::Admin::CreateTable>, as is done in t/test.t.

=item What is id?

Strictly speaking, the id field does not have to be a primary key, but it must be unique, because
it's used as a hash key when a tree is read in from the database.

The value of id is stored in each node when the tree is read in, whereas the values of context and
unique_id are not.

The id of a node can be recovered from the 'attribute' hashref associated with any node, using the
code:

	my($id) = ${$node -> attribute}{id} || 0;

Of course, this id (in the 'attribute' hashref) only exists if the tree has been written to the
database and read back in. For a brand-new node, which has never been saved, there is no id value by
default, hence the '|| 0'. Naturally, you're free to jam some sort of value in there yourself.

=item What is mother_id?

It is the id of the node which is the mother of the 'current' node. Using 'mother' rather than
'parent', and 'daughter' rather than 'child', is terminology I have adopted from L<Tree::DAG_Node>.

The mother_id of the root of each tree is 0, allowing you to use 'not null' on the definition of
mother_id.

This 'not null' convention is adopted from:

	Joe Celko's SQL for Smarties 2nd edition
	Morgan Kaufmann
	1-55860-576-2
	Section 6.9, page 120, Design Advice for NULLs

The mother_id of a node can be recovered from the 'attribute' hashref associated with any node,
using the code:

	my($mother) = $node -> mother;
	my($id)     = $mother ? ${$mother -> attribute}{id} : 0;

=item What is unique_id?

For a given tree (in the database), each node has the same value for context, but a unique value
for unique_id.

The reason the id field is not used for this, is that nodes in one tree may be deleted, so that when
a second tree is written to the database, if the database reuses ids, the order of ids no longer
means anything.

The module writes a node to the database before it writes that node's children. By generating a
unique value as the nodes are written, the module guarantees a node's unique_id will be less that
the unique_ids of each of its children.

Then, when the nodes are read back in, the database is used to sort the nodes using their unique_id
as the sort key.

In this manner, the order of children belonging to a node is preserved.

The field unique_id is only unique for a given tree (in the database). The root of each tree has a
unique_id of 1.

The value of id is stored in each node when the tree is read in, whereas the value of context and
unique_id are not.

=item What is context?

You give each tree some sort of identifying string, which is stored in the context field.

For a given tree, all nodes must have the same value for this context field.

Reading a tree means reading all records whose context matches the value you provide.

Writing a tree means:

=over 4

=item * Delete

All records whose context matches the value you provide are deleted.

=item * Insert

All nodes in the tree are inserted in the table.

=back

The reason for this 2-step process is to avoid depending on ids provided by the database, which may
be reused after records are deleted.

By inserting the tree afresh each time, we can ensure the unique_id values for the given tree are
generated in such a way that when the records are read back in, sorted by unique_id, each mother
node is read before any of its daughters. This makes it easy to insert the incoming data into a new
tree in a reliable manner, and to guarantee daughter nodes have their order preseved throughout the
write-then-read cycle.

The value of id is stored in each node when the tree is read in, whereas the value of context and
unique_id are not.

=item What is name?

Each node can have any name you wish. See L<Tree::DAG_Node> for details.

The name of a node can be recovered with the name method associated with any node, using the code:

	my($name) = $node -> name;

=item How do I build a tree from a text file?

See sub build_tree() in t/test.t, and where it's called from.

=item How do I process a single node?

See sub find_junk() or sub find_node() in t/test.t, and where they're called from.

=item How do I pretty-print a tree?

See sub pretty_print() in t/test.t, and where it's called from.

=item How do I run t/test.t?

You can set the environment variables $DBI_DSN, $DBI_USER and $DBI_PASS, and the program will use a
table called 'menus'. The I<default> table name is 'trees'.

Or, if $DBI_DSN has no value, the program will use SQLite and a default file (i.e. database) name,
in the temp directory.

=back

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 See Also

L<Data::NestedSet>. This module has its own list of See Also references.

L<DBIx::Tree::NestedSet>. This module has its own list of See Also references.

L<DBIx::Tree>.

L<DBIx::Tree::Persist>.

L<Tree>.

L<Tree::Persist>.

Thanx to the author(s) of Tree::Persist, for various ideas implemented in this module.

L<Tree::DAG_Node>.

=head1 Repository

L<https://github.com/ronsavage/Tree-DAG_Node-Persist>.

=head1 License

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl 5.10.0.

For more details, see the full text of the licenses at
http://www.perlfoundation.org/artistic_license_1_0,
and http://www.gnu.org/licenses/gpl-2.0.html.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-DAG_Node-Persist>.

=head1 Author

L<Tree::DAG_Node::Persist> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut

