#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAHC qw/yahc_conn_target/;

my ($yahc, $yahc_storage) = YAHC->new({ host => [ '127.0.0.1', '127.0.0.2' ] });
my $conn = $yahc->request({ path => '/', _test => 1 });

YAHC::_get_next_target($conn);
ok(yahc_conn_target($conn) eq '127.0.0.1', 'target is 127.0.0.1');
YAHC::_get_next_target($conn);
ok(yahc_conn_target($conn) eq '127.0.0.2', 'target is 127.0.0.2');

$conn = $yahc->request({ host => '127.0.0.3', path => '/', _test => 1 });

YAHC::_get_next_target($conn);
ok(yahc_conn_target($conn) eq '127.0.0.3', 'target is 127.0.0.3');

($yahc, $yahc_storage) = YAHC->new({ host => sub { '127.0.0.4' } });
$conn = $yahc->request({ path => '/', _test => 1 });

YAHC::_get_next_target($conn);
ok(yahc_conn_target($conn) eq '127.0.0.4', 'target is 127.0.0.4');

done_testing;
