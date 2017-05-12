#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use_ok( 'Test::Ping');

my @subclasses = qw(
    BIND
    PORT
    PROTO
    HIRES
    TIMEOUT
    SOURCE_VERIFY
    SERVICE_CHECK
);

my %subclasses_tests = (
    # subclass => [ default value, new value ]
    PORT  => [ 7, 8 ],
    PROTO => [ 'tcp', 'udp' ],
    HIRES => [ 1, 3 ],
    TIMEOUT => [ 5, 10 ],
    SOURCE_VERIFY => [ 1, 0 ],
    SERVICE_CHECK => [ undef, 1 ],
);

my $ping = Net::Ping->new;

for my $subclass (@subclasses) {
    my $module_name = "Test::Ping::Ties::$subclass";
    use_ok( $module_name );

    my $obj = $module_name->TIESCALAR;
    isa_ok( $obj, $module_name, 'TIESCALAR object' );

    if ($subclass eq 'BIND'){
        my $warn;
        local $SIG{__WARN__} = sub { $warn = shift; };
        my $ret = $obj->STORE( 'localhost' );
        is ($ret, 1, "$module_name STORE works");
        $obj->FETCH;
        like ($warn, qr/Usage:/, "$module_name FETCH works");
    } elsif ( my $data = $subclasses_tests{$subclass} ) {
        my $ret = $obj->FETCH;
        is ($ret, $data->[0], "$module_name FETCH works");
        $obj->STORE( $data->[1] );
        $ret = $obj->FETCH;
        is ($ret, $data->[1], "$module_name STORE works");
    } else {
        BAIL_OUT("Odd class called in test (this shouldn't happen): $subclass");
    }
}

done_testing();
