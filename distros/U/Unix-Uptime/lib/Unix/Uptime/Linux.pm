package Unix::Uptime::Linux;

use warnings;
use strict;

our $VERSION='0.4000';
$VERSION = eval $VERSION;

sub uptime {
    my $class = shift;
    open my $proc_uptime, '<', '/proc/uptime'
        or die "Failed to open /proc/uptime: $!";

    my $line = <$proc_uptime>;
    my ($uptime) = $line =~ /^(\d+)/;
    return $uptime;
}

sub uptime_hires {
    my $class = shift;

    unless ($class->_want_hires()) {
        die "uptime_hires: you need to import Unix::Uptime with ':hires'";
    }

    open my $proc_uptime, '<', '/proc/uptime'
        or die "Failed to open /proc/uptime: $!";

    my $line = <$proc_uptime>;
    my ($uptime) = $line =~ /^(\d+(\.\d+)?)/;
    return $uptime;
}

sub load {
    my $class = shift;

    open my $proc_loadavg, '<', '/proc/loadavg'
        or die "Failed to open /proc/loadavg: $!";

    my $line = <$proc_loadavg>;
    my ($load1, $load5, $load15) = $line =~ /^(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)/;
    return ($load1, $load5, $load15);
}

1;

__END__

=head1 NAME

Unix::Uptime::Linux - Linux implementation of Unix::Uptime

=head1 SEE ALSO

L<Unix::Uptime>

=cut

# vim: set ft=perl sw=4 sts=4 et :
