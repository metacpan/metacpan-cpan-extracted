package WWW::Suffit::Plugin::API;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::API - The API Suffit plugin

=head1 SYNOPSIS

    use Mojo::Base 'WWW::Suffit::Server';

    sub startup {
        my $self = shift->SUPER::startup();
        $self->plugin('API', {
            prefix_path => "/api",
            prefix_name => "api",
        });

        # . . .
    }

    sub startup {
        my $self = shift->SUPER::startup(
            init_api_routes => 'on',
            api_routes_opts => {
                prefix_path => "/api",
                prefix_name => "api",
            }
        );

        # . . .
    }

=head1 DESCRIPTION

The API Suffit plugin

This plugin requires L<WWW::Suffit::Plugin::AuthDB> plugin

=head1 OPTIONS

This plugin supports the following options

=head2 prefix_name

    prefix_name => "api"

This option defines prefix of api route name

Default: 'api'

=head2 prefix_path

    prefix_path => "/api"

This option defines prefix of api route

Default: '/api'

=head1 HELPERS

This plugin implements the following helpers

=head2 api_prefix_name

    my $api_prefix_name = $c->api_prefix_name;

Returns the api prefix name

Default: api

=head2 api_prefix_path

    my $api_prefix_path = $c->api_prefix_path;

Returns the api prefix path

Default: /api

=head1 METHODS

This plugin inherits all methods from L<Mojolicious::Plugin> and implements the following new ones

=head2 register

This method register the plugin and helpers in L<Mojolicious> application

    $plugin->register(Mojolicious->new, {
        prefix_path => "/api",
        prefix_name => "api",
    });

Register plugin in L<Mojolicious> application

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit::Server>, L<WWW::Suffit::AuthDB>, L<WWW::Suffit::Plugin::AuthDB>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($plugin, $app, $opts) = @_; # $self = $plugin
    $app->raise("Can't initialize the API plugin: the AuthDB plugin required")
        unless exists $app->renderer->helpers->{'authdb'};
    $opts //= {};
    my $pathpfx = $opts->{prefix_path} || '/api';
    my $namepfx = $opts->{prefix_name} || $pathpfx;
       $namepfx =~ s/[^a-z0-9_\-]//g;
       $namepfx ||= 'api';

    # Add helpers to quick access to api prefixes
    $app->helper('api_prefix_name' => sub { "$namepfx" });
    $app->helper('api_prefix_path' => sub { "$pathpfx" });

    # General routes related to the Suffit API
    my $r = $app->routes->under('/')->to('API#is_connected')->name('__authdb');

    $r->get(sprintf('%s/status', $pathpfx))->to('API#api')->name(sprintf('%s-status', $namepfx));
    $r->get(sprintf('%s/check', $pathpfx))->to('API#check')->name(sprintf('%s-check', $namepfx));
    $r->post(sprintf('%s/authorize',$pathpfx))->to('API::Auth#authorize' => {
            token_type => 'access',
            skip_authdb_connect => 1,
        })->name(sprintf('%s-authorize', $namepfx));

    # API routes with token or cookie authorization
    my $authorized = $r->under($pathpfx)->to('API::Auth#is_authorized')->name($namepfx);
    $authorized->get('/')->to('API#api')->name(sprintf('%s-data', $namepfx));

    # API::V1
    $authorized->post('/v1/authn')->to('API::V1#authn')->name(sprintf('%s-v1-authn', $namepfx));
    $authorized->post('/v1/authz')->to('API::V1#authz')->name(sprintf('%s-v1-authz', $namepfx));
    $authorized->get('/v1/publicKey')->to('API::V1#public_key')->name(sprintf('%s-v1-publickey', $namepfx));

    # API::NoAPI
    $authorized->get('/file')->to('API::NoAPI#file_list')->name(sprintf('%s-file-list', $namepfx));
    $authorized->get('/file/*filepath')->to('API::NoAPI#file_download')->name(sprintf('%s-file-download', $namepfx));
    $authorized->put('/file/*filepath')->to('API::NoAPI#file_upload')->name(sprintf('%s-file-upload', $namepfx));
    $authorized->delete('/file/*filepath')->to('API::NoAPI#file_remove')->name(sprintf('%s-file-remove', $namepfx));
}

1;

__END__

