package WWW::Suffit::Server::API;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::API - The Suffit API controller

=head1 SYNOPSIS

    use WWW::Suffit::Server::API;

=head1 DESCRIPTION

The Suffit API controller

=head1 METHODS

List of internal methods

=head2 api

See L<WWW::Suffit::API/"GET /api">

=head2 check

See L<WWW::Suffit::API/"GET /api/check">

=head2 status

See L<WWW::Suffit::API/"GET /api/status">

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit>, L<WWW::Suffit::Server>, L<WWW::Suffit::API>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.01';

use Mojo::Base 'Mojolicious::Controller';

use POSIX qw/ strftime /;

use Mojo::JSON qw/ true false /;
use Mojo::Date;

use WWW::Suffit::API;
use WWW::Suffit::Const qw/ :dicts DIGEST_ALGORITHMS /;

sub api {
    my $self = shift;
    my $now = time;
    my $status = 1;
    my $code = "E0000";
    my $message = "Ok";
    my $username = $self->stash('username');

    # Extended data of user
    my $user = $self->authdb->cached_user($username);
    return $self->reply->json_error($self->authdb->error) if $self->authdb->error;

    return $self->render(json => {
            status          => $status ? true : false,
            code            => $code,
            message         => $message,
            version         => $self->app->project_version,
            api_version     => WWW::Suffit::API->VERSION,
            generated       => $now,
            datetime        => Mojo::Date->new($now)->to_datetime, # RFC 3339
            requestid       => $self->req->request_id,
            remote_addr     => $self->remote_ip($self->app->trustedproxies),
            base_url        => $self->base_url,
            token           => $self->token,
            public_key      => $self->app->public_key,
            #csrf            => $self->csrf_token // '',
            year            => strftime('%Y', localtime $now),
            route           => $self->current_route // 'root',

            # Authorized only
            $user->is_authorized ? (
                algorithms      => DIGEST_ALGORITHMS,
                methods         => HTTP_METHODS,
                providers       => AUTHZ_PROVIDERS,
                entities        => AUTHZ_ENTITIES,
                operators       => AUTHZ_OPERATOTS,

                # User information
                user => {
                    username    => $username,
                    name        => $self->stash('name'),
                    email       => $self->stash('email'),
                    email_md5   => $self->stash('email_md5'),
                    role        => $self->stash('role'),
                    groups      => $self->stash('groups'),
                    expiration  => $self->stash('expiration'), # Session expiration time (no user data!)
                    expires     => $self->stash('expires'), # Cache expiration time
                    # Extended fields
                    attributes  => $user->attributes // '',
                    flags       => $user->flags || 0,
                    public_key  => $user->public_key // '',
                    comment     => $user->comment // '',
                },

                # Fies & Directories
                files => {
                    homedir     => $self->app->home->to_string,
                    datadir     => $self->app->datadir,
                    documentroot=> $self->app->documentroot,
                    tempdir     => $self->app->tempdir,
                    static_paths=> $self->app->static->paths,
                    render_paths=> $self->app->renderer->paths,
                    #configobj   => $self->app->configobj->conf, # $self->dumper()
                    #namespaces  => $self->app->routes->namespaces,
                    #name        => $self->match->endpoint->name, # Route name
                    #stash       => $self->dumper($self->stash),
                    #config      => $self->config,
                },
            ) : (),
        });
}
sub check {
    my $self = shift;
    my $status = 1;
    my $now = time;

    # Render
    return $self->render(json => {
        status          => $status ? true : false,
        code            => "E0000",
        message         => "Ok",
        version         => $self->app->project_version,
        project         => $self->app->project_name,
        api_version     => WWW::Suffit::API->VERSION,
        time            => $now,
        datetime        => Mojo::Date->new($now)->to_datetime, # RFC 3339
        requestid       => $self->req->request_id,
        remote_addr     => $self->remote_ip($self->app->trustedproxies),
        base_url        => $self->base_url,
    });
}
sub status {
    my $self = shift;
    my $status = 1;
    my $now = time;
    $self->timing->begin('stuff');

    # . . . user code here . . .

    # Render
    return $self->render(json => {
        status          => $status ? true : false,
        time            => $now,
        datetime        => Mojo::Date->new($now)->to_datetime, # RFC 3339
        elapsed         => $self->timing->elapsed('stuff') // 0,
        base_url        => $self->base_url,
    });
}

1;

__END__
