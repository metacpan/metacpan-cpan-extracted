package XAS::Lib::App::Service::Unix;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => 'daemonize dotid',
  mixins  => 'define_daemon get_service_config 
              install_service remove_service',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub define_daemon {
    my $self = shift;

    # become a daemon...
    # interesting, "daemonize() if ($self->daemon);" doesn't work as expected

    $self->log->debug("pid = $$");

    if ($self->daemon) {

        daemonize();
        $poe_kernel->has_forked();

    }

    $self->log->debug("pid = $$");

}

sub get_service_config {
    my $self = shift;

}

sub install_service {
    my $self = shift;

}

sub remove_service {
    my $self = shift;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::App::Service::Unix - A mixin class for Unix Services

=head1 SYNOPSIS

 use XAS::Class
   debug      => 0,
   version    => $VERSION,
   base       => 'XAS::Lib::App::Service',
   mixin      => 'XAS::Lib::App::Service::Unix',
   constants  => 'TRUE FALSE',
   filesystem => 'File',
   accessors  => 'daemon service pid',
 ;


=head1 DESCRIPTION

This module provides a mixin class to define the necessary functionality for
a Service to run on a Unix like box.

=head1 METHODS

=head2 define_daemon

This method will tell POE that the process has forked.

=head2 get_service_config

This method does nothing on Unix.

=head2 install_service

This method does nothing on Unix.

=head2 remove_service

This method does nothing on Unix.

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
