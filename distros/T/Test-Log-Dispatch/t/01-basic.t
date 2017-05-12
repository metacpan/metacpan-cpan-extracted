#!perl
use Test::Tester tests => 57;
use Test::More;
use Test::Log::Dispatch;
use strict;
use warnings;

my $test_name = 'dummy test name';

sub passed (&;$) {
    my ( $code, $name ) = @_;

    check_test( $code, { ok => 1, name => $test_name }, $name );
}

sub failed (&;$) {
    my ( $code, $name ) = @_;

    check_test( $code, { ok => 0, name => $test_name }, $name );
}

my $log = Test::Log::Dispatch->new();
$log->debug('good log message');
passed { $log->contains_ok( qr/good log message/, $test_name ) }
'contains_ok passed';
failed { $log->contains_ok( qr/unexpected log message/, $test_name ) }
'contains_ok fail';
passed { $log->empty_ok($test_name) } 'empty_ok pass';

$log->debug('good log message');
failed { $log->does_not_contain_ok( qr/good log message/, $test_name ) }
'does_not_contain_ok fail';
passed { $log->does_not_contain_ok( qr/unexpected log message/, $test_name ) }
'does_not_contain_ok pass';
failed { $log->empty_ok($test_name) } 'empty_ok fail';
passed { $log->empty_ok($test_name) }
'log is cleared after empty_ok fail; empty_ok pass';
$log->clear();

$log->error('good log message');
passed { $log->contains_only_ok( qr/good log message/, $test_name ) }
'contains_only_ok pass';
$log->error('good log message');
$log->error('another log message');
failed { $log->contains_only_ok( qr/good log message/, $test_name ) }
'contains_only_ok fail';
$log->clear();

$log->debug('log 1');
$log->warning('log 2');
$log->error('log 3');
$log->error('log 2');
is( join( ", ", map { $_->{message} } @{ $log->msgs } ),
    "log 1, log 2, log 3, log 2" );
$log->contains_ok(qr/log 2/);
is( join( ", ", map { $_->{message} } @{ $log->msgs } ),
    "log 1, log 3, log 2" );
