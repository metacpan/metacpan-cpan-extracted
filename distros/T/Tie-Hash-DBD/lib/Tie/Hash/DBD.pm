package Tie::Hash::DBD;

our $VERSION = "0.16";

use strict;
use warnings;

use Carp;

use DBI;
use Storable qw( nfreeze thaw );

my $dbdx = 0;

my %DB = (
    # k_asc is needed if h_key mush be converted to hex because
    #       where clause is not permitted on binary/BLOB/...
    Pg		=> {
	temp	=> "temp",
	t_key	=> "bytea primary key",
	t_val	=> "bytea",
	clear	=> "truncate table",
	autoc	=> 0,
	},
    Unify	=> {
	temp	=> "",
	t_key	=> "text",
	t_val	=> "binary",
	clear	=> "delete from",
	k_asc	=> 1,
	},
    Oracle	=> {
	# Oracle does not allow where clauses on BLOB's nor does it allow
	# BLOB's to be primary keys
	temp	=> "global temporary",	# Only as of Ora-9
	t_key	=> "varchar2 (4000) primary key",
	t_val	=> "blob",
	clear	=> "truncate table",
	autoc	=> 0,
	k_asc	=> 1,
	},
    mysql	=> {
	temp	=> "temporary",
	t_key	=> "blob",	# Does not allow binary to be primary key
	t_val	=> "blob",
	clear	=> "truncate table",
	autoc	=> 0,
	},
    SQLite	=> {
	temp	=> "temporary",
	t_key	=> "text primary key",
	t_val	=> "blob",
	clear	=> "delete from",
	pbind	=> 0, # TYPEs in SQLite are text, bind_param () needs int
	autoc	=> 0,
	},
    CSV		=> {
	temp	=> "temporary",
	t_key	=> "text primary key",
	t_val	=> "text",
	clear	=> "delete from",
	},
    Firebird	=> {
	temp	=> "",
	t_key	=> "varchar (8192)",
	t_val	=> "varchar (8192)",
	clear	=> "delete from",
	},
    );

sub _create_table
{
    my ($cnf, $tmp) = @_;
    $cnf->{tmp} = $tmp;

    my $dbh = $cnf->{dbh};
    my $dbt = $cnf->{dbt};

    my $exists = 0;
    eval {
	local $dbh->{PrintError} = 0;
	my $sth = $dbh->prepare ("select $cnf->{f_k}, $cnf->{f_v} from $cnf->{tbl}");
	$sth->execute;
	$cnf->{tmp} = 0;
	$exists = 1;
	};
    $exists and return;	# Table already exists

    my $temp = $DB{$dbt}{temp};
    $cnf->{tmp} or $temp = "";
    local $dbh->{AutoCommit} = 1 unless $dbt eq "CSV" || $dbt eq "Unify";
    $dbh->do (
	"create $temp table $cnf->{tbl} (".
	    "$cnf->{f_k} $cnf->{ktp},".
	    "$cnf->{f_v} $cnf->{vtp})"
	);
    $dbt eq "Unify" and $dbh->commit;
    } # create table

