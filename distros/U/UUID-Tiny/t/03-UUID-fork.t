#!perl -T

use strict;
use warnings;
use Test::More;
use Carp;

use UUID::Tiny qw(:std);

if ($^O eq 'MSWin32') {
    plan skip_all => 'Pipe-open not supported on MSWin32';
}
else {
	plan tests => 6
}

my %uuid;

my $first_time_uuid = create_uuid_as_string(UUID_TIME);
my $first_rand_uuid = create_uuid_as_string(UUID_RANDOM);

use IO::Handle;
if (my $pid = open my $child, "-|") {
    my $child_data;

    # Check uniqueness of time based UUIDs ...
    chomp($child_data = <$child>);
    my $time_uuid = create_uuid_as_string(UUID_TIME);
    ok(
        !equal_uuids($first_time_uuid, $time_uuid),
        'First time based UUID differs from parent one.'
    );
    ok(
        !equal_uuids($child_data, $time_uuid),
        'Time based UUIDs of parent and child differ.'
    );
    
    # Check integrity of parent clock sequence ...
    ok(
        (
            time_of_uuid($first_time_uuid) < time_of_uuid($time_uuid)
            && clk_seq_of_uuid($first_time_uuid)
                == clk_seq_of_uuid($time_uuid)
        ) || (
            clk_seq_of_uuid($first_time_uuid)
                != clk_seq_of_uuid($time_uuid)
        ),
        'Integrity of parent clock sequence OK.'
    );

    # Check uniqueness of clock sequence ...
    isnt(
        clk_seq_of_uuid($child_data),
        clk_seq_of_uuid($time_uuid),
        'Clock sequence of child differs.'
    );

    # Check uniqueness of random UUIDs ...
    chomp($child_data = <$child>);
    my $random_uuid = create_uuid_as_string(UUID_RANDOM);
    isnt( $first_rand_uuid, $random_uuid, 'Parent random UUIDs differ.' );
    isnt( $child_data, $random_uuid, 'Child and parent random UUIDs differ.' );

    close $child;
}
else {
    croak "Error on fork(): $!" unless defined $pid;
    STDOUT->autoflush(1);

    # Generate time based UUID for comparison ...
    print STDOUT create_uuid_as_string(UUID_TIME), "\n";

    # Generate random UUID for comparison ...
    print STDOUT create_uuid_as_string(UUID_RANDOM), "\n";

    exit;
}

