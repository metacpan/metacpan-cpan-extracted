package XAS::Lib::Log::Syslog;

our $VERSION = '0.01';

use Sys::Syslog qw(:standard :extended);

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => ':validation level2syslog',
  constants => 'HASHREF',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub output {
    my $self  = shift;
    my ($args) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $priority = level2syslog(lc($args->{'priority'}));
    my $message = sprintf('%s', $args->{'message'});

    syslog($priority, $message);

}

sub DESTROY {
    my $self = shift;

    closelog();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    setlogsock('unix');
    openlog($self->env->script, 'pid', $self->env->log_facility);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Log::Syslog - A class for logging syslog

=head1 DESCRIPTION

This module is for logging to syslog.

=head1 METHODS

=head2 new

This method initializes syslog. Sets the process, facility and requests that
the pid be included.

=head2 output($hashref)

This method translate the log level to an appropriate syslog priority and
writes out the log line. The translation is a follows:

    info  => 'info',
    error => 'err',
    warn  => 'warning',
    fatal => 'alert',
    trace => 'notice',
    debug => 'debug'

=head2 destroy

Closes the connection to syslog.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Log|XAS::Lib::Log>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
