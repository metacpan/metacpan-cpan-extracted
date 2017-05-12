package XAS::Collector::Output::Console::Base;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Service',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  utils     => 'db2dt',
  accessors => 'schema event',
;

#use Data::Dumper;

# --------------------------------------------------------------------
# Public Events
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('store_data', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup()");

    $self->event->publish(
        -event => 'start_queue',
        -args  => $alias
    );

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leasing session_startup()");

}

# --------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'event'} = XAS::Lib::POE::PubSub->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Collector::Output::Console::Base - Perl extension for the XAS Environment

=head1 SYNOPSIS

  use XAS::Collector::Output::Console::Logs;

  my $notify = XAS::Collector::Output::Console::Logs->new(
      -alias => 'database-logs',
  );

=head1 DESCRIPTION

This module is the base class for dumping data from packets.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::POE::Service|XAS::Lib::POE::Service> and
takes the same parameters.

=head1 PUBLIC EVENTS

This module declares the following events.

=head2 store_data

This event is called when a packet is ready for processing.

=head1 SEE ALSO

=over 4

=item L<XAS::Collector::Output::Console::Alerts|XAS::Collector::Output::Console::Alerts>

=item L<XAS::Collector::Output::Console::Logs|XAS::Collector::Output::Console::Logs>

=item L<XAS::Collector|XAS::Collector>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