sub TIEHASH
{
    my $pkg = shift;
    my $usg = qq{usage: tie %h, "$pkg", \$dbh [, { tbl => "tbl", key => "f_key", fld => "f_value" }];};
    my $dsn = shift or croak $usg;
    my $opt = shift;

    my $dbh = ref $dsn
	? $dsn->clone
	: DBI->connect ($dsn, undef, undef, {
	    PrintError       => 1,
	    RaiseError       => 1,
	    PrintWarn        => 0,
	    FetchHashKeyName => "NAME_lc",
	    }) or croak (DBI->errstr);

    my $dbt = $dbh->{Driver}{Name} || "no DBI handle";
    my $cnf = $DB{$dbt} or croak "I don't support database '$dbt'";
    my $f_k = "h_key";
    my $f_v = "h_value";
    my $tmp = 0;

    $dbh->{PrintWarn}   = 0;
    $dbh->{AutoCommit}  = $cnf->{autoc} if exists $cnf->{autoc};
    $dbh->{LongReadLen} = 4_194_304     if $dbt eq "Oracle";

    my $h = {
	dbt => $dbt,
	dbh => $dbh,
	tbl => undef,
	tmp => $tmp,
	str => undef,
	asc => $cnf->{k_asc} || 0,
	trh => 0,
	ktp => $cnf->{t_key},
	vtp => $cnf->{t_val},
	};

    if ($opt) {
	ref $opt eq "HASH" or croak $usg;

	$opt->{key} and $f_k      = $opt->{key};
	$opt->{fld} and $f_v      = $opt->{fld};
	$opt->{tbl} and $h->{tbl} = $opt->{tbl};
	$opt->{str} and $h->{str} = $opt->{str};
	$opt->{trh} and $h->{trh} = $opt->{trh};
	$opt->{ktp} and $h->{ktp} = $opt->{ktp};
	$opt->{vtp} and $h->{vtp} = $opt->{vtp};
	}

    $h->{f_k} = $f_k;
    $h->{f_v} = $f_v;
    $h->{trh} and $dbh->{AutoCommit} = 0;

    if ($h->{tbl}) {		# Used told the table name
	$dbh->{AutoCommit} = 1 unless $h->{trh} || $dbt eq "CSV" || $dbt eq "Unify";
	}
    else {			# Create a temporary table
	$tmp = ++$dbdx;
	$h->{tbl} = "t_tie_dbdh_$$" . "_$tmp";
	}
    _create_table ($h, $tmp);

    my $tbl = $h->{tbl};

    $h->{ins} = $dbh->prepare ("insert into $tbl values (?, ?)");
    $h->{del} = $dbh->prepare ("delete from $tbl where $f_k = ?");
    $h->{upd} = $dbh->prepare ("update $tbl set $f_v = ? where $f_k = ?");
    $h->{sel} = $dbh->prepare ("select $f_v from $tbl where $f_k = ?");
    $h->{cnt} = $dbh->prepare ("select count(*) from $tbl");
    $h->{ctv} = $dbh->prepare ("select count(*) from $tbl where $f_k = ?");

    unless (exists $cnf->{pbind} && !$cnf->{pbind}) {
	my $sth = $dbh->prepare ("select $f_k, $f_v from $tbl where 0 = 1");
	$sth->execute;
	my @typ = @{$sth->{TYPE}};

	$h->{ins}->bind_param (1, undef, $typ[0]);
	$h->{ins}->bind_param (2, undef, $typ[1]);
	$h->{del}->bind_param (1, undef, $typ[0]);
	$h->{upd}->bind_param (1, undef, $typ[1]);
	$h->{upd}->bind_param (2, undef, $typ[0]);
	$h->{sel}->bind_param (1, undef, $typ[0]);
	$h->{ctv}->bind_param (1, undef, $typ[0]);
	}

    bless $h, $pkg;
    } # TIEHASH

sub _stream
{
    my ($self, $val) = @_;
    defined $val or return undef;
    $self->{str} or return $val;

    $self->{str} eq "Storable" and return nfreeze ({ val => $val });
    return $val;
    } # _stream

sub _unstream
{
    my ($self, $val) = @_;
    defined $val or return undef;
    $self->{str} or return $val;

    $self->{str} eq "Storable" and return thaw ($val)->{val};
    return $val;
    } # _unstream

sub STORE
{
    my ($self, $key, $value) = @_;
    my $k = $self->{asc} ? unpack "H*", $key : $key;
    my $v = $self->_stream ($value);
    $self->{trh} and $self->{dbh}->begin_work unless $self->{dbt} eq "SQLite";
    my $r = $self->EXISTS ($key)
	? $self->{upd}->execute ($v, $k)
	: $self->{ins}->execute ($k, $v);
    $self->{trh} and $self->{dbh}->commit;
    $r;
    } # STORE

