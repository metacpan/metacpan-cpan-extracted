#!/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp;

use XS::Logger ();

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::XSLogger qw{:all};

my $tempfile = File::Temp->newdir( 'DIR' => '/tmp', 'TEMPLATE' => 'xslogger-test.XXXXX', UNLINK => 1 );
my $tmpdir = $tempfile->dirname();

ok -d $tmpdir, "got a tmpdir";

my $logfile = $tmpdir . '/first-test.log';    # q{/tmp/my-test};    # hard coded for now

note "Testing method calls";

foreach my $name (qw{first second}) {
    note "$name test";
    local $XS::Logger::PATH_FILE = $tmpdir . "/${name}-test.log";

    ok !-e $XS::Logger::PATH_FILE, "file does not exist before logging";
    XS::Logger::info("something");
    ok -e $XS::Logger::PATH_FILE, "file created after first log";

    is count_lines($XS::Logger::PATH_FILE), 1, "one single line logged";
    XS::Logger::info("something") for 1 .. 2;
    is count_lines($XS::Logger::PATH_FILE), 3, "three lines logged";
}

note "Testing object";

{
    note "Fallback to XS::Logger::PATH_FILE when no path specified";
    local $XS::Logger::PATH_FILE = $tmpdir . "/object-test.log";
    my $log = XS::Logger->new();

    ok !-e $XS::Logger::PATH_FILE, "file does not exist before logging";
    $log->info("something");
    ok -e $XS::Logger::PATH_FILE, "file created after first log";

    is count_lines($XS::Logger::PATH_FILE), 1, "one single line logged";
    $log->info("something") for 1 .. 2;
    is count_lines($XS::Logger::PATH_FILE), 3, "three lines logged";

}

{
    note "use custom path from constructor";

    local $XS::Logger::PATH_FILE = $tmpdir . "/unused.log";
    ok !-e $XS::Logger::PATH_FILE, "unused file does not exist";

    foreach my $id ( 1 .. 2 ) {
        my $logfile = $tmpdir . "/to-log-$id.txt";
        my $args = $id == 1 ? { logfile => $logfile } : { path => $logfile };

        my $log = XS::Logger->new($args);
        ok !-e $logfile, "logfile $id not created";

        $log->info("something");
        ok -e $logfile, "logfile $id created" or next;

        is count_lines($logfile), 1, "one single line logged";
        $log->info("something");
        is count_lines($logfile), 2, "two lines logged";
    }

    ok !-e $XS::Logger::PATH_FILE, "unused file does not exist";
}

done_testing;
