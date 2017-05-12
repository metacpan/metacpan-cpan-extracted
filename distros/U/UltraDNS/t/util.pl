# util functions for tests

use strict;
use warnings;
use Data::Dumper;
use Test::More;

my @at_end; # closures to cal at END to clean up


sub test_zone_name {
    return 'perl--ultradns--test.com.';
}


sub test_connect_args {
    my ($verbose) = @_;

    my $env = $ENV{ULTRADNS_CONNECT_ARGS} or do {
        warn "Set the ULTRADNS_CONNECT_ARGS env var to 'host.domain:port|sponsor|username|password'\n";
        pass(); # to keep Test::More happy
        exit 0;
    };

    my ($host_and_port, $sponsor, $username, $password) = split /\|/, $env, 4;

    warn "Connecting to $host_and_port as '$username' ($sponsor)\n"
        if $verbose;

    return ($host_and_port, $sponsor, $username, $password);
}


sub test_connect {
    my ($attr) = @_;
    require UltraDNS;
    return UltraDNS->connect(test_connect_args(), $attr)
}


sub delete_test_zone {
    my ($udns) = @_;
    my $zone = test_zone_name();
    $udns->do( $udns->DeleteZone($zone) );
}

sub create_test_zone {
    my ($udns) = @_;
    my $zone = test_zone_name();

    # delete it first just in case there's an old one lying around
    eval { delete_test_zone($udns) };

    # create a shiny new one
    $udns->do( $udns->CreatePrimaryZone($zone) );

    # try hard to ensure it gets deleted (quietly) when we exit
    push @at_end, sub {
	$udns->trace(0);
	$udns->rollback;
	delete_test_zone($udns);
    };

    # return handy info for tests to use
    (my $domain = $zone) =~ s/\.$//;
    return  $zone unless wantarray;
    return ($zone, $domain);
}

END {
    local ($@, $!);
    eval { $_->(); 1 } or warn $@ for @at_end;
}

