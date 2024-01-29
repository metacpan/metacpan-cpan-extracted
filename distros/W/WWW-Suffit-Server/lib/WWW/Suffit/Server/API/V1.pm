package WWW::Suffit::Server::API::V1;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::API::V1 - The public Suffit API controller, version 1

=head1 SYNOPSIS

    use WWW::Suffit::Server::API::V1;

=head1 DESCRIPTION

The public Suffit API controller, version 1

=head1 METHODS

List of internal methods

=head2 authn

See L<WWW::Suffit::API/"POST /api/v1/authn">

=head2 authz

See L<WWW::Suffit::API/"POST /api/v1/authz">

=head2 public_key

See L<WWW::Suffit::API/"GET /api/v1/publicKey">

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

our $VERSION = '1.00';

use Mojo::Base 'Mojolicious::Controller';

use Mojo::Path;
use Mojo::URL;

use WWW::Suffit::RefUtil qw/ is_hash_ref /;
use WWW::Suffit::RSA;

sub public_key {
    my $self = shift;
    my $authdb = $self->authdb;
    my $public_key = $authdb->cached_user($authdb->username())->public_key // '';
    return $self->reply->json_error(404 => "E1200" => "No RSA public key found") unless length $public_key;
    return $self->reply->json_ok({public_key => $public_key});
}
sub authn {
    my $self = shift;
    my $username = $self->req->json('/username') // '';
    my $password = $self->req->json('/password') // '';
    my $encrypted = $self->req->json('/encrypted') || 0;
    my $authdb = $self->authdb;
    my $acc_user = $authdb->cached_user($authdb->username());
    my $public_key = $acc_user->public_key // '';
    my $private_key = $acc_user->private_key // '';
    $authdb->clean;

    # Password decrypt
    if ($encrypted && length($password)) {
        return $self->reply->json_error(400 => "E1200" => "No RSA public key found") unless length $public_key;
        return $self->reply->json_error(400 => "E1201" => "No RSA private key found") unless length $private_key;
        my $rsa = WWW::Suffit::RSA->new->private_key($private_key);
        $password = $rsa->decrypt($password); # RSA Decrypt password
        return $self->reply->json_error(500 => "E1202" => $rsa->error || "RSA decrypt error") if $rsa->error;
    }

    # Authentication
    return $self->reply->json_error(
        $authdb->code, $authdb->error || "E1203: Incorrect username or password"
    ) unless $authdb->authen($username, $password); # Unauthenticated

    # Render ok
    return $self->reply->json_ok;
}
sub authz {
    my $self = shift;
    my $authdb = $self->authdb->clean;
    my $username = $self->req->json('/username') // '';
    my $verbose = $self->req->json('/verbose') || 0;
    my $url = $self->req->json('/url') // $self->base_url // '';
    my $uri = Mojo::URL->new($url);
       $username = $uri->username unless length $username;
    my %args = (controller => $self, username => $username);
    $args{client_ip} = $self->req->json('/address') // '';
    $args{method} = $self->req->json('/method') // '';
    $args{path} = $self->req->json('/path') //
        $uri->path->leading_slash(1)->trailing_slash(0)->to_string // '';
    $args{base} = $self->req->json('/base') //
        $uri->path_query("")->path(Mojo::Path->new->leading_slash(0)->trailing_slash(0) )->to_string // '';
    my $headers = $self->req->json('/headers') || {};
    if (is_hash_ref($headers)) {
        my %hdrs = ();
        while (my ($k, $v) = each %$headers) {
            $hdrs{$k} = $v if defined($v) && !ref($v);
        }
        $args{headers} = {%hdrs} if scalar %hdrs;
    }

    # Authorization (External!)
    my $user = $authdb->authz($username, 1);
    return $self->reply->json_error(
        $authdb->code, $authdb->error || "E1204: Access denied"
    ) unless $user; # Unauthorized

    # Access (username is optional)
    return $self->reply->json_error(
        $authdb->code, $authdb->error || "E1205: Access denied by realm restrictions"
    ) unless ($authdb->access(%args)); # Forbidden

    # Render ok
    return $self->reply->json_ok unless $verbose;

    # Render user data
    my %ret = $user->to_hash;
    $ret{address} = $args{client_ip} if length $args{client_ip};
    foreach my $k (qw/method path base/) {
        $ret{$k} = $args{$k} if length $args{$k};
    }
    $ret{headers} = $args{headers} if exists $args{headers};

    return $self->reply->json_ok({%ret});
}

1;

__END__
