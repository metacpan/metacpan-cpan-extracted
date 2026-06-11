use warnings;
use strict;

# V32 leak/behaviour harness for the hand-written XS buffer paths that the t/
# suite cannot reach without a serial/SPI device: serialGets and spiDataRW.
# Every Newx()/Safefree() site is driven on a loop so a leak shows up in
# valgrind's summary. The device *success* path is intentionally NOT here
# (no serial device; wiringPi wants /dev/spidev0.0 but a Pi5/RP1 exposes
# spidev10.0 -> tracked as B11). We gate the validation, croak and marshalling
# (buffer alloc/free) paths, which all run before the device touch.

use WiringPi::API qw(:all);

my $iters = 200;

exercise_phys_pin_to_wpi();
exercise_spi_data_rw();
exercise_serial_gets();

print "valgrind_xs.pl: all custom-XS buffer paths exercised ($iters iters each)\n";

# physPinToWpi: static-map index with the F21 bounds guard. OOB + in-range.
sub exercise_phys_pin_to_wpi {
    for (1 .. $iters) {
        physPinToWpi(-1);
        physPinToWpi(64);
        physPinToWpi(9999);
        physPinToWpi(11);     # -> wpi 0
        physPinToWpi(40);     # -> wpi 29
    }
}

# serialGets: drive the Newx/read-loop/Safefree buffer logic against fds we
# control (a pipe), so no serial port is needed. Covers the F13 overflow site.
sub exercise_serial_gets {
    for (1 .. $iters) {
        # Partial read then EOF: write 3 bytes, close the writer, ask for 10.
        # serialGets allocates 10, reads 3, sees EOF (read==0), returns 3.
        pipe(my $rx, my $tx) or die "pipe: $!";
        syswrite($tx, "abc");
        close $tx;
        my $got = WiringPi::API::serialGets(fileno($rx), 10);
        die "expected 'abc', got '$got'" unless $got eq 'abc';
        close $rx;

        # nbytes == 0: Newx(1), loop body never runs, returns "".
        pipe(my $rx0, my $tx0) or die "pipe: $!";
        my $empty = WiringPi::API::serialGets(fileno($rx0), 0);
        die "expected empty string" unless $empty eq '';
        close $rx0;
        close $tx0;

        # Read error: a bad fd croaks after Safefree(buf) - the leak-on-error
        # path. Must be catchable (F4: croak, not exit).
        eval { WiringPi::API::serialGets(-1, 8) };
        die "expected a read-error croak" unless $@ =~ /read error/;

        # Negative nbytes croaks before any alloc.
        eval { WiringPi::API::serialGets(fileno($rx), -1) };
        die "expected nbytes croak" unless $@ =~ /non-negative integer/;
    }
}

# spiDataRW: drive the Newx/av_fetch/Safefree marshalling. Every croak path
# Safefree()s the buffer first (F5/F14); the device call fails without setup,
# exercising the Safefree-before-croak on the valid-marshalling path too.
sub exercise_spi_data_rw {
    for (1 .. $iters) {
        # Bad channel: croaks before any alloc.
        eval { spiDataRW(5, [1, 2, 3], 3) };
        die "expected channel croak" unless $@ =~ /0 or 1/;

        # Not an arrayref.
        eval { spiDataRW(0, "notaref", 3) };
        die "expected aref croak" unless $@ =~ /array reference/;

        # len mismatch.
        eval { spiDataRW(0, [1, 2, 3], 2) };
        die "expected len croak" unless $@ =~ /does not match/;

        # Undefined element: allocates the buffer, then Safefree + croak.
        eval { spiDataRW(0, [1, undef, 3], 3) };
        die "expected undef-byte croak" unless $@ =~ /undefined/;

        # Out-of-range byte: allocates, then Safefree + croak.
        eval { spiDataRW(0, [1, 2, 999], 3) };
        die "expected out-of-range croak" unless $@ =~ /out of range/;

        # Valid bytes: full marshalling into the buffer, then the device call
        # fails (no wiringPiSPISetup / no usable spidev node here) -> Safefree
        # + croak. This is the buffer-fill path the croak cases above skip.
        eval { spiDataRW(0, [0x00, 0x01, 0x02, 0xFF], 4) };
        die "expected SPI-bus croak" unless $@ =~ /failed to write to the SPI bus/;
    }
}
