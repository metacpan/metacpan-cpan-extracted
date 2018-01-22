#!/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Capture::Tiny ':all';
use File::Slurp qw{read_file};

use File::Temp;

use XS::Logger qw{:all};

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::XSLogger qw{:all};

my $log = XS::Logger->new();
is $log->get_level, 0, "default level is 0";

$log = XS::Logger->new( { level => 1 } );
is $log->get_level, 1, "can set the log level to a custom value";

$log->set_level(4);
is $log->get_level, 4, "level updated to 4";

is XS::Logger::DEBUG_LOG_LEVEL(), 0, "debug level is 0";
is XS::Logger::INFO_LOG_LEVEL(),  1, "info level is 1";
is XS::Logger::WARN_LOG_LEVEL(),  2, "warn level is 2";
is XS::Logger::ERROR_LOG_LEVEL(), 3, "error level is 3";
is XS::Logger::FATAL_LOG_LEVEL(), 4, "fatal level is 4";

is check_lines_for_level(undef), 5,
  "level=default: debug, info, warn, error, die";
is check_lines_for_level(DEBUG_LOG_LEVEL), 5,
  "level=DEBUG_LOG_LEVEL: debug, info, warn, error, die";

is check_lines_for_level(INFO_LOG_LEVEL), 4,
  "level=INFO_LOG_LEVEL: info, warn, error, die";

is check_lines_for_level(WARN_LOG_LEVEL), 3,
  "level=WARN_LOG_LEVEL: warn, error, die";

is check_lines_for_level(ERROR_LOG_LEVEL), 2,
  "level=ERROR_LOG_LEVEL: error, die";

is check_lines_for_level(FATAL_LOG_LEVEL), 1,
  "level=FATAL_LOG_LEVEL: fatal";

done_testing;
exit;

sub check_lines_for_level {
    my ($level) = @_;

    my $tmp = File::Temp->new(
        'DIR'      => '/tmp',
        'TEMPLATE' => 'xslogger-test.XXXXX'
    );
    local $XS::Logger::PATH_FILE = $tmp->filename();

    my $log;
    if ( defined $level ) {
        $log = XS::Logger->new( { level => $level } );
    }
    else {
        $log = XS::Logger->new();
    }

    # call all levels once
    $log->debug();
    $log->info();
    $log->warn();
    $log->error();

    #eval { $log->die };
    eval { $log->fatal };

    return count_lines($XS::Logger::PATH_FILE);
}
