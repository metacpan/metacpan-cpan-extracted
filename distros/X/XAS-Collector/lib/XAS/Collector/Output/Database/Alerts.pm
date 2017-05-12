package XAS::Collector::Output::Database::Alerts;

our $VERSION = '0.01';

use POE;
use Try::Tiny;

use XAS::Model::Database
  schema => 'XAS::Model::Database::Messaging',
  table  => 'Alert'
;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Collector::Output::Database::Base',
;

#use Data::Dumper;

# --------------------------------------------------------------------
# Public Events
# --------------------------------------------------------------------

sub store_data {
    my ($self, $data, $ack, $input) = @_[OBJECT,ARG0...ARG2];

    my $buffer;
    my $alias  = $self->alias;
    my $schema = $self->schema;

    $self->log->debug("$alias: entering store_data()");

    $buffer = sprintf('%s: hostname = %s; timestamp = %s; priority = %s; facility = %s; message = %s',
        $alias, $data->{'hostname'}, $data->{'datetime'}, $data->{'priority'}, 
        $data->{'facility'}, $data->{'message'}
    );

    $self->log->debug($buffer);

    try {

        $data->{'revision'} = 1;
        Alert->create($schema, $data);

        $self->log->info_msg('collector_processed', $alias, 1, $data->{'hostname'}, $data->{'datetime'});

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);
        $self->event->publish(
            -event => 'stop_queue',
            -args  => $alias
        );

    };

    $poe_kernel->post($input, 'write_data', $ack);

    $self->log->debug("$alias: leaving store_notify()");

}

# --------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Collector::Output::Database::Alerts - Perl extension for the XAS Environment

=head1 SYNOPSIS

  use XAS::Collector::Output::Database::Alerts;

  my $notify = XAS::Collector::Output::Database::Alerts->new(
      -alias    => 'database-alerts',
      -database => 'messaging',
  );

=head1 DESCRIPTION

This module handles the xas-alerts packet type.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Collector::Output::Database::Base|XAS::Collector::Output::Database::Base> 
and takes the same parameters.

=head1 PUBLIC EVENTS

=head2 store_data(OBJECT, ARG0, ARG1, ARG2)

This event will trigger the storage of xas-alerts packets into the database. 

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

The data to be stored within the database.

=item B<ARG1>

The acknowledgement to send back to the message queue server.

=item B<ARG2>

The input to return the ack too.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Collector::Output::Database::Base|XAS::Collector::Output::Database::Base>

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
