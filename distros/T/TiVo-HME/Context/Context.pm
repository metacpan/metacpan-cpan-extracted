package TiVo::HME::Context;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.1';

use constant ID_CLIENT => 100;

sub new {
	my($class, %args) = @_;

	bless { %args, client_id => ID_CLIENT }, $class;
}

sub get_io {
	my($self) = @_;

	$self->{connexion};
}

sub get_next_id {
	my($self) = @_;

	$self->{client_id}++;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

TiVo::HME::Context - Context object containing some useful values

=head1 SYNOPSIS

  use TiVo::HME::Context;

=head1 DESCRIPTION

This object is just a bless'ed hash containing some important
values:
    'io' -> I/O stream to client (TiVo)
    'peer' -> packed sockaddr address of peer (perldoc -f getpeername)
    'cookie' -> ID of persistent data from client (TiVo)
    'request' -> HTTP::Request object

    This object is constructed by TiVo::HME::Socket as is passed to
    your application as a parameter to your 'init' function.
    It's also available to your app by calling $self->get_context

    You prolly do NOT want to mess w/the IO within the context.

=head1 SEE ALSO

http://tivohme.sourceforge.net
TiVo::HME::Application

=head1 AUTHOR

Mark Ethan Trostler, E<lt>mark@zzo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mark Ethan Trostler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
