#!/usr/bin/perl
# lib/db_migrate.pl -- schema update, by historisation or in place (the
# fork-integration plan, annexe D, steps S51b and S51c). A thin CLI over
# oEdtk::DBAdmin.
#
# Modes:
#   --check-only   detect the schema level and print the plan; NOTHING is written
#   --dry-run      like --check-only, plus the copy SQL and a DDL preview
#   --historize    build a T target, copy by named columns, validate, switch
#                  over and KEEP the old schema as history (recommended); a base
#                  already at T is a no-op unless --force is given
#   --revert       undo a --historize run before resuming the service
#   --additive     in-place additive update (S51c): ADD COLUMN, widening and
#                  CREATE ... IF NOT EXISTS only -- never a DROP, a narrowing or a
#                  rename; --with-constraints also changes the key (after a
#                  duplicate pre-check)
#
# --historize never modifies the service schema in place and never drops. It is
# the recommended procedure when the key or the types change. --additive is
# strictly monotone and is suited to the cases without a key change.
#
# Usage:
#   perl lib/db_migrate.pl --check-only --dsn <dsn> [--user U] [--pass P]
#   perl lib/db_migrate.pl --dry-run    --dsn <dsn>
#   perl lib/db_migrate.pl --historize  --dsn <dsn> [--stamp YYYYMMDD_HHMMSS]
#   perl lib/db_migrate.pl --revert     --dsn <dsn> --stamp YYYYMMDD_HHMMSS
#   perl lib/db_migrate.pl --additive   --dsn <dsn> [--with-constraints]
#
# READ-ONLY for --check-only / --dry-run. The password is never printed.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";
use DBI;
use Getopt::Long qw(GetOptions);

use oEdtk::DBAdmin qw(
	schema_MigrationPlan
	schema_Historize
	schema_Revert
	schema_Additive
	schema_Report
);

sub usage {
	print STDERR "usage: $0 <mode> --dsn <dsn> [--user U] [--pass P]\n"
		. "  modes: --check-only | --dry-run | --historize [--force] | --revert --stamp S"
		. " | --additive [--with-constraints]\n";
	exit 1;
}

sub mask_dsn {
	my ($dsn) = @_;
	$dsn =~ s/(pass(word)?=)[^;]*/$1***/gi;
	return $dsn;
}

my ( $dsn, $user, $pass, $stamp );
my ( $check, $dry, $historize, $revert, $additive, $force, $with_constraints );
GetOptions(
	'dsn=s'            => \$dsn,
	'user=s'           => \$user,
	'pass=s'           => \$pass,
	'stamp=s'          => \$stamp,
	'check-only'       => \$check,
	'dry-run'          => \$dry,
	'historize'        => \$historize,
	'revert'           => \$revert,
	'additive'         => \$additive,
	'force'            => \$force,
	'with-constraints' => \$with_constraints,
) or usage();

my @modes = grep { $_ } ( $check, $dry, $historize, $revert, $additive );
usage() unless @modes == 1;
usage() unless defined $dsn;

my $dbh = DBI->connect( $dsn, $user, $pass, { RaiseError => 1, PrintError => 0, AutoCommit => 1 } )
	or die "db_migrate: cannot connect to " . mask_dsn($dsn) . ": $DBI::errstr\n";

if ( $check || $dry ) {
	my $plan = schema_MigrationPlan( $dbh, ( defined $stamp ? ( stamp => $stamp ) : () ) );
	print join( "\n", @{ $plan->{report} } ), "\n";
	if ($dry) {
		print "\n-- copy statements --\n";
		print "  $_;\n" for @{ $plan->{copy_sql} };
		my @ddl = sort map { $_->{ddl} } values %{ $plan->{model} };
		print "\n-- target DDL (as generated for SQLite; illustrative) --\n";
		print "  $_;\n" for grep { defined } @ddl;
	}
	$dbh->disconnect;
	exit 0;
}

if ($additive) {
	my $res = schema_Additive(
		$dbh,
		( $force            ? ( force            => 1 ) : () ),
		( $with_constraints ? ( with_constraints => 1 ) : () )
	);
	if ( $res->{noop} ) {
		print "db_migrate: already at T, nothing to add or widen.\n";
		$dbh->disconnect;
		exit 0;
	}
	if ( $res->{ok} ) {
		printf
"db_migrate: additive update %s -> T: %d table(s) created, %d column(s) added, %d widened\n",
			$res->{from},
			scalar @{ $res->{created} },
			scalar( map { @$_ } values %{ $res->{added} } ),
			scalar( map { @$_ } values %{ $res->{widened} } );
		print "  unresolved: $_\n" for @{ $res->{violations} };
		$dbh->disconnect;
		exit 0;
	}
	print STDERR "db_migrate: additive update aborted; schema unchanged: $res->{error}\n";
	$dbh->disconnect;
	exit 1;
}

if ($historize) {
	my $res = schema_Historize(
		$dbh,
		( defined $stamp ? ( stamp => $stamp ) : () ),
		( $force         ? ( force => 1 )      : () )
	);
	if ( $res->{noop} ) {
		print "db_migrate: already at T, nothing to do (use --force to re-historise).\n";
		$dbh->disconnect;
		exit 0;
	}
	if ( $res->{ok} ) {
		printf "db_migrate: historised %s -> T, stamp %s, %d table(s) kept as history\n",
			$res->{from}, $res->{stamp}, scalar @{ $res->{renamed} };
		print "  rows: ", join( ' ', map { "$_=$res->{rows}{$_}" } sort keys %{ $res->{rows} } ),
			"\n";
		$dbh->disconnect;
		exit 0;
	}
	print STDERR "db_migrate: historisation aborted; service schema untouched: $res->{error}\n";
	$dbh->disconnect;
	exit 1;
}

# --revert
usage() unless defined $stamp;
my $res = schema_Revert( $dbh, stamp => $stamp );
if ( $res->{ok} ) {
	printf "db_migrate: reverted %d table(s) from stamp %s\n",
		scalar @{ $res->{reverted} }, $res->{stamp};
	$dbh->disconnect;
	exit 0;
}
print STDERR "db_migrate: revert aborted: $res->{error}\n";
$dbh->disconnect;
exit 1;