sub DELETE
{
    my ($self, $key) = @_;
    $self->{asc} and $key = unpack "H*", $key;
    $self->{trh} and $self->{dbh}->begin_work unless $self->{dbt} eq "SQLite";
    $self->{sel}->execute ($key);
    my $r = $self->{sel}->fetch;
    unless ($r) {
	$self->{trh} and $self->{dbh}->rollback;
	return;
	}

    $self->{del}->execute ($key);
    $self->{trh} and $self->{dbh}->commit;
    $self->_unstream ($r->[0]);
    } # DELETE

sub CLEAR
{
    my $self = shift;
    $self->{dbh}->do ("$DB{$self->{dbt}}{clear} $self->{tbl}");
    } # CLEAR

sub EXISTS
{
    my ($self, $key) = @_;
    $self->{asc} and $key = unpack "H*", $key;
    $self->{sel}->execute ($key);
    return $self->{sel}->fetch ? 1 : 0;
    } # EXISTS

sub FETCH
{
    my ($self, $key) = @_;
    $self->{asc} and $key = unpack "H*", $key;
    $self->{sel}->execute ($key);
    my $r = $self->{sel}->fetch or return;
    $self->_unstream ($r->[0]);
    } # STORE

sub FIRSTKEY
{
    my $self = shift;
    $self->{trh} and $self->{dbh}->begin_work unless $self->{dbt} eq "SQLite";
    $self->{key} = $self->{dbh}->selectcol_arrayref ("select $self->{f_k} from $self->{tbl}");
    $self->{trh} and $self->{dbh}->commit;
    unless (@{$self->{key}}) {
	$self->{trh} and $self->{dbh}->commit;
	return;
	}
    if ($self->{asc}) {
	 $_ = pack "H*", $_ for @{$self->{key}};
	 }
    pop @{$self->{key}};
    } # FIRSTKEY

sub NEXTKEY
{
    my $self = shift;
    unless (@{$self->{key}}) {
	$self->{trh} and $self->{dbh}->commit;
	return;
	}
    pop @{$self->{key}};
    } # FIRSTKEY

sub SCALAR
{
    my $self = shift;
    $self->{cnt}->execute;
    my $r = $self->{cnt}->fetch or return 0;
    $r->[0];
    } # SCALAR

sub drop
{
    my $self = shift;
    $self->{tmp} = 1;
    } # drop

sub DESTROY
{
    my $self = shift;
    my $dbh = $self->{dbh} or return;
    for (qw( sel ins upd del cnt ctv )) {
	$self->{$_} or next;
	$self->{$_}->finish;
	undef $self->{$_}; # DESTROY handle
	}
    if ($self->{tmp}) {
	$dbh->{AutoCommit} or $dbh->rollback;
	$dbh->do ("drop table ".$self->{tbl});
	$dbh->{AutoCommit} or $dbh->commit;
	}
    else {
	$dbh->{AutoCommit} or $dbh->commit;
	}
    $dbh->disconnect;
    undef $self->{dbh};
    } # DESTROY

1;

__END__

=head1 NAME

Tie::Hash::DBD - tie a plain hash to a database table

=head1 SYNOPSIS

  use DBI;
  use Tie::Hash::DBD;

  my $dbh = DBI->connect ("dbi:Pg:", ...);

  tie my %hash, "Tie::Hash::DBD", "dbi:SQLite:dbname=db.tie";
  tie my %hash, "Tie::Hash::DBD", $dbh;
  tie my %hash, "Tie::Hash::DBD", $dbh, {
      tbl => "t_tie_analysis",
      key => "h_key",
      fld => "h_value",
      str => "Storable",
      trh => 0,
      };

  $hash{key} = $value;  # INSERT
  $hash{key} = 3;       # UPDATE
  delete $hash{key};    # DELETE
  $value = $hash{key};  # SELECT
  %hash = ();           # CLEAR

