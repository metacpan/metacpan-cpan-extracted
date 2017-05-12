# Test cookies handling

package test::class;

use strict;

use RPC::ExtDirect  Action  => 'test',
                    before => \&before_hook;
use RPC::ExtDirect::Event;

my %cookies;

sub before_hook {
    my ($class, %params) = @_;

    my $env = $params{env};

    %cookies = map { $_ => $env->cookie($_) } $env->cookie;

    return 1;
}

sub ordered : ExtDirect(0) {
    my $ret  = { %cookies };
    %cookies = ();

    return $ret;
}

sub form : ExtDirect(formHandler) {
    my $ret  = { %cookies };
    %cookies = ();

    return $ret;
}

sub poll : ExtDirect(pollHandler) {
    return RPC::ExtDirect::Event->new('cookies', { %cookies });
}

package main;

use strict;
use warnings;
no  warnings 'uninitialized';

use Test::More tests => 3;

use Test::ExtDirect;

my $expected_data = {
    foo => 'bar',
    bar => 'baz',
};

my $expected_event = {
    name => 'cookies',
    data => $expected_data,
};

my $data = call_extdirect(
    action  => 'test',
    method  => 'ordered',
    cookies => $expected_data,
);

is_deeply $data, $expected_data, "Ordered"
    or diag explain $data;

$data = submit_extdirect(
    action  => 'test',
    method  => 'form',
    arg     => {},
    cookies => $expected_data,
);

is_deeply $data, $expected_data, "Form submit"
    or diag explain $data;

my $event = poll_extdirect(cookies => $expected_data);

is_deeply $event, $expected_event, "Event poll"
    or diag explain $data;

