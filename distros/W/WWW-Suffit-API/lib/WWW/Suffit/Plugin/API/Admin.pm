package WWW::Suffit::Plugin::API::Admin;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::API::Admin - The Admin API Suffit plugin

=head1 SYNOPSIS

    use Mojo::Base 'WWW::Suffit::Server';

    sub startup {
        my $self = shift->SUPER::startup();
        $self->plugin('API::Admin', {
            prefix_path => "/admin",
            prefix_name => "admin",
        });

        # . . .
    }

    sub startup {
        my $self = shift->SUPER::startup(
            init_admin_routes => 'on',
            admin_routes_opts => {
                prefix_path => "/admin",
                prefix_name => "admin",
            }
        );

        # . . .
    }

=head1 DESCRIPTION

The Admin API Suffit plugin

This plugin requires L<WWW::Suffit::Plugin::API> plugin

=head1 OPTIONS

This plugin supports the following options

=head2 prefix_name

    prefix_name => "admin"

This option defines prefix of admin api route name

Default: 'admin'

=head2 prefix_path

    prefix_path => "/admin"

This option defines prefix of admin api route

Default: '/admin'

=head1 METHODS

This plugin inherits all methods from L<Mojolicious::Plugin> and implements the following new ones

=head2 register

This method register the plugin and helpers in L<Mojolicious> application

    $plugin->register(Mojolicious->new, {
        prefix_path => "/admin",
        prefix_name => "admin",
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

use WWW::Suffit::Const qw/ USERNAME_REGEXP /;

sub register {
    my ($plugin, $app, $opts) = @_; # $self = $plugin
    $app->raise("Can't initialize the API::Admin plugin: the API plugin required")
        unless exists $app->renderer->helpers->{'api_prefix_name'};
    $opts //= {};
    my $pathpfx = $opts->{prefix_path} || '/admin';
    my $namepfx = $opts->{prefix_name} || 'admin';
       $namepfx =~ s/[^a-z0-9_\-]//g;
       $namepfx ||= 'admin';
       $namepfx = sprintf("%s-%s", $app->api_prefix_name, $namepfx) if $app->api_prefix_name;

    # Get base API route with token/cookie authorization
    my $r = $app->routes;
    my $api = $r->lookup($app->api_prefix_name // 'api');
    $r->{reverse} = undef; # Force flush Mojolicious routes cache

    # Admin routes
    my $admin = $api->under($pathpfx)->name($namepfx); # /api/admin

    # API::Admin *2
    $admin->get('/settings')->to('API::Admin#settings')->name(sprintf('%s-settings', $namepfx));
    $admin->post('/settings')->to('API::Admin#settings')->name(sprintf('%s-settings-save', $namepfx));

    # Users *8
    $admin->get('/user')->to('API::Admin#user_get')->name(sprintf('%s-user-all', $namepfx));
    $admin->get('/user/:username' => [username => USERNAME_REGEXP])->to('API::Admin#user_get')->name(sprintf('%s-user-get', $namepfx));
    $admin->put('/user/:username' => [username => USERNAME_REGEXP])->to('API::Admin#user_set')->name(sprintf('%s-user-set', $namepfx));
    $admin->post('/user')->to('API::Admin#user_set')->name(sprintf('%s-user-add', $namepfx));
    $admin->delete('/user/:username' => [username => USERNAME_REGEXP])->to('API::Admin#user_del')->name(sprintf('%s-user-del', $namepfx));
    $admin->put('/user/:username/passwd' => [username => USERNAME_REGEXP])->to('API::Admin#user_passwd')->name(sprintf('%s-user-passwd', $namepfx));
    $admin->get('/search/user')->to('API::Admin#user_search')->name(sprintf('%s-user-search', $namepfx));
    $admin->get('/user/:username/groups' => [username => USERNAME_REGEXP])->to('API::Admin#user_groups')->name(sprintf('%s-user-groups', $namepfx));

    # Groups *7
    $admin->get('/group')->to('API::Admin#group_get')->name(sprintf('%s-group-all', $namepfx));
    $admin->get('/group/:groupname' => [groupname => USERNAME_REGEXP])->to('API::Admin#group_get')->name(sprintf('%s-group-get', $namepfx));
    $admin->put('/group/:groupname' => [groupname => USERNAME_REGEXP])->to('API::Admin#group_set')->name(sprintf('%s-group-set', $namepfx));
    $admin->post('/group')->to('API::Admin#group_set')->name(sprintf('%s-group-add', $namepfx));
    $admin->delete('/group/:groupname' => [groupname => USERNAME_REGEXP])->to('API::Admin#group_del')->name(sprintf('%s-group-del', $namepfx));
    $admin->get('/group/:groupname/members' => [groupname => USERNAME_REGEXP])->to('API::Admin#group_members')->name(sprintf('%s-group-members', $namepfx));
    $admin->post('/group/:groupname/enroll' => [groupname => USERNAME_REGEXP])->to('API::Admin#group_enroll')->name(sprintf('%s-group-enroll', $namepfx));

    # Realms *6
    $admin->get('/realm')->to('API::Admin#realm_get')->name(sprintf('%s-realm-all', $namepfx));
    $admin->get('/realm/:realmname' => [realmname => USERNAME_REGEXP])->to('API::Admin#realm_get')->name(sprintf('%s-realm-get', $namepfx));
    $admin->put('/realm/:realmname' => [realmname => USERNAME_REGEXP])->to('API::Admin#realm_set')->name(sprintf('%s-realm-set', $namepfx));
    $admin->post('/realm')->to('API::Admin#realm_set')->name(sprintf('%s-realm-add', $namepfx));
    $admin->delete('/realm/:realmname' => [realmname => USERNAME_REGEXP])->to('API::Admin#realm_del')->name(sprintf('%s-realm-del', $namepfx));
    $admin->get('/requirement')->to('API::Admin#requirement_get')->name(sprintf('%s-requirement-get', $namepfx));

    # Routes *8
    $admin->get('/route')->to('API::Admin#route_get')->name(sprintf('%s-route-all', $namepfx));
    $admin->get('/route/:routename' => [routename => USERNAME_REGEXP])->to('API::Admin#route_get')->name(sprintf('%s-route-get', $namepfx));
    $admin->put('/route/:routename' => [routename => USERNAME_REGEXP])->to('API::Admin#route_set')->name(sprintf('%s-route-set', $namepfx));
    $admin->post('/route')->to('API::Admin#route_set')->name(sprintf('%s-route-add', $namepfx));
    $admin->delete('/route/:routename' => [routename => USERNAME_REGEXP])->to('API::Admin#route_del')->name(sprintf('%s-route-del', $namepfx));
    $admin->get('/search/route')->to('API::Admin#route_search')->name(sprintf('%s-route-search', $namepfx));
    $admin->get('/sysroute')->to('API::Admin#route_sysget')->name(sprintf('%s-route-sysget', $namepfx));
    $admin->post('/sysroute')->to('API::Admin#route_sysadd')->name(sprintf('%s-route-sysadd', $namepfx));
}

1;

__END__
