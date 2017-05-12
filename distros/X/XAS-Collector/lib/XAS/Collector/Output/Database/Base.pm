package XAS::Collector::Output::Database::Base;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use XAS::Model::Schema;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Service',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  utils     => 'db2dt',
  accessors => 'schema event',
  vars => {
    PARAMS => {
      -database => { optional => 1, default => 'messaging' },
    }
  }
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

    $self->{'event'}  = XAS::Lib::POE::PubSub->new();
    $self->{'schema'} = XAS::Model::Schema->opendb($self->database);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Collector::Output::Database::Base - Perl extension for the XAS Environment

=head1 SYNOPSIS

  use XAS::Collector::Output::Database::Logs;

  my $output = XAS::Collector::Output::Database::Logs->new(
      -alias    => 'database-logs',
      -database => 'messaging',
  );

=head1 DESCRIPTION

This module is the base class for database storage.

=head1 METHODS

=head2 new

This module inheirts from L<XAS::Lib::POE::Service|XAS::Lib::POE::Service> and
takes these additional parameters:

=over 4

=item B<-database>

An optional configuration name for the database to use, defaults to 'messaging'.

=back

=head1 PUBLIC EVENTS

This module declares the following events.

=head2 store_data

This event is called when a packet is ready for processing.

=head1 SEE ALSO

=over 4

=item L<XAS::Collector::Output::Database::Alerts|XAS::Collector::Output::Database::Alerts>

=item L<XAS::Collector::Output::Database::Logs|XAS::Collector::Output::Database::Logs>

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
