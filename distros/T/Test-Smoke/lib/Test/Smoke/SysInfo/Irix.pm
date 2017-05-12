package Test::Smoke::SysInfo::Irix;
use warnings;
use strict;

use base 'Test::Smoke::SysInfo::Base';

=head1 NAME

Test::Smoke::SysInfo::Irix - Object for specific Irix info.

=head1 DESCRIPTION

=head2 $si->prepare_sysinfo()

Use os-specific tools to find out more about the system.

=cut

sub prepare_sysinfo {
    my $self = shift;
    $self->SUPER::prepare_sysinfo();
    $self->prepare_os();

    chomp( my( $cpu ) = `hinv -t cpu` );
    $cpu =~ s/^CPU:\s+//;

    chomp( my @processor = `hinv -c processor` );
    my ($cpu_cnt) = grep /\d+.+processors?$/i => @processor;
    my ($cpu_mhz) = $cpu_cnt =~ /^\d+ (\d+ MHZ) /;
    my $ncpu = (split " ", $cpu_cnt)[0];
    my $type = (split " ", $cpu_cnt)[-2];

    $self->{__cpu_type}  = $type;
    $self->{__cpu}       = $cpu . " ($cpu_mhz)";
    $self->{__cpu_count} = $ncpu;

    return $self;
}

=head2 $si->prepare_os()

Use os-specific tools to find out more about the operating system.

=cut

sub prepare_os {
    my $self = shift;

    chomp( my $osvers = `uname -R` );
    my ($osn, $osv) = ($self->_osname, $self->_osvers);
    $osvers =~ s/^$osv\s+(?=$osv)//;
    $self->{__os} = "$osn - $osvers";
}

1;

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
