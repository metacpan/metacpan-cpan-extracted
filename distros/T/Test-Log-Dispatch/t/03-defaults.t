#!perl
use Test::Tester tests => 4;
use Test::More;
use Test::Log::Dispatch;
use strict;
use warnings;

sub check_name (&;$$) {
    my ( $code, $name_regex, $test_name ) = @_;

    my ( $premature, @results ) = run_tests($code);
    like( $results[0]->{name}, $name_regex, $test_name );
}

my $log = Test::Log::Dispatch->new();
check_name { $log->contains_ok(qr/foo/) } qr/log contains .*foo/, 'contains_ok';
check_name { $log->does_not_contain_ok(qr/foo/) }
qr/log does not contain .*foo/, 'does_not_contain_ok';
check_name { $log->empty_ok() } qr/log is empty/, 'empty_ok';
check_name { $log->contains_only_ok(qr/foo/) } qr/log contains only .*foo/,
  'contains_only_ok';
