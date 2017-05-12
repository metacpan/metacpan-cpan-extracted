package XAS::Collector::Format::Logs;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Collector::Format::Base',
;

#use Data::Dumper;

# --------------------------------------------------------------------
# Public Events
# --------------------------------------------------------------------

sub format_data {
    my ($self, $data, $ack, $input, $output) = @_[OBJECT,ARG0...ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: format");

    my $rec = {
        datetime => $data->{'@timestamp'},
        hostname => $data->{'hostname'},
        type     => $data->{'type'},
        level    => $data->{'priority'},
        facility => $data->{'facility'},
        process  => $data->{'process'},
        message  => $data->{'message'},
        pid      => $data->{'pid'},
        tid      => $data->{'tid'} || '0',
        msgnum   => $data->{'msgnum'} || '0',
    };

    $poe_kernel->post($output, 'store_data', $rec, $ack, $input);

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

XAS::Collector::Format::Logs - Perl extension for the XAS Environment

=head1 SYNOPSIS

  use XAS::Collector::Format::Logs;

  my $formatter = XAS::Collector::Format::Logs->new(
      -alias => 'format-logs',
  );

=head1 DESCRIPTION

This module formats the xas-logs packet type for output.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Collector::Format::Base|XAS::Collector::Format::Base>
and takes the same parameters.

=head1 PUBLIC EVENTS

=head2 format_data(OBJECT, ARG0...ARG3)

This event will trigger the formatting of xas-logs packets. 

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

The data to be formatted.

=item B<ARG1>

The acknowledgement to send back to the message queue server. This is passed 
on to the output processor.

=item B<ARG2>

The alias of the input processor. This is passed on to the output processor.

=item B<ARG3>

The alias of the output processor.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Collector::Format::Base|XAS::Collector::Format::Base>

=item L<XAS::Collector::Format::Alerts|XAS::Collector::Format::Alerts>

=item L<XAS::Collector|XAS::Collector>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
