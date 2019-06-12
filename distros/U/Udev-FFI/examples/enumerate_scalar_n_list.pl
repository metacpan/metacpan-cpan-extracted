#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Udev::FFI;



my $udev = Udev::FFI->new() or
    die "Can't create Udev::FFI object: $@.\n";

my $enumerate = $udev->new_enumerate() or
    die "Can't create enumerate context: $@.\n";

$enumerate->add_match_subsystem('block');
$enumerate->scan_devices();

# scalar context
my $href = $enumerate->get_list_entries();
print Dumper($href), "\n";

# list context
my @a = $enumerate->get_list_entries();
print Dumper(@a), "\n";