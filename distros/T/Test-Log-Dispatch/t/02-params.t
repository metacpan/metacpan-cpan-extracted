#!perl
use Test::More tests => 3;
use Test::Log::Dispatch;
use strict;
use warnings;

# Any parameters will be forwarded to the Log::Dispatch::Array constructor.
#
my $log = Test::Log::Dispatch->new( min_level => 'warning' );
$log->debug('debug message');
$log->info('info message');
$log->warning('warning message');
$log->error('error message');

$log->contains_ok(qr/warning message/);
$log->contains_ok(qr/error message/);
$log->empty_ok();
