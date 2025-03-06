package WWW::Suffit::Plugin::API::User;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::API::User - The User API Suffit plugin

=head1 SYNOPSIS

    use Mojo::Base 'WWW::Suffit::Server';

    sub startup {
        my $self = shift->SUPER::startup();
        $self->plugin('API::User', {
            prefix_path => "/user",
            prefix_name => "user",
        });

        # . . .
    }

    sub startup {
        my $self = shift->SUPER::startup(
            init_user_routes => 'on',
            user_routes_opts => {
                prefix_path => "/user",
                prefix_name => "user",
            }
        );

        # . . .
    }

=head1 DESCRIPTION

The User API Suffit plugin

This plugin requires L<WWW::Suffit::Plugin::API> plugin

=head1 OPTIONS

This plugin supports the following options

=head2 prefix_name

    prefix_name => "user"

This option defines prefix of user api route name

Default: 'user'

=head2 prefix_path

    prefix_path => "/user"

This option defines prefix of user api route

Default: '/user'

=head1 METHODS

This plugin inherits all methods from L<Mojolicious::Plugin> and implements the following new ones

=head2 register

This method register the plugin and helpers in L<Mojolicious> application

    $plugin->register(Mojolicious->new, {
        prefix_path => "/user",
        prefix_name => "user",
    });

Register plugin in L<Mojolicious> application

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit::Server>, L<WWW::Suffit::AuthDB>, L<WWW::Suffit::Plugin::API>

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

use WWW::Suffit::Const qw/ JTI_REGEXP /;

sub register {
    my ($plugin, $app, $opts) = @_; # $self = $plugin
    $app->raise("Can't initialize the API::User plugin: the API plugin required")
        unless exists $app->renderer->helpers->{'api_prefix_name'};
    $opts //= {};
    my $pathpfx = $opts->{prefix_path} || '/user';
    my $namepfx = $opts->{prefix_name} || 'user';
       $namepfx =~ s/[^a-z0-9_\-]//g;
       $namepfx ||= 'user';
       $namepfx = sprintf("%s-%s", $app->api_prefix_name, $namepfx) if $app->api_prefix_name;

    # Get base API route with token/cookie authorization
    my $r = $app->routes;
    my $api = $r->lookup($app->api_prefix_name // 'api');
    $r->{reverse} = undef; # Force flush Mojolicious routes cache

    # User routes
    my $u = $api->under($pathpfx)->name($namepfx); # /api/user

    # User routes
    $u->get('/')->to('API::User#user_get')->name(sprintf('%s-data', $namepfx));
    $u->put('/')->to('API::User#user_set')->name(sprintf('%s-set', $namepfx));
    $u->patch('/passwd')->to('API::User#passwd')->name(sprintf('%s-passwd', $namepfx));
    $u->post('/genkeys')->to('API::User#genkeys')->name(sprintf('%s-genkeys', $namepfx));
    $u->get('/token')->to('API::User#token_get')->name(sprintf('%s-token-get', $namepfx));
    $u->post('/token')->to('API::User#token_set')->name(sprintf('%s-token-set', $namepfx));
    $u->delete('/token/:jti' => [jti => JTI_REGEXP])->to('API::User#token_del')->name(sprintf('%s-token-del', $namepfx));
}

1;

__END__
