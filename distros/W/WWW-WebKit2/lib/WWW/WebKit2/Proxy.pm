package WWW::WebKit2::Proxy;

=head1 NAME

WWW::WebKit2::Proxy

=head1 DESCRIPTION

Proxy related attributes and methods


=head2 PROPERTIES

=cut

use Moose::Role;

has 'proxy_uri' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has 'proxy_ignored_hosts' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

=head2 set_proxy

Set proxy by providing an uri and optional ignore_hosts-param
(list of hosts that won't go through proxy)

=cut

sub set_proxy {
    my ($self, $uri, $ignore_hosts) = @_;

    die "no proxy-uri provided!" unless $uri;
    $ignore_hosts //= [];

    $self->proxy_uri($uri);
    $self->proxy_ignored_hosts($ignore_hosts);

    my $context = $self->view->get_context;
    my $proxy_settings = Gtk3::WebKit2::NetworkProxySettings->new($uri, $ignore_hosts);
    $context->set_network_proxy_settings("WEBKIT_NETWORK_PROXY_MODE_CUSTOM", $proxy_settings);

    return;
}

1;

=head1 AUTHOR

Jason Shaun Carty <jc@atikon.com>,
Philipp Voglhofer <pv@atikon.com>,
Philipp A. Lehner <pl@atikon.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Jason Shaun Carty, Philipp Voglhofer and Philipp A. Lehner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