=head1 DESCRIPTION

This module has been created to act as a drop-in replacement for modules
that tie straight perl hashes to disk, like C<DB_File>. When the running
system does not have enough memory to hold large hashes, and disk-tieing
won't work because there is not enough space, it works quite well to tie
the hash to a database, which preferable runs on a different server.

This module ties a hash to a database table using B<only> a C<key> and a
C<value> field. If no tables specification is passed, this will create a
temporary table with C<h_key> for the key field and a C<h_value> for the
value field.

I think it would make sense  to merge the functionality that this module
provides into C<Tie::DBI>.

=head1 tie

The tie call accepts two arguments:

=head2 Database

The first argument is the connection specifier.  This is either and open
database handle or a C<DBI_DSN> string.

If this argument is a valid handle, this module does not open a database
all by itself, but uses the connection provided in the handle.

If the first argument is a scalar, it is used as DSN for DBI->connect ().

Supported DBD drivers include DBD::Pg, DBD::SQLite, DBD::CSV, DBD::mysql,
DBD::Oracle, DBD::Unify, and DBD::Firebird.  Note that due to limitations
they won't all perform equally well. Firebird is not tested anymore.

DBD::Pg and DBD::SQLite have an unexpected great performance when server
is the local system. DBD::SQLite is even almost as fast as DB_File.

The current implementation appears to be extremely slow for CSV, as
expected, mysql, and Unify. For Unify and mysql that is because these do
not allow indexing on the key field so they cannot be set to be primary
key.

When using DBD::CSV with Text::CSV_XS version 1.02 or newer, it might be
wise to disable utf8 encoding (only supported as of DBD::CSV-0.48):

 "dbi:CSV:f_ext=.csv/r;csv_null=1;csv_decode_utf8=0"

=head2 Options

The second argument is optional and should - if passed - be a hashref to
options. The following options are recognized:

=over 2

=item tbl

Defines the name of the table to be used. If none is passed, a new table
is created with a unique name like C<t_tie_dbdh_42253_1>. When possible,
the table is created as I<temporary>. After the session, this table will
be dropped.

If a table name is provided, it will be checked for existence. If found,
it will be used with the specified C<key> and C<fld>.  Otherwise it will
be created with C<key> and C<fld>, but it will not be dropped at the end
of the session.

If a table name is provided, C<AutoCommit> will be "On" for persistence,
unless you provide a true C<trh> attribute.

=item key

Defines the name of the key field in the database table.  The default is
C<h_key>.

=item ktp

Defines the type of the key field in the database table.  The default is
depending on the underlying database. Probably unwise to change.

=item fld

Defines the name of the value field in the database table.   The default
is C<h_value>.

=item vtp

Defines the type of the fld field in the database table.  The default is
depending on the underlying database and most likely some kind of BLOB.

=item str

Defines the required persistence module. Currently only supports the use
of C<Storable>.  The default is undefined.  Passing unsupported streamer
module names will be silently ignored.

Note that C<Storable> does not support persistence of perl types C<CODE>, 
C<REGEXP>, C<IO>, C<FORMAT>, and C<GLOB>.

If you want to preserve Encoding on the hash values, you should use this
feature.

Also note that this module does not yet support dynamic deep structures.
See L</Nesting and deep structues>.

=item trh

Use transaction Handles. By default none of the operations is guarded by
transaction handling for speed reasons. Set C<trh> to a true value cause
all actions to be surrounded by  C<begin_work> and C<commit>.  Note that
this may have a big impact on speed.

=back

=head2 Encoding

C<Tie::Hash::DBD> stores keys and values as binary data. This means that
all Encoding and magic is lost when the data is stored, and thus is also
not available when the data is restored,  hence all internal information
about the data is also lost, which includes the C<UTF8> flag.

