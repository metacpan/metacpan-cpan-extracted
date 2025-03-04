package WebService::Simplenote;

# ABSTRACT: Note-taking through simplenoteapp.com

# TODO: Net::HTTP::Spore?

our $VERSION = '0.2.2';

use v5.10;
use open qw(:std :utf8);
use Moose;
use MooseX::Types::Path::Class;
use JSON;
use LWP::UserAgent;
use HTTP::Cookies;
use Log::Any qw//;
use DateTime;
use MIME::Base64 qw//;
use Try::Tiny;
use WebService::Simplenote::Note;
use Method::Signatures;
use namespace::autoclean;

has ['email', 'password'] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has _token => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_logged_in',
);

has no_server_updates => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 0,
);

has page_size => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => 20,
);

has logger => (
    is       => 'ro',
    isa      => 'Object',
    lazy     => 1,
    required => 1,
    default  => sub { return Log::Any->get_logger },
);

has _uri => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'https://simple-note.appspot.com/api2',
    required => 1,
);

has _ua => (
    is         => 'ro',
    isa        => 'LWP::UserAgent',
    required   => 1,
    lazy_build => 1,
);

method _build__ua {

    my $headers = HTTP::Headers->new(Content_Type => 'application/json',);

    # XXX is it worth saving cookie?? How is password more valuable than auth token?
    # logging in is only a fraction of a second!
    my $ua = LWP::UserAgent->new(
        agent           => "WebService::Simplenote/$VERSION",
        default_headers => $headers,
        env_proxy       => 1,
        cookie_jar      => HTTP::Cookies->new,
    );

    return $ua;
}

# Connect to server and get a authentication token
method _login {
    my $content = MIME::Base64::encode_base64(sprintf 'email=%s&password=%s',
        $self->email, $self->password);

    $self->logger->debug('Network: getting auth token');

    # the login uri uses api instead of api2 and must always be https
    my $response =
      $self->_ua->post('https://simple-note.appspot.com/api/login',
        Content => $content);

    if (!$response->is_success) {
        die 'Error logging into Simplenote server: '
          . $response->status_line . "\n";
    }

    $self->_token($response->content);
    return 1;
}

method _build_req_uri(Str $path, HashRef $options?) {
    my $req_uri = sprintf '%s/%s', $self->_uri, $path;

    if (!$self->has_logged_in) {
        $self->_login;
    }

    return $req_uri if !defined $options;

    $req_uri .= '?';
    while (my ($option, $value) = each %$options) {
        $req_uri .= "&$option=$value";
    }

    return $req_uri;
}

method _get_remote_index_page(Str $mark?) {
    my $notes;

    my $req_uri = $self->_build_req_uri('index', {length => $self->page_size});

    if (defined $mark) {
        $self->logger->debug('Network: retrieving next page');
        $req_uri .= '&mark=' . $mark;
    }

    $self->logger->debug('Network: retrieving ' . $req_uri);

    my $response = $self->_ua->get($req_uri);
    if (!$response->is_success) {
        $self->logger->error('Network: ' . $response->status_line);
        return;
    }

    my $index = decode_json($response->content);

    if ($index->{count} > 0) {
        $self->logger->debugf('Network: Index returned [%s] notes',
            $index->{count});

        # iterate through notes in index and load into hash
        foreach my $i (@{$index->{data}}) {
            $notes->{$i->{key}} = WebService::Simplenote::Note->new($i);
        }

    } elsif ($index->{count} == 0 && !exists $index->{mark}) {
        $self->logger->debugf('Network: No more pages to retrieve');
    } elsif ($index->{count} == 0) {
        $self->logger->debugf('Network: No notes found');
    }

    if (exists $index->{mark}) {
        return ($notes, $index->{mark});
    }

    return $notes;
}

# Get list of notes from simplenote server
# TODO since, length options
method get_remote_index {
    $self->logger->debug('Network: getting note index');

    my ($notes, $mark) = $self->_get_remote_index_page;

    while (defined $mark) {
        my $next_page;
        ($next_page, $mark) = $self->_get_remote_index_page($mark);
        @$notes{keys %$next_page} = values %$next_page;
    }

    $self->logger->infof('Network: found %i remote notes',
        scalar keys %$notes);
    return $notes;
}

