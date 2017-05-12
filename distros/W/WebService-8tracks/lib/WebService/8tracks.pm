package WebService::8tracks;
use Any::Moose;

=pod

=head1 NAME

WebService::8tracks - Handle 8tracks API

=head1 SYNOPSIS

  use WebService::8tracks;

  my $api = WebService::8tracks->new;

  # explore
  my $res = $api->mixes({ sort => 'recent' });
  foreach my $mix (@{$res->{mixes}}) {
      print "$mix->{user}->{name} $mix->{name} id=$mix->{id}\n";
  }

  # listen
  my $session = $api->create_session($res->{mixes}->[0]->{id});
  my $res = $session->play;
  my $media_url = $res->{set}->{track}->{url};
  ...
  $res = $session->next;
  $res = $session->skip;

  # authenticated API
  my $api = WebService::8tracks->new(username => ..., password => ...);
  $api->fav(23); # fav a track

=head1 DESCRIPTION

WebService::8tracks provides Perl interface to 8tracks API.

Currently, all response objects are almost naive hashrefs.

=cut

has 'username', (
    is  => 'rw',
    isa => 'Str',
);

has 'password', (
    is  => 'rw',
    isa => 'Str',
);

has 'user_agent', (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub {
        require LWP::UserAgent;
        return  LWP::UserAgent->new;
    },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

our $VERSION = '0.01';

use WebService::8tracks::Session;
use WebService::8tracks::Response;

use JSON::XS qw(decode_json);
use URI::Escape qw(uri_escape uri_escape_utf8);
use HTTP::Request;

our @CARP_NOT = ( our @ISA, 'WebService::8tracks::Session' );

our $API_BASE_URL = 'http://8tracks.com/';

sub api_url {
    my ($self, $path, $qparam) = @_;

    my $url = "http://api.8tracks.com/$path.json";
    if ($qparam) {
        if (ref $qparam eq 'HASH' && scalar keys %$qparam) {
            my @pairs;
            while (my ($key, $value) = each %$qparam) {
                my $pair = $key . '=';
                if (utf8::is_utf8 $value) {
                    $pair .= uri_escape_utf8 $value;
                } else {
                    $pair .= uri_escape $value;
                }
                push @pairs, $pair;
            }
            $url .= '?' . join '&', @pairs;
        } else {
            $url .= "?$qparam";
        }
    }

    return $url;
}

sub request_api {
    my ($self, $method, $path, $qparam) = @_;

    my $url = $self->api_url($path, $qparam);
    my $req = HTTP::Request->new($method, $url);
    if ($method eq 'POST') {
        $req->header(Content_Length => 0);
    }

    if ($self->username && $self->password) {
        $req->authorization_basic($self->username, $self->password);
    }

    my $res = $self->user_agent->request($req);
    my $api_response = decode_json $res->content;
    return WebService::8tracks::Response->new($api_response);
}

=head1 METHODS

=over 4

=item new

  my $api = WebService::8tracks->new([ username => ..., password => ... ]);

Create API object. Pass username and password args to use methods
that require login (like, fav, follow).

=item mixes([ \%qparam ])

  my $res = $api->mixes({ page => 2 });
  my $res = $api->mixes({ q => 'miles davis' });

List mixes.

=cut

sub mixes {
    my ($self, $qparam) = @_;
    return $self->request_api(GET => 'mixes', $qparam);
}

=item user($id_or_name)

  my $res = $api->user(1);
  my $res = $api->user('remi');

View user info.

=cut

sub user {
    my ($self, $user, $qparam) = @_;
    return $self->request_api(GET => "users/$user", $qparam);
}

=item user_mixes($id_or_name[, \%qparam ])

  my $res = $api->user_mixes(2);
  my $res = $api->user_mixes('dp', { view => 'liked' });

List mixes made by a user.

=cut

sub user_mixes {
    my ($self, $user, $qparam) = @_;
    return $self->request_api(GET => "users/$user/mixes", $qparam);
}

sub _create_play_token {
    my $self = shift;
    my $result = $self->request_api(GET => 'sets/new');
    return $result->{play_token};
}

=item create_session($mix_id)

  my $session = $api->create_session($mix_id);
  my $res = $session->play;
  my $res = $session->next;
  my $res = $session->skip;

Start playing mix. Returns a WebService::8tracks::Session.

=cut

sub create_session {
    my ($self, $mix_id) = @_;

    return WebService::8tracks::Session->new(
        api => $self,
        play_token => $self->_create_play_token,
        mix_id => $mix_id,
    );
}

=item like / unlike / toggle_like($mix_id)

  my $res = $api->toggle_like($mix_id);

Like/unlike/toggle_like a mix. Requires username and password.

=cut

foreach my $like (qw(like unlike toggle_like)) {
    my $code = sub {
        my ($self, $mix_id) = @_;
        return $self->request_api(POST => "mixes/$mix_id/$like");
    };
    no strict 'refs';
    *$like = $code;
}

=item fav / unfav / toggle_fav($track_id)

  my $res = $api->fav($track_id);

Fav/unfav/toggle_fav a track. Requires username and password.

=cut

foreach my $fav (qw(fav unfav toggle_fav)) {
    my $code = sub {
        my ($self, $track_id) = @_;
        return $self->request_api(POST => "tracks/$track_id/$fav");
    };
    no strict 'refs';
    *$fav = $code;
}

=item follow / unfollow / toggle_follow($user_id)

  my $res = $api->follow($user_id);

Follow/unfollow/toggle_follow a user. Requires username and password.

=cut

foreach my $follow (qw(follow unfollow toggle_follow)) {
    my $code = sub {
        my ($self, $user_id) = @_;
        return $self->request_api(POST => "users/$user_id/$follow");
    };
    no strict 'refs';
    *$follow = $code;
}

=back

=cut

1;

__END__

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

8tracks Playback API. L<http://docs.google.com/Doc?docid=0AQstf4NcmkGwZGdia2c5ZjNfNDNjbW01Y2dmZw>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
