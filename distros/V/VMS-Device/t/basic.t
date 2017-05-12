use strict;
use Config;
use Test::More tests => 3;

BEGIN { use_ok( 'VMS::Device' ); }

use VMS::Device;  # no longer in scope

my $devhash = VMS::Device::device_info('SYS$SYSDEVICE:');
ok $devhash, "Retrieved device info";
diag "Your " . $devhash->{ACPTYPE} . " system disk has " . $devhash->{FREEBLOCKS} . " free blocks.";

SKIP:
{
  skip 'VOLCHAR not implemented on VAX', 1 if $Config{archname} =~ m/^VMS_VAX/;
  my $volchar = VMS::Device::decode_device_bitmap("VOLCHAR", $devhash->{VOLCHAR});
  ok $volchar, "Retrieved device bitmap";

  diag "Volume characteristics for your system disk:";
  for my $char (keys %$volchar) {
    next unless $volchar->{$char};
    diag "$char";
  }
}
