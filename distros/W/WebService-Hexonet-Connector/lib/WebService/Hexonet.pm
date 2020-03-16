package WebService::Hexonet;

use 5.026_000;
use strict;
use warnings;
use WebService::Hexonet::Connector;

use version 0.9917; our $VERSION = version->declare('v2.3.0');

1;

__END__

=pod

=head1 NAME

WebService::Hexonet - Namespace package for modules provided by L<HEXONET|https://www.hexonet.net/>.

=head1 DESCRIPTION

This module is just used as namespace package for module provided by L<HEXONET|https://www.hexonet.net/>
and does not provide any further functionality.

=head1 AVAILABLE MODULES

Up to now we provide the following modules:

=over 4

=item L<WebService::Hexonet::Connector|WebService::Hexonet::Connector> - Connector Library for our Backend API.

=back

=head1 LICENSE AND COPYRIGHT

This program is licensed under the L<MIT License|https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE>.

=head1 AUTHOR

L<HEXONET GmbH|https://www.hexonet.net>

=cut
