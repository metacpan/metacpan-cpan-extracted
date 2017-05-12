package Unix::Uptime::BSD;

use warnings;
use strict;

my $HAVE_XS = eval { require Unix::Uptime::BSD::XS; };

our $VERSION='0.4000';
$VERSION = eval $VERSION;

sub uptime {
    my $class = shift;

    my ($boot_seconds, $boot_useconds) = $HAVE_XS
        ? $class->_boottime_xs()
        : $class->_boottime_sysctl_b();

    return (time() - $boot_seconds);
}

sub _boottime_sysctl_b {
    local $ENV{PATH} .= ':/usr/local/sbin:/usr/sbin:/sbin';
    my $raw_boottime = `sysctl -b kern.boottime`;

    return unpack("ll", $raw_boottime);
}

sub _boottime_xs {
    my $class = shift;

    return Unix::Uptime::BSD::XS::sysctl_kern_boottime();
}

sub uptime_hires {
    my $class = shift;

    my ($boot_seconds, $boot_useconds) = $HAVE_XS
        ? $class->_boottime_xs()
        : $class->_boottime_sysctl_b();

    my $time = Time::HiRes::gettimeofday();

    my $boot_time = $boot_seconds + ($boot_useconds * (10.0**-6));
    return ($time - $boot_time);
}

sub load {
    my $class = shift;

    my ($load1, $load5, $load15) = $HAVE_XS
        ? $class->_load_xs()
        : $class->_load_sysctl();

    return ($load1, $load5, $load15);
}

sub _load_xs {
    my $class = shift;

    my ($load1, $load5, $load15, $fscale) = Unix::Uptime::BSD::XS::sysctl_vm_loadavg();

    return (
        sprintf("%.2f",$load1/$fscale),
        sprintf("%.2f",$load5/$fscale),
        sprintf("%.2f",$load15/$fscale));
}

sub _load_sysctl {
    my $class = shift;

    local $ENV{PATH} .= ':/usr/local/sbin:/usr/sbin:/sbin';
    my $loadavg = `sysctl vm.loadavg`;

    # OpenBSD:
    #   vm.loadavg=2.54 2.47 2.48
    # FreeBSD:
    #   vm.loadavg: { 0.53 0.24 0.19 }

    my ($load1, $load5, $load15) = $loadavg =~ /vm\.loadavg\s*[:=]\s*\{?\s*(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)/;

    return ($load1, $load5, $load15);
}

sub load_hires {
    my $class = shift;

    require Time::HiRes;
}

1;

__END__

=head1 NAME

Unix::Uptime::BSD - BSD implementation of Unix::Uptime (for Darwin, DragonFly, and *BSD)

=head1 SEE ALSO

L<Unix::Uptime>

=cut

# vim: set ft=perl sw=4 sts=4 et :
