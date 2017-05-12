#!/usr/bin/perl

use strict;
use warnings;

use Benchmark 'timethis';
use JSON;
use Sys::Hostname;
use File::Path 'mkpath';

use Text::Tradition;
use Text::Tradition::Directory;
use Test::More;
use Test::Memory::Cycle;

## Don't run this test when running make test or prove, to run it use perl -Ilib t/load-save-speed.t

if($ENV{HARNESS_ACTIVE}) {
    plan skip_all => 'Skipping performance tests under prove/make, run manually to test performance improvements';
} else {
    plan 'no_plan';
}

## Using t/data/besoin.xml  / t/data/besoin.dot as a large test example:
my $test_name = 'besoin';
# my $test_name = 'simple';

## Data file for repeated benchmarks:
my $benchmark_file = 't/data/load-save-benchmark.json';

## SQL file (previously dumped KiokuDB) for testing tradition directory loading:
# my $load_sql = 't/data/speed_test_load.sql';

## uuid to load from the above stored db:
my $load_uuid = 'load-test';

## Pass the git hash to identify this performance improvement, if you
## want to save the results of this run. Pass nothing to just run a test
## of the current code against the previous best.
my $git_hash = shift;

if($git_hash) {
    diag "Will save results using $git_hash as a key";
} else {
    diag "No git hash passed in, just running test";
}

## Setup
mkpath('t/var') if(!-d 't/var');

my $tradition = Text::Tradition->new(
   'input' => 'Self',
   'file'  => "t/data/${test_name}.xml"
    ## smaller for testing the test!
#    'input' => 'Tabular',
#    'file' => 't/data/simple.txt',
);
#$tradition->add_stemma(dotfile => "t/data/${test_name}.dot");

#my $fh = File::Temp->new();
#my $file = $fh->filename;
#$fh->close;
## use t/var so you can look at the results after if neccessary:

#my $load_db = 't/var/speed_test_load.db';
#unlink($load_db) if(-e $load_db);
#my $load_dsn = "dbi:SQLite:dbname=$load_db";
## Prime db from .sql file:
## ?? fails

#`sqlite3 $load_db < $load_sql`;

my $save_db = 't/var/speed_test_save.db';
unlink($save_db) if(-e $save_db);
my $save_dsn = "dbi:SQLite:dbname=${save_db}";

my $benchmark_data = load_benchmark($benchmark_file);

my $test_save = sub {
    unlink($save_db) if(-e $save_db);

    my $dir = Text::Tradition::Directory->new(
        dsn => $save_dsn,
        extra_args => { create => 1 },
    );
    ## This seems to be a required magic incantation:
    my $scope = $dir->new_scope;

    ## save the tradition (with stemma) to the db:
    $dir->save($load_uuid => $tradition);
#    print STDERR "UUID: $uuid\n";

};

my $test_load = sub {
    my $dir = Text::Tradition::Directory->new(
        dsn => $save_dsn,
    );

    ## This seems to be a required magic incantation:
    my $scope = $dir->new_scope;
    my $t = $dir->tradition($load_uuid);
    return $t;
#    print STDERR $load_tradition->name, $tradition->name, "\n";
};

## Find most recent benchmark info on this hostname
my ($last_benchmark) = grep { $_->{host} eq hostname() } (reverse @{$benchmark_data}); 

if(!$last_benchmark) {
    diag "Can't find last benchmark for " . hostname() . ", starting again";
    $last_benchmark = fresh_benchmark();
}


# Benchmark current code:
# Should probably run the test the same number of times as the last time it ran
# Or compare results more sanely
my $new_save_result = timethis(5, $test_save);

my $new_save = $new_save_result->[1] + $new_save_result->[2];
#use Data::Dump;

my $old_save = $last_benchmark->{save_times}[1] + $last_benchmark->{save_times}[2];
ok( $new_save < $old_save, "Saving to a Tradition Directory got faster: $new_save vs $old_save");

my $new_load_result = timethis(5, $test_load);

my $new_load = $new_load_result->[1] + $new_load_result->[2];
my $old_load = $last_benchmark->{load_times}[1] + $last_benchmark->{load_times}[2];
ok($new_load < $old_load, "Loading from a Tradition Directory got faster: $new_load vs $old_load");

my $load_tradition = $test_load->();
isa_ok($load_tradition, 'Text::Tradition');
ok($load_tradition->collation->as_svg());

if($git_hash) {
    push(@{ $benchmark_data }, {
        git_hash => $git_hash,
        host => hostname(),
        load_times => [@$new_load_result],
        save_times => [@$new_save_result],
    });

    save_benchmark($benchmark_file, $benchmark_data);
}

# -----------------------------------------------------------------------------

sub load_benchmark {
    my ($filename) = @_;

    my $loaded_data = [];
    if(-e $filename) {
        local $/;
        open( my $fh, '<', $filename ) || die "$!";
        my $json_text   = <$fh>;
        $fh->close();
        $loaded_data = decode_json( $json_text );
    } else {
        ## bare bones default table:
        $loaded_data = fresh_benchmark();
    }

    return $loaded_data;
}

sub fresh_benchmark {
    return {
             git_hash => '',
             host => hostname(),
             load_times => [1000, 1000, 1000, 0, 0, 5],
             save_times => [1000, 1000, 1000, 0, 0, 20],
         }
}

sub save_benchmark {
    my ($filename, $new_benchmarks) = @_;

    my $json_text = JSON->new->utf8->allow_blessed->encode($new_benchmarks);

    open(my $fh, '>', $filename) || die "$!";
    $fh->print($json_text);
    $fh->close();
}
