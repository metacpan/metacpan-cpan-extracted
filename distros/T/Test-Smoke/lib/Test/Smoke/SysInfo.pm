package Test::Smoke::SysInfo;
use warnings;
use strict;

our $VERSION = '0.043';

use base 'Exporter';
our @EXPORT_OK = qw( &sysinfo &tsuname );

use Test::Smoke::SysInfo::AIX;
use Test::Smoke::SysInfo::BSD;
use Test::Smoke::SysInfo::Cygwin;
use Test::Smoke::SysInfo::Darwin;
use Test::Smoke::SysInfo::Generic;
use Test::Smoke::SysInfo::Haiku;
use Test::Smoke::SysInfo::HPUX;
use Test::Smoke::SysInfo::Irix;
use Test::Smoke::SysInfo::Linux;
use Test::Smoke::SysInfo::Solaris;
use Test::Smoke::SysInfo::VMS;
use Test::Smoke::SysInfo::Windows;

=head1 NAME

Test::Smoke::SysInfo - Factory for system specific information objects

=head1 SYNOPSIS

    use Test::Smoke::SysInfo;

    my $si = Test::Smoke::SysInfo->new;

    printf "Hostname: %s\n", $si->host;
    printf "Number of CPU's: %s\n", $si->ncpu;
    printf "Processor type: %s\n", $si->cpu_type;   # short
    printf "Processor description: %s\n", $si->cpu; # long
    printf "OS and version: %s\n", $si->os;

or

    use Test::Smoke::SysInfo qw( sysinfo );
    printf "[%s]\n", sysinfo();

or

    $ perl -MTest::Smoke::SysInfo=tsuname -le print+tsuname

=head1 DESCRIPTION

Sometimes one wants a more eleborate description of the system one is
smoking.

=head1 METHODS

=head2 Test::Smoke::SysInfo->new( )

Factory method, with fallback to the information in C<< POSIX::uname() >>.

=cut

sub new {
    my $factory = shift;

    $^O =~ /aix/i               and return Test::Smoke::SysInfo::AIX->new();
    $^O =~ /bsd/i               and return Test::Smoke::SysInfo::BSD->new();
    $^O =~ /cygwin/i            and return Test::Smoke::SysInfo::Cygwin->new();
    $^O =~ /darwin/i            and return Test::Smoke::SysInfo::Darwin->new();
    $^O =~ /haiku/              and return Test::Smoke::SysInfo::Haiku->new();
    $^O =~ /hp-?ux/i            and return Test::Smoke::SysInfo::HPUX->new();
    $^O =~ /irix/i              and return Test::Smoke::SysInfo::Irix->new();
    $^O =~ /linux/i             and return Test::Smoke::SysInfo::Linux->new();
    $^O =~ /solaris|sunos|osf/i and return Test::Smoke::SysInfo::Solaris->new();
    $^O =~ /VMS/                and return Test::Smoke::SysInfo::VMS->new();
    $^O =~ /mswin32|windows/i   and return Test::Smoke::SysInfo::Windows->new();

    return Test::Smoke::SysInfo::Generic->new();;
}

=head2 sysinfo( )

C<sysinfo()> returns a string with C<host>, C<os> and C<cpu_type>.

=cut

sub sysinfo {
    my $si = Test::Smoke::SysInfo->new;
    my @fields = $_[0]
        ? qw( host os cpu ncpu cpu_type )
        : qw( host os cpu_type );
    return join " ", @{ $si }{ map "_$_" => @fields };
}

=head2 tsuname( @args )

This class gathers most of the C<uname(1)> info, make a comparable
version. Takes almost the same arguments:

    a for all (can be omitted)
    n for nodename
    s for os name and version
    m for cpu name
    c for cpu count
    p for cpu_type

=cut

sub tsuname {
    my $si = Test::Smoke::SysInfo->new();
    return $si->tsuname(@_);
}

1;

=head1 SEE ALSO

L<Test::Smoke::Smoker>, L<Test::Smoke::Reporter>

=head1 COPYRIGHT

(c) 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
