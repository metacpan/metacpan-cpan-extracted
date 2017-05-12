package Thrift::XS::MemoryBuffer;

use strict;
use base('Thrift::Transport');

use Thrift::XS;

# Implementation is in MemoryBuffer.xs

1;
__END__

=head1 NAME

Thrift::XS::MemoryBuffer - Fast memory buffer

=head1 SYNOPSIS

    use Thrift;
    use Thrift::XS::MemoryBuffer;
    use Thrift::XS::CompactProtocol;
    use MyThriftInterface;
    
    my $transport = Thrift::XS::MemoryBuffer->new(8192);
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    my $client    = MyThriftInterface->new($protocol);
    
    $transport->open;
    
    $client->api_call( @args );

=head1 DESCRIPTION

This module is useful when writing your own socket-layer implementation, for example,
it is used with L<AnyEvent::Cassandra>.

=head1 METHODS

=head2 new( [ BUFFER_SIZE ] )

Create a new buffer instance. Default buffer size is 8192 bytes.

=head2 available()

Return the amount of bytes waiting to be read from the buffer.

=head2 read( LENGTH )

Try to read LENGTH bytes from the buffer. If less bytes are available, as many as
possible will be returned.

=head2 readAll( LENGTH )

Similar to read, but dies if LENGTH bytes are not available.

=head2 write( DATA, [ LENGTH ] )

Append DATA to the buffer. LENGTH is optional but if provided it will avoid making
a length function call.

=head1 AUTHOR

Andy Grundman, E<lt>andy@slimdevices.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Logitech, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
