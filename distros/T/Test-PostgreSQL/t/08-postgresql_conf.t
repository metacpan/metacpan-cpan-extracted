use Test::More;

use strict;
use warnings;

use DBI;
use File::Spec;
use Test::PostgreSQL;
use Try::Tiny;

my $pg = try { Test::PostgreSQL->new() }
         catch { plan skip_all => $_ };

plan tests => 8;

ok defined($pg), "test instance 1 created";

my $datadir = File::Spec->catfile($pg->base_dir, 'data');
my $conf_file = File::Spec->catfile($datadir, 'postgresql.conf');

my $ver_cmd = join' ', (
    $pg->postmaster,
    '--version'
);

my ($ver) = qx{$ver_cmd} =~ /(\d+(?:\.\d+)?)/;

# By default postgresql.conf is truncated
is -s $conf_file, 0, "test 1 postgresql.conf size 0";

SKIP: {
    skip "No -C switch on PostgreSQL $ver (9.2 required)", 1 if $ver < 9.2;
    my $cmd = join ' ', (
        $pg->postmaster,
        '-D', $datadir,
        '-C', 'synchronous_commit'
    );

    my $config_value = qx{$cmd};

    # Default for synchronous_commit is on
    like $config_value, qr/^on/, "test 1 synchronous_commit = on";
}

my @pids = ($pg->pid);

undef $pg;

$pg = Test::PostgreSQL->new(
    pg_config => q|# foo baroo mymse throbbozongo
fsync = off
synchronous_commit = off
full_page_writes = off
bgwriter_lru_maxpages = 0
shared_buffers = 512MB
effective_cache_size = 512MB
work_mem = 100MB
|);

ok defined($pg), "test instance 2 created";

my $dsn = $pg->dsn;
my $dbh = DBI->connect($dsn, undef, undef, { PrintError => !1 });

# Means config was correct
ok defined($dbh), "test instance 2 connected";

$datadir = File::Spec->catfile($pg->base_dir, 'data');
$conf_file = File::Spec->catfile($datadir, 'postgresql.conf');

SKIP: {
    skip "No -C switch on PostgreSQL $ver (9.2 required)", 1 if $ver < 9.2;
    my $cmd = join ' ', (
        $pg->postmaster,
        '-D', $datadir,
        '-C', 'synchronous_commit'
    );

    my $config_value = qx{$cmd};

    # Now it should be off (overridden above)
    like $config_value, qr/^off/, "test 2 synchronous_commit = off";
}

open my $fh, '<', $conf_file;
my $pg_conf = join '', <$fh>;
close $fh;

like $pg_conf, qr/foo baroo mymse throbbozongo/,
    "test instance 2 postgresql.conf match";

push @pids, $pg->pid;

undef $pg;

my $watchdog = 50;

while ( kill 0, @pids and $watchdog-- ) {
    select undef, undef, undef, 0.1;
}

ok !kill(0, @pids), "test Postgres instances stopped";
