package # hide from PAUSE
        Win32::Service;
use strict;
use warnings;
use Exporter ();

use constant {
    SERVICE_KERNEL_DRIVER       => 0x00000001,
    SERVICE_FILE_SYSTEM_DRIVER  => 0x00000002,
    SERVICE_ADAPTER             => 0x00000004,
    SERVICE_RECOGNIZER_DRIVER   => 0x00000008,
    SERVICE_WIN32_OWN_PROCESS   => 0x00000010,
    SERVICE_WIN32_SHARE_PROCESS => 0x00000020,
    SERVICE_INTERACTIVE_PROCESS => 0x00000100,

    SERVICE_STOPPED             => 0x00000001, 
    SERVICE_START_PENDING       => 0x00000002,
    SERVICE_STOP_PENDING        => 0x00000003,
    SERVICE_RUNNING             => 0x00000004,
    SERVICE_CONTINUE_PENDING    => 0x00000005,
    SERVICE_PAUSE_PENDING       => 0x00000006,
    SERVICE_PAUSED              => 0x00000007,

    SERVICE_ACCEPT_STOP                 => 0x00000001,
    SERVICE_ACCEPT_PAUSE_CONTINUE       => 0x00000002,
    SERVICE_ACCEPT_SHUTDOWN             => 0x00000004,
    SERVICE_ACCEPT_PARAMCHANGE          => 0x00000008,
    SERVICE_ACCEPT_NETBINDCHANGE        => 0x00000010,
    SERVICE_ACCEPT_HARDWAREPROFILECHANGE=> 0x00000020,
    SERVICE_ACCEPT_POWEREVENT           => 0x00000040,
    SERVICE_ACCEPT_SESSIONCHANGE        => 0x00000080,
};

{
    no strict;
    $VERSION = '0.01';
    @ISA     = qw(Exporter);
    @EXPORT  = qw(
        SERVICE_KERNEL_DRIVER
        SERVICE_FILE_SYSTEM_DRIVER
        SERVICE_ADAPTER
        SERVICE_RECOGNIZER_DRIVER
        SERVICE_WIN32_OWN_PROCESS
        SERVICE_WIN32_SHARE_PROCESS
        SERVICE_INTERACTIVE_PROCESS

        SERVICE_STOPPED
        SERVICE_START_PENDING
        SERVICE_STOP_PENDING
        SERVICE_RUNNING
        SERVICE_CONTINUE_PENDING
        SERVICE_PAUSE_PENDING
        SERVICE_PAUSED

        SERVICE_ACCEPT_STOP
        SERVICE_ACCEPT_PAUSE_CONTINUE
        SERVICE_ACCEPT_SHUTDOWN
        SERVICE_ACCEPT_PARAMCHANGE
        SERVICE_ACCEPT_NETBINDCHANGE
        SERVICE_ACCEPT_HARDWAREPROFILECHANGE
        SERVICE_ACCEPT_POWEREVENT
        SERVICE_ACCEPT_SESSIONCHANGE
    );

    @EXPORT_OK = qw(
        StartService  StopService  PauseService  ResumeService
        GetStatus     GetServices
    );
}

my %services = (
    dummy => {
        ServiceType             => SERVICE_WIN32_OWN_PROCESS,
        CurrentState            => SERVICE_PAUSED,
        ControlsAccepted        => SERVICE_ACCEPT_PAUSE_CONTINUE,
        Win32ExitCode           => 0,
        ServiceSpecificExitCode => 0,
        CheckPoint              => 0,
        WaitHint                => 0,
    },
);


sub StartService {
    my ($hostname, $servicename) = @_;
    return 1
}

sub StopService {
    my ($hostname, $servicename) = @_;
    return 1
}

sub PauseService {
    my ($hostname, $servicename) = @_;
    return 1
}

sub ResumeService {
    my ($hostname, $servicename) = @_;
    return 1
}

sub GetStatus {
    my ($hostname, $servicename, $status) = @_;
    %$status = %{ $services{$servicename} };
    return 1
}

sub GetServices {
    my ($hostname, $descr) = @_;
    %$descr = map { $_ => $_ } keys %services;
    return 1
}


1

__END__

=head1 NAME

Win32::Service - Mocked Win32::Service

=head1 SYNOPSIS

    use Win32::Mock;
    use Win32::Service;

=head1 DESCRIPTION

This module is a mock/emulation of C<Win32::Service>. 
See the documentation of the real module for more details. 

=head1 SEE ALSO

L<Win32::Service>

L<Win32::Mock>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2008 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

