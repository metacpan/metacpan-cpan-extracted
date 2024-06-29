package Thrift::API::HiveClient2::Compat;
$Thrift::API::HiveClient2::Compat::VERSION = '0.026';
{
  $Thrift::API::HiveClient2::Compat::DIST = 'Thrift-API-HiveClient2';
}

use strict;
use warnings;
use 5.010;

use Thrift;

# Compatibility layer for the changes in the new versions.
#
# To be removed in the near future to break free from older releases of Thrift.

BEGIN {
    if ( ! defined &TType::STOP ) {
        # >= 0.11.0
        # Yes, the naming is broken in Thrift:: since forever
        require Thrift::Type;
        require Thrift::MessageType;
        require Thrift::Exception;
        *TType::                 = *Thrift::TType::;
        *TMessageType::          = *Thrift::TMessageType::;
        *TApplicationException:: = *Thrift::TApplicationException::;
    }
}

# More things to consider
# [1]
# eval { require Thrift::SSLSocket; } or do { require Thrift::Socket; }
# [2]
# Thrift::HttpClient setRecvTimeout() and setSendTimeout() are deprecated.
# Use setTimeout instead.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Thrift::API::HiveClient2::Compat

=head1 VERSION

version 0.026

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Morel & Booking.com. Portions are (c) R.Scaffidi, Thrift files are (c) Apache Software Foundation.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