If you want to preserve the C<UTF8> flag you will need to store internal
flags and use the streamer option:

  tie my %hash, "Tie::Hash::DBD", { str => "Storable" };

If you do not want the performance impact of Storable just to be able to
store and retrieve UTF-8 values, there are two ways to do so:

  # Use utf-8 from database
  tie my %hash, "Tie::Hash::DBD", "dbi:Pg:", { vtp => "text" };
  $hash{foo} = "The teddybear costs \x{20ac} 45.95";

  # use Encode
  tie my %hash, "Tie::Hash::DBD", "dbi:Pg:";
  $hash{foo} = encode "UTF-8", "The teddybear costs \x{20ac} 45.95";

Note  that using Encode will allow other binary data too where using the
database encoding does not:

  $hash{foo} = pack "L>A*", time, encode "UTF-8", "Price: \x{20ac} 45.95";

=head2 Nesting and deep structures

C<Tie::Hash::DBD> stores keys and values as binary data. This means that
all structure is lost when the data is stored and not available when the
data is restored. To maintain deep structures, use the streamer option:

  tie my %hash, "Tie::Hash::DBD", { str => "Storable" };

Note that changes inside deep structures do not work. See L</TODO>.

=head1 METHODS

=head2 drop ()

If a table was used with persistence, the table will not be dropped when
the C<untie> is called.  Dropping can be forced using the C<drop> method
at any moment while the hash is tied:

  (tied %hash)->drop;

=head1 PREREQUISITES

The only real prerequisite is DBI but of course that uses the DBD driver
of your choice. Some drivers are (very) actively maintained.  Be sure to
to use recent Modules.  DBD::SQLite for example seems to require version
1.29 or up.

=head1 RESTRICTIONS and LIMITATIONS

=over 2

=item *

As Oracle does not allow BLOB, CLOB or LONG to be indexed or selected on,
the keys will be converted to ASCII for Oracle. The maximum length for a
converted key in Oracle is 4000 characters. The fact that the key has to
be converted to ASCII representation,  also excludes C<undef> as a valid
key value.

C<DBD::Oracle> limits the size of BLOB-reads to 4kb by default, which is
too small for reasonable data structures.  Tie::Hash::DBD locally raises
this value to 4Mb, which is still an arbitrary limit.

=item *

C<Storable> does not support persistence of perl types C<IO>, C<REGEXP>,
C<CODE>, C<FORMAT>, and C<GLOB>.  Future extensions might implement some
alternative streaming modules, like C<Data::Dump::Streamer> or use mixin
approaches that enable you to fit in your own.

=item *

Note that neither DBD::CSV nor DBD::Unify support C<AutoCommit>.

=item *

For now, Firebird does not support C<TEXT> (or C<CLOB>) in DBD::Firebird
at a level required by Tie::Hash::DBD. Neither does it support arbitrary
length index on C<VARCHAR> fields so it can neither be a primary key nor
can it be the subject of a (unique) index hence large sets will be slow.

Firebird support is stalled.

=back

=head1 TODO

=over 2

=item Update on deep changes

Currently,  nested structures do not get updated when it is an change in
a deeper part.

  tie my %hash, "Tie::Hash::DBD", $dbh, { str => "Storable" };

  $hash{deep} = {
      int  => 1,
      str  => "foo",
      };

  $hash{deep}{int}++; # No effect :(

=item Documentation

Better document what the implications are of storing  I<data> content in
a database and restoring that. It will not be fool proof.

=item Mixins

Maybe: implement a feature that would enable plugins or mixins to do the
streaming or preservation of other data attributes.

=back

=head1 AUTHOR

H.Merijn Brand <h.m.brand@xs4all.nl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2015 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

DBI, Tie::DBI, Tie::Hash, Tie::Array::DBD, Redis::Hash, DBM::Deep

=cut

":ex:se gw=72";
