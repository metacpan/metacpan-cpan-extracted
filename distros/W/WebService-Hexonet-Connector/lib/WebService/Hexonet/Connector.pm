package WebService::Hexonet::Connector;

use 5.030;
use strict;
use warnings;
use WebService::Hexonet::Connector::APIClient;
use WebService::Hexonet::Connector::Column;
use WebService::Hexonet::Connector::Record;
use WebService::Hexonet::Connector::Response;
use WebService::Hexonet::Connector::ResponseParser;
use WebService::Hexonet::Connector::ResponseTemplate;
use WebService::Hexonet::Connector::ResponseTemplateManager;
use WebService::Hexonet::Connector::SocketConfig;

use version 0.9917; our $VERSION = version->declare('v2.10.0');

1;

__END__

=pod

=head1 NAME

WebService::Hexonet::Connector - Connector library for the insanely fast L<HEXONET Backend API|https://www.hexonet.net/>.

=head1 SYNOPSIS

	###############################
	# How to use this Library?
	###############################

	# Install our module by
	cpan WebService::Hexonet::Connector
	# or
	cpanm WebService::Hexonet::Connector
	# NOTE: We suggest to use cpanm (App::cpanminus) for several reasons.

Check the Example provided at L<WebService::Hexonet::Connector::APIClient|WebService::Hexonet::Connector::APIClient>.

=head1 DESCRIPTION

This module is used as namespace.

=head1 AVAILABLE SUBMODULES

We've split our functionality into submodules to give this module a better structure.

=over 4

=item L<WebService::Hexonet::Connector::APIClient|WebService::Hexonet::Connector::APIClient> - API Client functionality.

=item L<WebService::Hexonet::Connector::Column|WebService::Hexonet::Connector::Column> - API Response Data handling as "Column".

=item L<WebService::Hexonet::Connector::Record|WebService::Hexonet::Connector::Record> - API Response Data handling as "Record".

=item L<WebService::Hexonet::Connector::Response|WebService::Hexonet::Connector::Response> - API Response functionality.

=item L<WebService::Hexonet::Connector::ResponseParser|WebService::Hexonet::Connector::ResponseParser> - API Response Parser functionality.

=item L<WebService::Hexonet::Connector::ResponseTemplate|WebService::Hexonet::Connector::ResponseTemplate> - API Response Template functionality.

=item L<WebService::Hexonet::Connector::ResponseTemplateManager|WebService::Hexonet::Connector::ResponseTemplateManager> - API Response Template Manager functionality.

=item L<WebService::Hexonet::Connector::SocketConfig|WebService::Hexonet::Connector::SocketConfig> - API Communication Configuration functionality.

=back

=head1 LICENSE AND COPYRIGHT

This program is licensed under the L<MIT License|https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE>.

=head1 AUTHOR

L<HEXONET GmbH|https://www.hexonet.net>

=cut
