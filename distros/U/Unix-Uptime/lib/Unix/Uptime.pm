package Unix::Uptime;

use warnings;
use strict;

our $VERSION='0.4000';
$VERSION = eval $VERSION;

my %modules = (
    cygwin    => 'Linux',
    freebsd   => 'BSD',
    dragonfly => 'BSD',
    linux     => 'Linux',
    openbsd   => 'BSD',
    darwin    => 'BSD',
    netbsd    => 'BSD',
);

my $module = $modules{$^O}
    or die "Operating system type $^O is currently unsupported";

require "Unix/Uptime/$module.pm";
our @ISA = ("Unix::Uptime::$module");

my $hires;

sub _want_hires {
    my $class = shift;

    return $hires;
}

sub import {
    my $class = shift;
    if (grep {$_ eq ':hires'} @_) {
        $hires = 1;
        $module = "Unix::Uptime::$module";
        $module->can('load_hires')
            and $module->load_hires();
    }
}

1;

=head1 NAME

Unix::Uptime - Determine the current uptime, in seconds, and load
averages, across different *NIX architectures

=head1 SYNOPSIS

  # Standard Usage
  use Unix::Uptime;

  my $uptime = Unix::Uptime->uptime(); # 2345

  # "HiRes" mode
  use Unix::Uptime qw(:hires);

  my $uptime = Unix::Uptime->uptime_hires(); # 2345.123593

  # Load Average
  my ($load1, $load5, $load15) = Unix::Uptime->load(); # (1.0, 2.0, 0.0)

=head1 DESCRIPTION

This is a rather simple module that abstracts the task of figuring out
the current system uptime, in seconds. It was born out of a desire to do
this on non-Linux systems, without SNMP. If you want to use SNMP, there
are pleanty of modules on CPAN already.

Additionally, since version 0.33_02, it supports retrieving the load
average.

Currently, this module just supports Linux, FreeBSD, Darwin (Mac OS X),
OpenBSD, and NetBSD. It should be easy enough to add support for other
operating systems, though.

=head1 OPTIONS

While this module doesn't provide any functions for exporting, if the
tag C<:hires> is given, then uptime_hires static method will be
available. It returns decimal numbers when possible, but on some systems
it is simply an alias for C<uptime()>. This will likely
require the Time::HiRes module to be available. Otherwise, they will
simply be whole seconds.

=head1 METHODS

The following static (class) methods are available:

=head2 uptime

This takes no arguments, and simply returns the number of seconds this
system has been running. This will always be an integer.

=head2 uptime_hires

This is only available if the C<:hires> import tag is used. It returns
the system uptime with a greater resolution than one second on supported
platforms. On some platforms, its results may not be any more precise
than C<uptime()>, though. On different platforms, this requires
different additional modules:

=over 4

=item Linux

No additional requirements.

=item FreeBSD

Requires Time::HiRes

=item Darwin, OpenBSD, NetBSD

No more precise than uptime()

=back

=head2 load

This returns an array of the load averages for the last 1, 5, and 15
minutes. The degree of precision varies from system to system.

=head1 SEE ALSO

L<Sys::Load>(3) and L<Sys::Uptime>(3) for Linux-specific implementations.

L<Win32::Uptime> for Win32.

=head1 BUGS

This currently doesn't support more than Linux, FreeBSD, Darwin (Mac OS
X), OpenBSD, and NetBSD. Contributions for other operating systems would
be welcome.

=head1 CAVEATS

B<NOTE:> This module is still a work in progress, under fairly heavy
development.  While I think the final API should be mostly finalized at
this point, I won't commit to an API freeze until version 1.0.

=head1 CONTRIBUTING

This project is developed using git. The repository may be browsed at:
L<https://github.com/pioto/Unix-Uptime>

Patches in git-format-patch style are preferred. Either send them to me
by email, or open an RT ticket
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Unix-Uptime>.

=head1 AUTHOR

Mike Kelly <pioto@pioto.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2014, Mike Kelly.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses at <http://www.perlfoundation.org/artistic_license_1_0>,
and <http://www.gnu.org/licenses/gpl-2.0.html>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

# vim: set ft=perl sw=4 sts=4 et :
