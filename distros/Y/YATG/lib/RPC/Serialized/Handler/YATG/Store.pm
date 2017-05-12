package RPC::Serialized::Handler::YATG::Store;
{
  $RPC::Serialized::Handler::YATG::Store::VERSION = '5.140510';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Handler';
use YATG::Store::Disk;

sub invoke {
    my $self = shift;
    return YATG::Store::Disk::store(@_);
}

1;

# ABSTRACT: RPC handler for YATG::Store::Disk


__END__
=pod

=head1 NAME

RPC::Serialized::Handler::YATG::Store - RPC handler for YATG::Store::Disk

=head1 VERSION

version 5.140510

=head1 DESCRIPTION

This module implements an L<RPC::Serialized> handler for L<YATG::Store::Disk>.
There is no special configuration, and all received parameters are passed on
to C<YATG::Store::Disk::store()> verbatim.

=head1 REQUIREMENTS

Install the following additional modules to use this plugin:

=over 4

=item *

L<RPC::Serialized>

=item *

L<Tile::File::FixedRecLen>

=item *

L<integer>

=item *

L<Time::Local>

=item *

L<Fcntl>

=back

=head1 INSTALLATION

You'll need to run an RPC::Serialized server, of course, and configure it to
serve this handler. There are files in the C<examples/> folder of this
distribution to help with that, e.g. C<rpc-serialized.server.yml>:

 ---
 # configuration for rpc-serialized server with YATG handlers
 rpc_serialized:
     handlers:
         yatg_store:    "RPC::Serialized::Handler::YATG::Store"
         yatg_retrieve: "RPC::Serialized::Handler::YATG::Retrieve"
 net_server:
     port: 1558
     user: daemon
     group: daemon

You should head over to the RPC::Serialized documentation to learn how to set
that up. We use a pre-forking L<Net::Server> based implementation to receive
port traffic data and store to disk, then serve it back out to CGI on a web
server.

=head1 SEE ALSO

=over 4

=item L<RPC::Serialized>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

