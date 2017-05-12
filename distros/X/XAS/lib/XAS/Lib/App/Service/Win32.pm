package XAS::Lib::App::Service::Win32;

our $VERSION = '0.01';

use Win32;
use Win32::Daemon;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  mixins  => 'define_daemon get_service_config install_service remove_service',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub define_daemon {
    my $self = shift;

}

sub get_service_config {
    my $self = shift;

    # here be dragons... the format is important, especially for the path.

    my $script = Win32::GetFullPathName($0);

    return {
        name        =>  $self->class->any_var('SERVICE_NAME'),
        display     =>  $self->class->any_var('SERVICE_DISPLAY_NAME'),
        path        =>  "\"$^X\" \"$script\"",
        user        =>  '',
        password    =>  '',
        description => $self->class->any_var('SERVICE_DESCRIPTION')
    };

}

sub install_service {
    my $self = shift;

    my $config = $self->get_service_config();

    if (Win32::Daemon::CreateService($config)) {

        printf("%s\n", $self->message('service_installed'));

    } else {

        printf("%s\n", $self->message('service_failed', 'install', _get_error()));

    }

}

sub remove_service {
    my $self = shift;

    my $config = $self->get_service_config();

    if (Win32::Daemon::DeleteService($config->{name})) {

        printf("%s\n", $self->message('service_removed'));

    } else {

        printf("%s\n", $self->message('service_failed', 'remove', _get_error()));

    }

}


# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _get_error {

    return(Win32::FormatMessage(Win32::Daemon::GetLastError()));

}

1;

__END__

=head1 NAME

XAS::Lib::App::Service::Win32 - A mixin class for Win32 Services

=head1 SYNOPSIS

 use XAS::Class
   debug      => 0,
   version    => $VERSION,
   base       => 'XAS::Lib::App::Service',
   mixin      => 'XAS::Lib::App::Service::Win32',
   constants  => 'TRUE FALSE',
   filesystem => 'File',
   accessors  => 'daemon service pid',
 ;

=head1 DESCRIPTION

This module provides a mixin class to define the necessary functionality for
a Service to run on Win32.

=head1 METHODS

=head2 define_daemon

This method does nothing on Win32.

=head2 get_service_config

This method defines how the service is configured. This is used with the
--install and --deinstall command line options. See
L<Win32::Daemon|https://metacpan.org/pod/Win32::Daemon> for more details.

=head2 install_service

This method will install the service with the SCM.

=head2 remove_service

This method will deinstall the service for the SCM.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::App::Service|XAS::Lib::App::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