# Given a local file, upload it as a note at simplenote web server
method put_note(WebService::Simplenote::Note $note) {

    if ($self->no_server_updates) {
        $self->logger->warn('Sending notes to the server is disabled');
        return;
    }

    my $req_uri = $self->_build_req_uri('data');

    if (defined $note->key) {
        $self->logger->infof('[%s] Updating existing note', $note->key);
        $req_uri .= '/' . $note->key,;
    } else {
        $self->logger->debug('Uploading new note');
    }

    $self->logger->debug("Network: POST to [$req_uri]");

    my $content = $note->serialise;

    my $response = $self->_ua->post($req_uri, Content => $content);

    if (!$response->is_success) {
        $self->logger->errorf('Failed uploading note: %s',
            $response->status_line);
        return;
    }

    my $note_tmp = WebService::Simplenote::Note->new($response->content);

    # a brand new note will have a key generated remotely
    if (!defined $note->key) {
        return $note_tmp->key;
    }

    #TODO better return values
    return;
}

# Save local copy of note from Simplenote server
method get_note(Str $key) {
    $self->logger->infof('Retrieving note [%s]', $key);

    # TODO are there any other encoding options?
    my $req_uri = $self->_build_req_uri("data/$key");
    $self->logger->debug("Network: GETting [$req_uri]");
    my $response = $self->_ua->get($req_uri);

    if (!$response->is_success) {
        $self->logger->errorf('[%s] could not be retrieved: %s',
            $key, $response->status_line);
        return;
    }

    my $note = WebService::Simplenote::Note->new($response->content);

    return $note;
}

# Delete specified note from Simplenote server
method delete_note(WebService::Simplenote::Note $note) {

    if ($self->no_server_updates) {
        $self->logger->warnf(
            '[%s] Attempted to delete note when "no_server_updates" is set',
            $note->key);
        return;
    }

    if (!$note->deleted) {
        $self->logger->warnf(
            '[%s] Attempted to delete note which was not marked as trash',
            $note->key);
        return;
    }

    $self->logger->infof('[%s] Deleting from trash', $note->key);
    my $req_uri = $self->_build_req_uri('data/' . $note->key);
    $self->logger->debug("Network: DELETE on [$req_uri]");
    my $response = $self->_ua->delete($req_uri);

    if (!$response->is_success) {
        $self->logger->errorf('[%s] Failed to delete note from trash: %s',
            $note->key, $response->status_line);
        $self->logger->debug("Uri: [$req_uri]");
        return;
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers Fletcher T. Penney github

=head1 NAME

WebService::Simplenote - Note-taking through simplenoteapp.com

=head1 VERSION

version 0.2.2

=head1 SYNOPSIS

  use WebService::Simplenote;
  use WebService::Simplenote::Note;

  my $sn = WebService::Simplenote->new(
      email    => $email,
      password => $password,
  );

  my $notes = $sn->get_remote_index;

  foreach my $note_id (keys %$notes) {
      say "Retrieving note id [$note_id]";
      my $note = $sn->get_note($note_id);
      printf "[%s] %s\n %s\n",
          $note->modifydate->iso8601,
          $note->title,
          $note->content;
  }

  my $new_note = WebService::Simplenote::Note->new(
      content => "Some stuff",
  );

  $sn->put_note($new_note);

=head1 DESCRIPTION

This module proves v2.1.5 API access to the cloud-based note software at
L<Simplenote|https://simplenoteapp.com>.

=head1 ERRORS

Will C<die> if unable to connect/login. Returns C<undef> for other errors.

=head1 METHODS

=over

=item WebService::Simplenote->new($args)

Requires the C<email> and C<password> for your simplenote account. You can also
provide a L<Log::Any> compatible C<logger>.

=item get_remote_index

Returns a hashref of L<WebService::Simplenote::Note|notes>. The notes are keyed by id.

=item get_note($note_id)

Retrieves a note from the remote server and returns it as a L<WebService::Simplenote::Note>.
C<$note_id> is an alphanumeric key generated on the server side.

=item put_note($note)

Puts a L<WebService::Simplenote::Note> to the remote server

=item delete_note($note_id)

Delete the specified note from the server. The note should be marked as C<deleted>
beforehand.

=back

=head1 TESTING

Setting the environment variables C<SIMPLENOTE_USER> and C<SIMPLENOTE_PASS> will enable remote tests.
If you want to run the remote tests B<MAKE SURE YOU MAKE A BACKUP OF YOUR NOTES FIRST!!>

=head1 SEE ALSO

Designed for use with Simplenote:

<http://www.simplenoteapp.com/>

Based on SimplenoteSync:

<http://fletcherpenney.net/other_projects/simplenotesync/>

=head1 AUTHORS

=over 4

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Fletcher T. Penney <owner@fletcherpenney.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Ioan Rogers.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/WebService-Simplenote/issues>.

=head1 SOURCE

The development version is on github at L<https://github.com/ioanrogers/WebService-Simplenote>
and may be cloned from L<git://github.com/ioanrogers/WebService-Simplenote.git>

=cut
