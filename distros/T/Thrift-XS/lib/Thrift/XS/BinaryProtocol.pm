package Thrift::XS::BinaryProtocol;

use strict;
use base('Thrift::Protocol');

use Thrift::XS;

# Implementation is in BinaryProtocol.xs

1;
__END__

=head1 NAME

Thrift::XS::BinaryProtocol - Standard binary protocol

=head1 SYNOPSIS

    use Thrift;
    use Thrift::Socket;
    use Thrift::FramedTransport;
    use Thrift::XS::CompactProtocol;
    use MyThriftInterface;
    
    my $socket    = Thrift::Socket->new( $host, $port );
    my $transport = Thrift::FramedTransport->new($socket);
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    my $client    = MyThriftInterface->new($protocol);
    
    $transport->open;
    
    $client->api_call( @args );

=head1 DESCRIPTION

This is the standard Thrift binary protocol.

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
