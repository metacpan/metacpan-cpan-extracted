package WebService::Instapaper;
use 5.008001;
use strict;
use warnings;

use OAuth::Lite::Consumer;
use JSON qw(decode_json);
use Carp qw(croak);

our $VERSION = "0.02";

my $endpoint = "https://www.instapaper.com/api/1.1";

sub new {
  my ($class, %args) = @_;
  my $self = {%args};
  $self->{consumer} = OAuth::Lite::Consumer->new(
    consumer_key => $self->{consumer_key},
    consumer_secret => $self->{consumer_secret}
  );
  bless $self, $class;
}

sub auth {
  my ($self, $username, $password) = @_;
  my $res = $self->{consumer}->obtain_access_token(
    url => $endpoint . '/oauth/access_token',
    params => {
      x_auth_username => $username,
      x_auth_password => $password,
      x_auth_mode => 'client_auth'
    }
  );
  unless ($res) {
    croak 'failed to obtain access token';
  }
  $self->{access_token} = $res->access_token;
}

sub token {
  my ($self, $access_token, $access_secret) = @_;
  $self->{access_token} = OAuth::Lite::Token->new(token => $access_token, secret => $access_secret);
}

sub request {
  my ($self, $method, $path, $params) = @_;
  my $res = $self->{consumer}->request(method => $method, url => $endpoint . $path, token => $self->{access_token}, params => $params);
  unless ($res->is_success) {
    croak "failed to ${method} ${path}";
  }
  $res;
}

sub bookmarks {
  my ($self, %params) = @_;
  my $res = $self->request('POST', '/bookmarks/list', \%params);
  @{decode_json($res->decoded_content)->{bookmarks}};
}

sub add_bookmark {
  my ($self, $url, %params) = @_;
  $params{url} = $url;
  $self->request('POST', '/bookmarks/add', \%params);
}

sub delete_bookmark {
  my ($self, $id) = @_;
  $self->request('POST', '/bookmarks/delete', {bookmark_id => $id});
}

sub archive_bookmark {
  my ($self, $id) = @_;
  $self->request('POST', '/bookmarks/archive', {bookmark_id => $id});
}

sub unarchive_bookmark {
  my ($self, $id) = @_;
  $self->request('POST', '/bookmarks/unarchive', {bookmark_id => $id});
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Instapaper - A client for the Instapaper Full API

=head1 SYNOPSIS

    use WebService::Instapaper;

    my $client = WebService::Instapaper->new(consumer_key => '...', consumer_secret => '...');

    $client->auth('username', 'password');

    # or
    $client->token('access_token', 'access_token_secret');

    # get bookmark list
    my @bookmarks = $client->bookmarks;

    # archive bookmarks
    my $bookmark = shift @bookmarks;
    $client->archive_bookmark($bookmark->{bookmark_id});

=head1 DESCRIPTION

WebService::Instapaper is a client for the Instapepr Full API (https://www.instapaper.com/api)

=over 4

=item new(\%options)

Create new instance of this module. C<%options> should contain following keys: C<consumer_key> and C<consumer_secret>.

=item auth($username, $password)

Authenticate with given C<$username> and C<$password>.

=item token($access_token, $access_secret)

Set existing access token to the instance.

=item bookmarks(\%options)

Return bookmark list. By default, it returns 25 bookmark items.

C<%options> may contain C<limit> to specify the number of results.

    my @many_bookmarks = $client->bookmarks(limit => 100);

=item add_bookmark($url, \%options)

Add new bookmark to Instapaper.

    $client->add_bookmark('http://www.example.org/');

    # with details
    $client->add_bookmark('http://www.example.org/', title => 'Example Article', description => 'This is an example.');

=item delete_bookmark($bookmark_id)

Delete the bookmark.

=item archive_bookmark($bookmark_id)

Archive the bookmark.

=item unarchive_bookmark($bookmark_id)

Unarchive the bookmark.

=back

=head1 LICENSE

Copyright (C) Shun Takebayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shun Takebayashi E<lt>shun@takebayashi.asiaE<gt>

=cut

