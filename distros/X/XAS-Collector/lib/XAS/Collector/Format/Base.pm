package XAS::Collector::Format::Base;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::POE::Session',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('format_data', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leasing session_initialize()");

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Collector::Format::Base - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Collector::Format::Base'
 ;

=head1 DESCRIPTION

This module is the base class for formatting data.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::POE::Session|XAS::Lib::POE::Session> and
takes the same parameters.

=head1 PUBLIC EVENTS

This module declares the following events:

=head2 format_data

This event is called when data is available for formatting.

=head1 SEE ALSO

=over 4

=item L<XAS::Collector::Format::Alerts|XAS::Collector::Format::Alerts>

=item L<XAS::Collector::Format::Logs|XAS::Collector::Format::Logs>

=item L<XAS::Colletor|XAS::Collector>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
