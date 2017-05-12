package t::Utils;
use strict;
use warnings;
use base qw/Exporter/;
use Test::More;
use DBI;
our @EXPORT = (@Test::More::EXPORT, 'run_test');

eval 'require DBD::SQLite';
plan skip_all => 'this test requires DBD::SQLite' if $@;
eval 'require File::Temp';
plan skip_all => 'this test requires File::Temp' if $@;

my $SCHEMA = join '', <DATA>;

sub run_test (&) {
    my $code = shift;
    my $tmp = File::Temp->new;
    $tmp->close();
    my $tmpf = $tmp->filename;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$tmpf", '', '', {RaiseError => 1}) or die $DBI::err;

    # work around for DBD::SQLite's resource leak
    tie my %blackhole, 't::Utils::Blackhole';
    $dbh->{CachedKids} = \%blackhole;

    my $schema = $SCHEMA;
    my $prefix = $::prefix || "";
    $schema =~ s/create\s+table\s+/CREATE TABLE $prefix/gi;

    do {
        $dbh->begin_work;
        for (split /;\s*/, $schema) {
            $dbh->do($_);
        }
        $dbh->commit;
    };

    $code->($dbh); # do test

    $dbh->disconnect;
}

{
    package t::Utils::Blackhole;
    use base qw/Tie::Hash/;
    sub TIEHASH { bless {}, shift }
    sub STORE { } # nop
    sub FETCH { } # nop
}

1;
__DATA__
CREATE TABLE funcmap (
        funcid         INTEGER PRIMARY KEY AUTOINCREMENT,
        funcname       VARCHAR(255) NOT NULL,
        UNIQUE(funcname)
);

CREATE TABLE job (
        jobid           INTEGER PRIMARY KEY AUTOINCREMENT,
        funcid          INTEGER UNSIGNED NOT NULL,
        arg             MEDIUMBLOB,
        uniqkey         VARCHAR(255) NULL,
        insert_time     INTEGER UNSIGNED,
        run_after       INTEGER UNSIGNED NOT NULL,
        grabbed_until   INTEGER UNSIGNED NOT NULL,
        priority        SMALLINT UNSIGNED,
        coalesce        VARCHAR(255),
        UNIQUE(funcid,uniqkey)
);

CREATE TABLE error (
        error_time      INTEGER UNSIGNED NOT NULL,
        jobid           INTEGER NOT NULL,
        message         VARCHAR(255) NOT NULL,
        funcid          INT UNSIGNED NOT NULL DEFAULT 0
);

CREATE TABLE exitstatus (
        jobid           INTEGER PRIMARY KEY NOT NULL,
        funcid          INT UNSIGNED NOT NULL DEFAULT 0,
        status          SMALLINT UNSIGNED,
        completion_time INTEGER UNSIGNED,
        delete_after    INTEGER UNSIGNED
);
