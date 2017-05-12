use strict;
use warnings FATAL => 'all';

package Test::TempDatabase;

our $VERSION = 0.16;
use DBI;
use DBD::Pg;
use POSIX qw(setuid);
use Carp;
use File::Slurp;

=head1 NAME

Test::TempDatabase - temporary database creation and destruction.

=head1 SYNOPSIS

  use Test::TempDatabase;
  
  my $td = Test::TempDatabase->create(dbname => 'temp_db');
  my $dbh = $td->handle;

  ... some tests ...
  # Test::TempDatabase drops database

=head1 DESCRIPTION

This module automates creation and dropping of test databases.

=head1 USAGE

Create test database using Test::TempDatabase->create. Use C<handle>
to get a handle to the database. Database will be automagically dropped
when Test::TempDatabase instance goes out of scope.

=cut
sub connect {
	my ($self, $db_name) = @_;
	my $cp = $self->connect_params;
	$db_name ||= $cp->{dbname};
	my $h = $cp->{cluster_dir} ? "host=$cp->{cluster_dir};" : "";
	my $dbi_args = $cp->{dbi_args} || { RaiseError => 1, AutoCommit => 1 };
	return DBI->connect("dbi:Pg:dbname=$db_name;$h" . ($cp->{rest} || ''),
				$cp->{username}, $cp->{password}, $dbi_args);
}

sub find_postgres_user {
	return $< if $<;

	my $uname = $ENV{TEST_TEMP_DB_USER} || $ENV{SUDO_USER} || "postgres";
	return getpwnam($uname);
}

=head2 $class->become_postgres_user

When running as root, this function becomes different user.
It decides on the user name by probing TEST_TEMP_DB_USER, SUDO_USER environment
variables. If these variables are empty, default "postgres" user is used.

=cut
sub become_postgres_user {
	my $class = shift;
	return if $<;

	my $p_uid = $class->find_postgres_user;
	my @pw = getpwuid($p_uid);

	carp("# $class\->become_postgres_user: setting $pw[0] uid\n");
	setuid($p_uid) or die "Unable to set $p_uid uid";
	$ENV{HOME} = $pw[ $#pw - 1 ];
}

sub create_db {
	my $self = shift;
	my $cp = $self->connect_params;
	my $dbh = $self->connect('template1');

	my $found = @{ $dbh->selectcol_arrayref(
			"select datname from pg_database where "
			. "datname = '$cp->{dbname}'") };

	my $drop_it = (!$cp->{no_drop} && $found);
	$self->drop_db if $drop_it;

	my $tn = $cp->{template} ? "template \"$cp->{template}\"" : "";
	$dbh->do("create database \"$cp->{dbname}\" $tn")
		if ($drop_it || !$found);
	$dbh->disconnect;
	$dbh = $self->connect($cp->{dbname});
	$self->{db_handle} = $dbh;

	if (my $schema = $cp->{schema}) {
		my $vs = $schema->new($dbh);
		$vs->run_updates;
		$self->{schema} = $vs;
	}
}

=head2 create

Creates temporary database. It will be dropped when the resulting
instance will go out of scope.

Arguments are passed in as a keyword-value pairs. Available keywords are:

dbname: the name of the temporary database.

rest: the rest of the database connection string.  It can be used to connect to
a different host, etc.

username, password: self-explanatory.

=cut
sub create {
	my ($class, %args) = @_;
	my $self = $class->new(\%args);
	$self->become_postgres_user;
	$self->create_db;
	return $self;
}

sub new {
	my ($class, $args) = @_;
	my $self = bless { connect_params => $args }, $class;
	$self->{pid} = $$;
	return $self;
}

sub _call_pg_cmd {
	my ($self, $cmd) = @_;
	my ($bdir) = (`pg_config | grep BINDIR` =~ /= (\S+)$/);
	$cmd = "$bdir/$cmd";
	$cmd = "su - postgres -c '$cmd'" unless $<;
	my $res = `$cmd 2>&1`;
	confess $res if $?;
}

sub create_cluster {
	my $self = shift;
	my $cdir = $self->{connect_params}->{cluster_dir};
	$self->_call_pg_cmd("initdb -D $cdir");
	append_file("$cdir/postgresql.conf"
		, "\nlisten_addresses = ''\nunix_socket_directory = '$cdir'\n");
}

sub start_server {
	my $self = shift;
	my $cdir = $self->{connect_params}->{cluster_dir};
	$self->_call_pg_cmd("pg_ctl -D $cdir -l $cdir/log start");

	sleep 1;
	for (1 .. 5) {
		my $log = read_file("$cdir/log");
		return if $log =~ /ready to accept/;
		sleep 1;
	}
	die "Server did not start " . read_file("$cdir/log");
}

sub stop_server {
	my $self = shift;
	my $cdir = $self->{connect_params}->{cluster_dir};
	$self->_call_pg_cmd("pg_ctl -D $cdir -m fast -l $cdir/log stop");
}

sub connect_params { return shift()->{connect_params}; }
sub handle { return shift()->{db_handle}; }

sub drop_db {
	my $self = shift;
	my $dn = $self->connect_params->{dbname};
	my @plines = `ps auxx | grep post | grep $dn | grep -v grep`;
	my $dbh = $self->connect('template1');
	for (@plines) {
		/\w\s+(\d+)/ or next;
		$dbh->do("select pg_terminate_backend($1)");
	}
	$dbh->do(q{ set client_min_messages to warning });
	$dbh->do("drop database if exists \"$dn\"");
	$dbh->disconnect;
	$self->{db_handle} = undef;
}

sub destroy {
	my $self = shift;
	return if $self->handle->{InactiveDestroy};
	$self->handle->disconnect;
	$self->{db_handle} = undef;
	return unless $self->{pid} == $$;
	return if $self->connect_params->{no_drop};
	$self->drop_db;
}

sub DESTROY {
	my $self = shift;
	$self->destroy if $self->handle;
}

sub dump_db {
	my ($self, $file) = @_;
	my $cp = $self->connect_params;
	my $h = $cp->{cluster_dir} ? "-h $cp->{cluster_dir}" : "";
	my $cmd = "pg_dump $h -O -c $cp->{dbname} > $file";
	system($cmd) and confess "Unable to do $cmd";
}

=head1 BUGS

* Works with PostgreSQL database currently.

=head1 AUTHOR

	Boris Sukholitko
	boriss@gmail.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Test::More

=cut

1; 
