#!/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Capture::Tiny ':all';
use File::Slurp qw{read_file};

use File::Temp;

use XS::Logger ();

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::XSLogger qw{:all};

my $tempfile = File::Temp->newdir( 'DIR' => '/tmp', 'TEMPLATE' => 'xslogger-test.XXXXX', UNLINK => 1 );
my $tmpdir = $tempfile->dirname();

ok -d $tmpdir, "got a tmpdir";

my $logfile;

# make sure holy() is in the current namespace
{
    note "Testing function calls XS::Logger::*something*()";

    $logfile = $XS::Logger::PATH_FILE = $tmpdir . '/first-test.log';    # // default_value

    XS::Logger::info();
    logfile_last_line_like( $logfile, level => 'INFO', color => 0, msg => '', test => 'info without args' );

    XS::Logger::info("a simple information");
    logfile_last_line_like( $logfile, level => 'INFO', color => 0, msg => 'a simple information' );

    XS::Logger::info( "something to eat - %s %s", "cherry", "pie" );
    logfile_last_line_like( $logfile, level => 'INFO', color => 0, msg => 'something to eat - cherry pie' );

    foreach my $level (qw{info warn error die panic fatal debug}) {
        my $expect_level = uc($level);
        $expect_level = 'ERROR' if $level eq 'die';     # FIXME maybe to change
        $expect_level = 'FATAL' if $level eq 'panic';

        my $ok = eval qq{XS::Logger::$level(); 1};
        if ( grep { $_ eq $level } qw{die panic fatal} ) {
            ok !$ok, "$level should die";
        }
        else {
            ok $ok, "$level do not die";
        }

        logfile_last_line_like( $logfile, level => $expect_level, color => 0, msg => '' );

        my $msg = "my $level message";
        $ok = eval qq{XS::Logger::${level}('${msg}'); 1};
        if ( grep { $_ eq $level } qw{die panic fatal} ) {
            ok !$ok, "$level should die";
        }
        else {
            ok $ok, "$level do not die";
        }

        logfile_last_line_like( $logfile, level => $expect_level, color => 0, msg => $msg );
    }
}

{
    note "Testing object XS::Logger->new->log_something";

    my $logger = XS::Logger->new( { color => 0 } );

    $logfile = $XS::Logger::PATH_FILE = $tmpdir . '/second-test.log';    # // default_value

    ok eval  { $logger->info();  1 };
    ok eval  { $logger->warn();  1 };
    ok eval  { $logger->error(); 1 };
    ok !eval { $logger->die();   1 };
    ok !eval { $logger->panic(); 1 };
    ok !eval { $logger->fatal(); 1 };
    ok eval  { $logger->debug(); 1 };

    foreach my $level (qw{info warn error die panic fatal debug}) {
        my $expect_level = uc($level);
        $expect_level = 'ERROR' if $level eq 'die';                      # FIXME maybe to change
        $expect_level = 'FATAL' if $level eq 'panic';

        my $ok = eval { $logger->can($level)->(); 1 };
        if ( grep { $_ eq $level } qw{die panic fatal} ) {
            ok !$ok, "$level should die";
        }
        else {
            ok $ok, "$level do not die";
        }

        logfile_last_line_like( $logfile, level => $expect_level, color => 0, msg => '' );

        my $msg = "this is a BW $level message";
        $ok = eval { $logger->can($level)->($msg); 1 };
        if ( grep { $_ eq $level } qw{die panic fatal} ) {
            ok !$ok, "$level should die";
        }
        else {
            ok $ok, "$level do not die";
        }

        logfile_last_line_like( $logfile, level => $expect_level, color => 0, msg => $msg );
    }

}

{
    $logfile = $tmpdir . '/custom-path.log';
    my $logger = XS::Logger->new( { color => 1, logfile => $logfile } );

    $logger->info("one info no newline");
    like get_logfile_last_line($logfile), qr{one info no newline\n$}, "one info no newline";

    $logger->info("one info with newline\n");
    like get_logfile_last_line($logfile), qr{one info with newline\n$}, "one info with newline";

    $logger->warn( "a warning with integer '%d'", 42 );
    logfile_last_line_like( $logfile, level => 'WARN', color => 1, msg => "a warning with integer '42'" );

    foreach my $level (qw{info warn error die panic fatal debug}) {
        my $expect_level = uc($level);
        $expect_level = 'ERROR' if $level eq 'die';     # FIXME maybe to change
        $expect_level = 'FATAL' if $level eq 'panic';

        my $msg = "this is a colored $level message";
        my $ok = eval { $logger->can($level)->( $logger, $msg ); 1 };
        if ( grep { $_ eq $level } qw{die panic fatal} ) {
            ok !$ok, "$level should die";
        }
        else {
            ok $ok, "$level do not die";
        }

        logfile_last_line_like( $logfile, level => $expect_level, color => 1, msg => $msg );
    }

    $logger->debug( "my debug message %s", "whatever" );
    logfile_last_line_like( $logfile, level => 'DEBUG', color => 1, msg => "my debug message whatever" );

    $logger->info( "one %d two %d three %d", 1, 2, 3 );
    logfile_last_line_like( $logfile, level => 'INFO', color => 1, msg => "one 1 two 2 three 3" );

    $logger->info( "d %d, s %s, d %d, s %s", -42, "banana", 404, "apple" );
    logfile_last_line_like( $logfile, level => 'INFO', color => 1, msg => "d -42, s banana, d 404, s apple" );

    todo "Floating numbers not implemented correctly" => sub {
        $logger->info( "decimal '%f'", 1.56789 );
        logfile_last_line_like( $logfile, level => 'INFO', color => 1, msg => "decimal '1.56789'" );
    };

    foreach my $max ( 1 .. 10 ) {
        ok eval { $logger->debug( "$max + 1 parameters || " . ( "%d, " x $max ), ( 1 .. $max ) ); 1 }, "should not fail with $max + 1 argument";

        my $end = sprintf( "%d, " x $max, 1 .. $max );
        like get_logfile_last_line($logfile), qr{|| $end\n$}, "$end";
    }

    foreach my $max ( 11 .. 15 ) {
        my $ok = eval { $logger->debug( "$max parameters " . ( "%d, " x $max ), 1 .. $max ); 1 } || 0;
        my $error = $@;
        is( $ok, 0, "dies with $max +1 argument" );
        like $error, qr{^Too many args to the caller};
    }

    $logger->info(1234);
    logfile_last_line_like( $logfile, level => 'INFO', color => 1, msg => "1234", test => "info using an integer instead of format 1234" );
}

done_testing;    # safe with Test2
