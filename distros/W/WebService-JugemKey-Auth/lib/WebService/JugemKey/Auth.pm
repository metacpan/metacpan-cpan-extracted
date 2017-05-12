package WebService::JugemKey::Auth;

use strict;
use warnings;
our $VERSION = '0.04';

use base qw (Class::Accessor::Fast Class::ErrorHandler);

use URI;
use LWP::UserAgent;
use Digest::HMAC;
use Digest::SHA1;
use DateTime;
use DateTime::Format::W3CDTF;
use Carp;
use XML::Atom::Entry;

__PACKAGE__->mk_accessors(qw(api_key secret perms));

my $jugemkey_url = 'https://secure.jugemkey.jp';
my $auth_api_url = 'http://api.jugemkey.jp/api/auth';

sub uri_to_login {
    my $self = shift;
    my %params = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    my $uri = URI->new($jugemkey_url);

    my $callback_url = URI->new($params{callback_url});
    delete($params{callback_url});
    $callback_url->query_form( %params );

    my $request = {
        api_key      => $self->api_key,
        perms        => $self->perms,
        callback_url => $callback_url->as_string,
    };

    $uri->query_form(
        api_sig => $self->api_sig($request),
        mode    => 'auth_issue_frob',
        %$request,
    );
    return $uri;
}

sub api_sig {
    my ($self, $args) = @_;

    my $hmac = Digest::HMAC->new($self->secret, 'Digest::SHA1');
    for my $key (sort {$a cmp $b} keys %{$args}) {
        my $value = $args->{$key} ? $args->{$key} : '';
        $hmac->add($value);
    }
    return $hmac->hexdigest;
}

sub get_token {
    my $self = shift;
    my $frob = shift or croak "Invalid argumet (no frob)";

    my $created = DateTime::Format::W3CDTF->new->format_datetime(DateTime->now);
    my $sig = $self->api_sig({
        api_key => $self->api_key,
        created => $created,
        frob    => $frob,
    });

    my $req = HTTP::Request->new(GET => "$auth_api_url/token");
    $req->header('X-JUGEMKEY-API-KEY',     $self->api_key);
    $req->header('X-JUGEMKEY-API-FROB',    $frob);
    $req->header('X-JUGEMKEY-API-CREATED', $created);
    $req->header('X-JUGEMKEY-API-SIG',     $sig);

    my $res = $self->ua->request($req);
    return $self->error("Error on GET token: " . $self->_extract_error($res->content))
        unless $res->code == 200;

    my $entry = XML::Atom::Entry->new(Stream => \$res->content);

    my $pp = XML::Atom::Namespace->new( auth => 'http://paperboy.co.jp/atom/auth#' );
    return WebService::JugemKey::Auth::User->new({
        name  => $entry->title,
        token => $entry->get($pp, 'token'),
    });
}

sub get_user {
    my $self = shift;
    my $token = shift or croak "Invalid argument (no token)";

    my $created = DateTime::Format::W3CDTF->new->format_datetime(DateTime->now);
    my $sig = $self->api_sig({
        api_key => $self->api_key,
        created => $created,
        token   => $token,
    });

    my $req = HTTP::Request->new(GET => "$auth_api_url/user");
    $req->header('X-JUGEMKEY-API-KEY',     $self->api_key);
    $req->header('X-JUGEMKEY-API-TOKEN',   $token);
    $req->header('X-JUGEMKEY-API-CREATED', $created);
    $req->header('X-JUGEMKEY-API-SIG',     $sig);

    my $res = $self->ua->request($req);
    return $self->error("Error on GET user: " . $self->_extract_error($res->content))
        unless $res->code == 200;
    my $entry = XML::Atom::Entry->new(Stream => \$res->content);

    return WebService::JugemKey::Auth::User->new({
        name  => $entry->title,
    });
}

sub ua {
    my $self = shift;
    if (@_) {
        $self->{_ua} = shift;
    } else {
        $self->{_ua} and return $self->{_ua};
        $self->{_ua} = LWP::UserAgent->new;
        $self->{_ua}->agent(join '/', __PACKAGE__, __PACKAGE__->VERSION);
    }
    $self->{_ua};
}

sub _extract_error {
    my ($self, $error) = @_;

    while ($error =~ /<error>([^<]*)<\/error>/g) {
        return $1;
    }
}

package WebService::JugemKey::Auth::User;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(name token));


1;
__END__

=head1 NAME

WebService::JugemKey::Auth - Perl interface to the JugemKey Authentication API

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

  use WebService::JugemKey::Auth;

  my $api = WebService::JugemKey::Auth->new({
     api_key => '...',
     secret  => '...',
  });

  # create login uri
  my $uri = $api->uri_to_login({
      callback_url => 'http://your_callback_url_here/',
      param1 => 'value1',
      param2 => 'value2',
  });
  print $uri->as_string;

  # exchange frob for token
  my $frob = $q->param('frob');
  my $user = $api->get_token($frob) or die "Couldn't get token: " . $api->errstr;
  $user->name;
  $user->token;

  # get user info from token
  my $user = $api->get_user($token) or die "Couldn't get user: " . $api->errstr;
  $user->name;

=head1 DESCRIPTION

A simple interface for using the JugemKey Auththentication API.
L<http://jugemkey.jp/api/auth/>

=head1 METHODS

=over 6

=item new({ api_key => '...', secret => '...' })

Contructs a WerbService::JugemKey::Auth object.It requires 'api_key' and 'secret' you can get from the JugemKey web site. (L<https://secure.jugemkey.jp/?mode=auth_top>)

=item uri_to_login({ %options })

Returns a L<URI> object that points the JugemKey login url with required parameters.
You must specify callback_url parameter like this.

  uri_to_login({ callback_url => 'http://your_callback_url/' })

If you need a query string with the callback_url, you can specify it like this.

  uri_to_login({
      callback_url => 'http://your_callback_url/',
      param1       => 'value1',
      param2       => 'value2',
  })

In this example, a JugemKey user returns to http://your_callback_url/?param1=value1&param2=value2&frob=xxxxxxxxxxxxxxxx after authenticated by the JugemKey.A frob is used for getting a token and a user information.

=item get_token($frob)

Passes a frob to the JugemKey Auth API and returns a WebService::JugemKey::Auth::User object associated with the JugemKey user.This user object has some accessors for getting JugemKey user information.

=over 2

=item name()

Returns an account name on the JugemKey.

=item token()

Returns a token associated with the JugemKey logged-in user.
You can use this token for getting a user information again or authenticating with other paperboy&co. Web Service APIs.

=back

=item get_user($token)

Passes a token to the JugemKey Auth API and returns a WebService::JugemKey::Auth::User object associated with the JugemKey user.This user object has some accessors for getting JugemKey user information.

=over 1

=item name()

Returns an account name on the JugemKey.

=back

=item api_sig($request)

Generates a message authentication code with HMAC_SHA1.

=item ua()

Set/Get a user-agent name.

=back

=head1 SEE ALSO

JugemKey Authentication API L<http://jugemkey.jp/api/auth/>


This module's interface and code are inspired by L<Hatena::API::Auth>.
Thanks to Naoya Ito and Hatena.

=head1 AUTHOR

Gosuke Miyashita, C<< <gosukenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-jugemkey-auth at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-JugemKey-Auth>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::JugemKey::Auth

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-JugemKey-Auth>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-JugemKey-Auth>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-JugemKey-Auth>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-JugemKey-Auth>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 paperboy&co., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
