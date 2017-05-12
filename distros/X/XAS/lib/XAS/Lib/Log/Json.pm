package XAS::Lib::Log::Json;

our $VERSION = '0.01';

use XAS::Factory;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  utils      => ':validation level2syslog',
  codec      => 'JSON',
  accessors  => 'spooler',
  constants  => 'HASHREF',
  filesystem => 'Dir',
;

# note to self: Don't but $self->log->debug() statements in here
# it will produce a nice race condition.

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub output {
    my $self  = shift;
    my ($args) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $message = sprintf('[%s] %-5s - %s',
        $args->{'datetime'}->strftime('%Y-%m-%d %H:%M:%S'),
        uc($args->{'priority'}), 
        $args->{'message'}
    );

    # create a logstash "json_event"

    my $data = {
        '@timestamp' => $args->{'datetime'}->strftime('%Y-%m-%dT%H:%M:%S.%3N%z'),
        '@version'   => '1',
        '@message'   => $message,
        type         => 'xas-logs',
        message      => $args->{'message'},
        hostname     => $args->{'hostname'},
        priority     => level2syslog($args->{'priority'}),
        facility     => $args->{'facility'},
        process      => $args->{'process'},
        pid          => $args->{'pid'}
    };

    my $json = encode($data);

    # write the spool file

    $self->spooler->write($json);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'spooler'} = XAS::Factory->module('spool', {
        -directory => Dir($self->env->spool, 'logs'),
        -lock      => Dir($self->env->spool, 'logs', 'locked')->path,
    });

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Log::Json - A class for logging with JSON output

=head1 DESCRIPTION

This module creates JSON output in the logstash "json_event" format which 
is then logged to the logs spool directory.

=head1 METHODS

=head2 new

This method initializes the module. It creates a spool object for writing
the "json_event".

=head2 output($hashref)

This method formats the hashref and writes out the results. The JSON data
structure has the following fields:

    @timestamp     - current time in GMT
    @version       - 1
    @message       - the line that would have gone to a log file
    type           - 'xas-logs',
    message        - the log line
    hostname       - from the environment host name
    pid            - the pid of the process
    msgid          - 0
    priority       - converted from XAS log level to syslog priority
    facility       - from the environment log_facility
    process        - from the environment script name

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Log|XAS::Lib::Log>

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
