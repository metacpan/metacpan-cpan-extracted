package XAS::Apps::Test::Service;

use XAS::Lib::POE::Service;

use XAS::Class
  version => '0.01',
  base    => 'XAS::Lib::App::Service',
  vars => {
    SERVICE_NAME         => 'XAS_POE_TEST',
    SERVICE_DISPLAY_NAME => 'XAS POE Test',
    SERVICE_DESCRIPTION  => 'This is a test service',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub main {
    my $self = shift;

    my $service;

    $self->service->register('testing');

    $self->log->info_msg('startup');

    $service = XAS::Lib::Service->new(-alias => 'testing');
    $service->run();

    $self->log->info_msg('shutdown');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Test::Service - A template module for services within the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Test::Service;

 my $app = XAS::Apps::Test::Service->new();

 exit $app->run();

=head1 DESCRIPTION

This module is a template on a way to write procedures that are services
within the XAS enviornment.

=head1 CONFIGURATION

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
