use strict;
use warnings;

use Test::More;
use WiringPi::API qw(:wiringPi :perl);

# V14: I2C block/raw additions + i2c_interface implementation.
#
# Real block transfers need a wired I2C device, so this test exercises the
# argument guards (both the Perl wrappers and the XS-level size/arrayref checks),
# which all croak BEFORE any ioctl - safe without hardware. The fd value below is
# never used because validation fails first.

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

my $fd = 3;   # dummy; guards croak before it is touched

# exports
for my $sub (qw(wiringPiI2CReadBlockData wiringPiI2CRawRead
                wiringPiI2CWriteBlockData wiringPiI2CRawWrite
                i2c_read_block i2c_raw_read i2c_write_block i2c_raw_write
                i2c_interface)){
    ok(WiringPi::API->can($sub), "$sub is defined/exported");
}

# i2c_interface now works (no longer the old "not available" stub)
eval { i2c_interface() };
like $@, qr/requires a \$device/, "i2c_interface() croaks on missing device (not 'not available')";
unlike $@, qr/not available/, "i2c_interface() is implemented (no 'not available' croak)";

# Perl-wrapper param guards
eval { i2c_read_block() };       like $@, qr/requires an \$fd/,  "i2c_read_block() needs \$fd";
eval { i2c_read_block($fd) };    like $@, qr/requires a \$register/, "i2c_read_block() needs \$reg";
eval { i2c_read_block($fd, 0) }; like $@, qr/requires a \$size/, "i2c_read_block() needs \$size";
eval { i2c_raw_read() };         like $@, qr/requires an \$fd/,  "i2c_raw_read() needs \$fd";
eval { i2c_write_block($fd, 0, "nope") }; like $@, qr/array reference/, "i2c_write_block() needs an arrayref";
eval { i2c_raw_write($fd, {}) };          like $@, qr/array reference/, "i2c_raw_write() needs an arrayref";

# XS-level size/length guards (croak before any ioctl)
eval { i2c_read_block($fd, 0, 300) }; like $@, qr/0-255/, "i2c_read_block() rejects size > 255";
eval { i2c_raw_read($fd, 256) };      like $@, qr/0-255/, "i2c_raw_read() rejects size > 255";
eval { i2c_write_block($fd, 0, [ (0) x 256 ]) }; like $@, qr/0-255/, "i2c_write_block() rejects > 255 values";
eval { i2c_raw_write($fd, [ (0) x 256 ]) };      like $@, qr/0-255/, "i2c_raw_write() rejects > 255 values";

done_testing();
