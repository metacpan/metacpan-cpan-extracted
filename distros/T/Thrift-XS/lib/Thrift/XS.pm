package Thrift::XS;

use strict;

use Thrift::XS::MemoryBuffer;
use Thrift::XS::BinaryProtocol;
use Thrift::XS::CompactProtocol;

our $VERSION = '1.04';

require XSLoader;
XSLoader::load('Thrift::XS', $VERSION);

1;

__END__

=head1 NAME

Thrift::XS - Faster Thrift binary protocol encoding and decoding

=head1 SYNOPSIS

    use Thrift;
    use Thrift::Socket;
    use Thrift::FramedTransport;
    use Thrift::XS::BinaryProtocol;
    use MyThriftInterface;
    
    my $socket    = Thrift::Socket->new( $host, $port );
    my $transport = Thrift::FramedTransport->new($socket);
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    my $client    = MyThriftInterface->new($protocol);
    
    $transport->open;
    
    $client->api_call( @args );
    
=head1 DESCRIPTION

Thrift::XS provides faster versions of Thrift::BinaryProtocol and
Thrift::MemoryBuffer.

Thrift compact protocol support is also available, just replace
Thrift::XS::BinaryProtocol with Thrift::XS::CompactProtocol.

To use, simply replace your Thrift initialization code with the appropriate
Thrift::XS version.

=head1 SPEED

For the best performance, you need to use a custom socket layer and both
L<Thrift::XS::MemoryBuffer> and one of L<Thrift::XS::BinaryProtocol> or
L<Thrift::XS::CompactProtocol>. If using the standard BufferedTransport,
FramedTransport, or HttpClient modules, performance will not be as good
as it could be. In particular, HttpClient is incredibly bad, making a lot of
very small (1-4 byte) sysread() and print() calls. A future version of this
module will probably provide XS implementations of these other modules to
help with this problem.

Here is a breakdown of the performance improvements of the various low-level
methods. A given Thrift API call will make many write and read method calls,
so your results will be some average of these numbers. For detailed numbers
and to run your own benchmarks, see the bench/bench.pl script.

    XS::MemoryBuffer write + read: 6x faster
    
    XS::BinaryProtocol
        writeMessageBegin + readMessageBegin: 12.0x
        complex struct/field write+read:       6.6x
        writeMapBegin + readMapBegin:         24.0x
        writeListBegin + readListBegin:       20.0x
        writeSetBegin + readSetBegin:         21.0x
        writeBool + readBool:                 13.5x
        writeByte + readByte:                 13.9x
        writeI16 + readI16:                   14.4x
        writeI32 + readI32:                   12.9x
        writeI64 + readI64:                   29.4x
        writeDouble + readDouble:             13.5x
        writeString + readString:              7.5x
        
    XS::CompactProtocol
        writeMessageBegin + readMessageBegin: 11.6x
        complex struct/field write+read:       6.2x
        writeMapBegin + readMapBegin:         18.7x
        writeListBegin + readListBegin:       14.1x
        writeSetBegin + readSetBegin:         13.3x
        writeBool + readBool:                 13.2x
        writeByte + readByte:                 13.9x
        writeI16 + readI16:                    9.0x
        writeI32 + readI32:                    7.5x
        writeI64 + readI64:                   10.0x
        writeDouble + readDouble:             13.5x
        writeString + readString:              7.4x

=head1 THANKS

Wang Lam, E<lt>wlam@kosmix.comE<gt>, for patches and additional tests.

=head1 SEE ALSO

Thrift Home L<http://thrift.apache.org/>

Thrift Perl code L<http://svn.apache.org/repos/asf/thrift/trunk/lib/perl/>

L<AnyEvent::Cassandra>, example usage of this module. This module is not yet
on CPAN, but will be available soon.

=head1 AUTHOR

Andy Grundman, E<lt>andy@hybridized.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Andy Grundman

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
