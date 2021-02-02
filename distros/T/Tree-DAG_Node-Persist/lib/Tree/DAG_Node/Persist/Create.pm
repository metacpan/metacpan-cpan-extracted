package Tree::DAG_Node::Persist::Create;

use strict;
use warnings;

use DBI;

use DBIx::Admin::CreateTable;

use Moo;

use Types::Standard qw/Any ArrayRef Str/;

has dbh =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has dsn =>
(
	default  => sub{return $ENV{DBI_DSN} || ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has extra_columns =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has extra_column_names =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has password =>
(
	default  => sub{return $ENV{DBI_PASS} || ''},
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

has username =>
(
	default  => sub{return $ENV{DBI_USER} || ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.13';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> extra_column_names([split(/\s*,\s*/, $self -> extra_columns)]);

} # End of BUILD.

# -----------------------------------------------

sub connect
{
	my($self) = @_;

	# Warning: Can't just return $self -> dbh(....) for some reason.
	# Tree::DAG_Node::Persist dies at line 137 ($self -> dbh -> prepare_cached).

	$self -> dbh
		(
		 DBI -> connect
		 (
		  $self -> dsn,
		  $self -> username,
		  $self -> password,
		  {
			  AutoCommit => 1,
			  PrintError => 0,
			  RaiseError => 1,
		  }
		 )
		);

	return $self -> dbh;

} # End of connect.

# -----------------------------------------------

sub drop_create
{
	my($self)          = @_;
	my($creator)       = DBIx::Admin::CreateTable -> new(dbh => $self -> dbh, verbose => 0);
	my($table_name)    = $self -> table_name;
	my(@extra_columns) = @{$self -> extra_column_names};
	my($extra_sql)     = '';

	if ($#extra_columns >= 0)
	{
		my(@sql);

		for my $extra (@extra_columns)
		{
			$extra =~ tr/:/ /;

			push @sql, "$extra,";
		}

		$extra_sql = join("\n", @sql);
	}

	$creator -> drop_table($self -> table_name);

	my($primary_key) = $creator -> generate_primary_key_sql($table_name);
	my($result)      = $creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
mother_id integer not null,
$extra_sql
unique_id integer not null,
context varchar(255) not null,
name varchar(255) not null
)
SQL
	# 0 is success.

	return 0;

} # End of drop_create.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	$self -> connect;

	# 0 is success.

	return $self -> drop_create;

} # End of run.

# -----------------------------------------------

1;
