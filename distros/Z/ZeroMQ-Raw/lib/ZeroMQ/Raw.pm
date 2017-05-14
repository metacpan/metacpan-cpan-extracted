package ZeroMQ::Raw;
# ABSTRACT: ZeroMQ binding that tries to maintain a 1:1 correspondence with the C api
use strict;
use warnings;
use XSLoader;
use XS::Object::Magic;
use 5.008;

our $VERSION = '0.01';

XSLoader::load('ZeroMQ::Raw', $VERSION);

require ZeroMQ::Raw::Context;
require ZeroMQ::Raw::Message;
require ZeroMQ::Raw::Socket;

1;

__END__

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>
