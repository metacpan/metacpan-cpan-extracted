package Unblock::WebSocket::_Native;

use strict;
use warnings;

use Unblock::WebSocket ();

1;

__END__

=head1 NAME

Unblock::WebSocket::_Native - private native WebSocket engine

=head1 DESCRIPTION

This module is private. It exposes the native protocol engine used by
Unblock::WebSocket and the versioned C adapter ABI used by optimized native
transport integrations.

The public WebSocket API does not depend on these methods.

=cut
