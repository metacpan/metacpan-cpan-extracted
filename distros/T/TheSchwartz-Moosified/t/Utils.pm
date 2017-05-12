package t::Utils;
use strict;
use warnings;
use base qw/Exporter/;
use blib;
use Test::More;
use DBI;
our @EXPORT = (@Test::More::EXPORT, 'run_test');

eval 'require File::Temp';
plan skip_all => 'this test requires File::Temp' if $@;
if ($ENV{TSM_TEST_PG}) {
    plan skip_all => 'DBD::Pg support not working on windows yet'
        if $^O =~ /windows/i;
    eval 'require DBD::Pg';
    plan skip_all => 'this test requires DBD::Pg' if $@;
}
else {
    eval 'require DBD::SQLite';
    plan skip_all => 'this test requires DBD::SQLite' if $@;
}

our $dbcount = 0;

sub run_test (&) {
    my $code = shift;
    local $dbcount = $dbcount+1;
    local $@;

    my $tmp = File::Temp->new;
    $tmp->close();
    my $dbname;
    my $dbh;

    if ($ENV{TSM_TEST_PG}) {
        my $createdb = $ENV{PGCREATEDB} || 'createdb';
        $dbname = $ENV{PGDBPREFIX} || 'schwartz';
        $dbname .= $dbcount;

        my $diag = File::Temp->new(UNLINK => 1);
        my $rv = do {
            local %ENV = %ENV;
            delete $ENV{$_} for grep /^LC_/, keys %ENV;
            $ENV{LANG} = 'C';
            system("$createdb -E UTF-8 -l en_US.UTF-8 $dbname > $diag 2>&1");
        };
        if ($rv) {
            $diag->seek(0,0);
            my $txt = do {local $/; <$diag>};
            diag "createdb failed: $txt";
            diag "HINT: you can set the PGUSER env-var to control who to connect as";
            diag "HINT: you can set the PGCREATEDB/PGDROPDB env-vars to pick createdb/dropdb invocations to use";

            if ($txt =~ /authentication failed for user/) {
                diag "HINT: you may need to createuser or adjust pg_hba.conf";
            }
            elsif ($txt =~ /permission denied to create database/) {
                diag "HINT: user needs create database permissions (the -d flag for createuser)";
            }
            elsif ($txt =~ /database "\Q$dbname\E" already exists/) {
                diag "HINT: you may need to drop '$dbname' manually";
            }

            die "SETUP: can't set up postgres database '$dbname'";
        }

        $dbh = DBI->connect("dbi:Pg:database=$dbname", '', '', {
            AutoCommit => 1,
            RaiseError => 1,
            PrintError => 0,
        }) or die "SETUP: $DBI::errstr";
    }
    else {
        $dbname = $tmp->filename;
        $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", '', '', {
            RaiseError => 1,
            PrintError => 0,
        }) or die $DBI::errstr;

        # work around for DBD::SQLite's resource leak
        tie my %blackhole, 't::Utils::Blackhole';
        $dbh->{CachedKids} = \%blackhole;
    }

    init_schwartz($dbh);

    eval {
        $code->($dbh); # do test
    };
    my $e = $@ if $@;

    eval {
        $dbh->disconnect;

        if ($ENV{TSM_TEST_PG}) {
            my $dropdb = $ENV{PGDROPDB} || 'dropdb';
            system("$dropdb -e $dbname") and die "can't dropdb $dbname";
        }
    };
    if ($@) {
        diag "while disconnecting/dropping: $@";
    }

    if ($e) {
        $@ = $e;
        die $@;
    }
}

sub init_schwartz {
    my $dbh = shift;
    my $name = $dbh->{Driver}{Name};

    my $schemafile = "schema/$name.sql";
    my $schema = do { local(@ARGV,$/)=$schemafile; <> };
    die "Schmema not found" unless $schema;
    my $prefix = $::prefix || "";
    $schema =~ s/PREFIX_/$prefix/g;

    do {
        $dbh->begin_work;
        for (split /;\s*/m, $schema) {
            $dbh->do($_);
        }
        $dbh->commit;
    };
}

{
    package t::Utils::Blackhole;
    use base qw/Tie::Hash/;
    sub TIEHASH { bless {}, shift }
    sub STORE { } # nop
    sub FETCH { } # nop
}

1;
