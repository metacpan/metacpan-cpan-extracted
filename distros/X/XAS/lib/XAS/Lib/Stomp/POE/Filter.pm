package XAS::Lib::Stomp::POE::Filter;

our $VERSION = '0.03';

use XAS::Lib::Stomp::Parser;
use XAS::Constants 'CRLF :stomp';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'filter eol',
  constant => {
    LF => "\n",
  },
  vars => {
    PARAMS => {
      -target => { optional => 1, default => undef, regex => STOMP_LEVELS },
    }
  }
;

#use Data::Hexdumper;

# ---------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------

sub get_one_start {
    my ($self, $buffers) = @_;

    foreach my $buffer (@$buffers) {

        if (my $frame = $self->filter->parse($buffer)) {

            push(@{$self->{frames}}, $frame);

        }

    }

}

sub get_one {
    my ($self) = shift;

    my @ret;

    if (my $frame = shift(@{$self->{frames}})) {

        push(@ret, $frame);

    }

    return \@ret;

}

sub get_pending {
    my ($self) = shift;

    return $self->filter->get_pending;

}

sub put {
    my ($self, $frames) = @_;

    my @ret;

    foreach my $frame (@$frames) {

        my $buffer = $frame->as_string;

#        $self->log->debug(hexdump($buffer));
        push(@ret, $buffer);

    }

    return \@ret;

}

# ---------------------------------------------------------------------
# Private methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    unless (defined($self->{target})) {

        $self->{target} = $self->env->mqlevel;

    }

    $self->{eol} = ($self->target > 1.1) ? CRLF : LF;
    $self->{filter} = XAS::Lib::Stomp::Parser->new(-target => $self->target);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Stomp::POE::Filter - An I/O filter for the POE Environment

=head1 SYNOPSIS

  use XAS::Lib::Stomp::POE::Filter;

  For a server

  POE::Component::Server::TCP->new(
      ...
      Filter => XAS::Lib::Stomp::POE::Filter->new(),
      ...
  );

  For a client

  POE::Component::Client::TCP->new(
      ...
      Filter => XAS::Lib::Stomp::POE::Filter->new(),
      ...
  );

=head1 DESCRIPTION

This module is a filter for the POE environment. It will translate the input
buffer into L<XAS::Lib::Stomp::Frame|XAS::Lib::Stomp::Frame> objects and 
serialize the output buffer from said object. 

=head1 METHODS

=head2 new

This method initializes the module.

=head2 get_one_start($buffers)

This method parses one frame for a buffer and stores it in an internal frames 
buffer.

=over 4

=item B<$buffers>

A reference to a buffer.

=back

=head2 get_one

This method returns one frame from the internal buffer.

=head2 get_pending

This method returns the number of pending frames.

=head2 put($buffers)

This method pulls frames out of the buffer, stringifies them and places them
into a internal array. When done it returns that array.

=over 4

=item B<$buffers>

A reference to a buffer of L<XAS::Lib::Stomp::Frame|XAS::Lib::Stomp::Frame> 
frames.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

See the documentation for L<POE::Filter|https://metacpan.org/pod/POE::Filter> for usage.

For more information on the STOMP protocol, please refer to: L<http://stomp.github.io/> .

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
