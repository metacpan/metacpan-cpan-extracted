package Test::Smoke::SysInfo::Windows;
use warnings;
use strict;

use base 'Test::Smoke::SysInfo::Base';

=head1 NAME

Test::Smoke::SysInfo::Windows - Object for specific Windows info.

=head1 DESCRIPTION

=head2 $si->prepare_sysinfo()

Use os-specific tools to find out more about the system.

=cut

sub prepare_sysinfo {
    my $self = shift;
    $self->SUPER::prepare_sysinfo();
    $self->prepare_os();

    my $reginfo = __get_registry_sysinfo();
    my $envinfo = __get_environment_sysinfo();

    for my $key (qw/__cpu_type __cpu __cpu_count/) {
        my $value = $reginfo->{$key} || $envinfo->{$key};
        $self->{$key} = $value if $value;
    }
    return $self;
}

=head2 $si->prepare_os()

Use os-specific tools to find out more about the operating system.

=cut

sub prepare_os {
    my $self = shift;

    eval { require Win32 };
    return if $@;

    my $os = $self->_os();
    $os = "$^O - " . join(" ", Win32::GetOSName());
    $os =~ s/Service\s+Pack\s+/SP/;
    $self->{__os} = $os;
}

sub __get_registry_sysinfo {
    eval { require Win32::TieRegistry };
    return if $@;

    Win32::TieRegistry->import();
    my $Registry = $Win32::TieRegistry::Registry->Open(
        "",
        { Access => 0x2000000 }
    );

    my $basekey = join(
        "\\",
        qw(LMachine HARDWARE DESCRIPTION System CentralProcessor)
    );

    my $pnskey = "$basekey\\0\\ProcessorNameString";
    my $cpustr = $Registry->{ $pnskey };

    my $idkey = "$basekey\\0\\Identifier";
    $cpustr ||= $Registry->{ $idkey };
    $cpustr =~ tr/ / /s;

    my $mhzkey = "$basekey\\0\\~MHz";
    $cpustr .= sprintf "(~%d MHz)", hex $Registry->{ $mhzkey };
    my $cpu = $cpustr;

    my $ncpu = keys %{ $Registry->{ $basekey } };

    my ($cpu_type) = $Registry->{ $idkey } =~ /^(\S+)/;

    return {
        __cpu_type  => $cpu_type,
        __cpu       => $cpu,
        __cpu_count => $ncpu,
    };
}

sub __get_environment_sysinfo {
    return {
        __cpu_type  => $ENV{PROCESSOR_ARCHITECTURE},
        __cpu       => $ENV{PROCESSOR_IDENTIFIER},
        __cpu_count => $ENV{NUMBER_OF_PROCESSORS},
    };
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
