package XAS::Apps::Test::RPC::Processor;

our $VERSION = '0.01';

use POE;
use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Net::Server',
  mixin     => 'XAS::Lib::Mixin::JSON::Server XAS::Lib::Mixins::Keepalive',
  constants => ':jsonrpc',
  vars => {
    PARAMS => {
      -port          => { optional => 1, default => RPC_DEFAULT_PORT },
      -tcp_keepalive => { optional => 1, default => 0 },
    }
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub handle_connection {
    my ($self, $wheel) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    if (my $socket = $self->{clients}->{$wheel}->{socket}) {

        if ($self->tcp_keepalive) {

            $self->log->debug("$alias: keepalive enabled");
            $self->init_keepalive();
            $self->enable_keepalive($socket);

        }

    }

}

sub echo {
    my ($self, $params, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $line  = $params->{line};

    $poe_kernel->post($alias, 'process_response', $line, $ctx);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $methods = ['echo'];

    $self->init_json_server($methods);

    return $self;

}

1;

__END__

=head1 NAME

XAS::xxx - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::XXX;

=head1 DESCRIPTION

=head1 METHODS

=head2 method1

=head1 SEE ALSO

=over 4

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
