package VPNDetection::Database;

use strict;
use warnings;

use Carp ();

use VPNDetection::Error;

our $VERSION = '1.4.0';

# The dataset FAMILIES your organization is licensed to download. A license
# covers a family, while a download names one of its versions, so the ids the
# download and checksum calls take come from each family's `versions`.
sub list {
    my $self = shift;
    $self->_assert_blocking_ok('list');
    return $self->{client}->_wait($self->list_p(@_));
}

sub list_p {
    my ($self, %options) = @_;
    return $self->_body_p('list', \%options, '/api/v1/database/list')
        ->then(sub { $_[0]->{datasets} });
}

# What is inside one dataset: schema, samples, row count and per-format sizes.
sub metadata {
    my $self = shift;
    $self->_assert_blocking_ok('metadata');
    return $self->{client}->_wait($self->metadata_p(@_));
}

sub metadata_p {
    my ($self, $id, %options) = @_;
    Carp::croak('database->metadata: expected a dataset id') if !defined $id || !length $id;
    return $self->_body_p('metadata', \%options, '/api/v1/database/metadata', id => $id);
}

# The digests published alongside one dataset file.
#
# Returns the WHOLE set rather than one algorithm: which digests a dataset
# publishes is the API's choice, not ours, and picking one here is how a caller
# ends up holding undef against a perfectly healthy API.
sub checksums {
    my $self = shift;
    $self->_assert_blocking_ok('checksums');
    return $self->{client}->_wait($self->checksums_p(@_));
}

sub checksums_p {
    my ($self, $id, $format, %options) = @_;
    _assert_dataset('checksums', $id, $format);
    return $self->_body_p(
        'checksums', \%options, '/api/v1/database/checksum', id => $id, format => $format,
    )->then(sub { $_[0]->{checksums} });
}

# Your organization's recent download attempts, newest first.
sub downloads {
    my $self = shift;
    $self->_assert_blocking_ok('downloads');
    return $self->{client}->_wait($self->downloads_p(@_));
}

sub downloads_p {
    my ($self, %options) = @_;
    my $limit = delete $options{limit};
    return $self->_body_p(
        'downloads', \%options, '/api/v1/database/downloads',
        defined $limit ? (limit => $limit) : (),
    )->then(sub { $_[0]->{downloads} });
}

# The time-limited URL for one dataset file.
#
# The URL is returned rather than the bytes, so the caller decides how to
# transfer a file that routinely runs to gigabytes. The link authorizes the START
# of a transfer, so one already running is not interrupted when it lapses.
sub download_url {
    my $self = shift;
    $self->_assert_blocking_ok('download_url');
    return $self->{client}->_wait($self->download_url_p(@_));
}

sub download_url_p {
    my ($self, $id, $format, %options) = @_;
    _assert_dataset('download_url', $id, $format);
    my $client = $self->{client};
    $client->_check_options('database->download_url', \%options, 'retries');
    my $url = $client->_url('/api/v1/database/download', id => $id, format => $format);
    my $retries = defined $options{retries} ? $options{retries} : $client->{retries};
    return $client->_retry_p($retries, sub {
        $client->_get_p($url)->then(sub {
            my $res = shift->res;
            return _location($res) if $res->code == 302;
            # A 2xx here means the user agent followed the redirect and read the
            # dataset into memory. Naming the cause beats reporting a shape
            # mismatch a caller cannot act on.
            die VPNDetection::Error->new(
                kind => 'server_error', status => $res->code,
                message => 'expected a redirect to object storage but got '
                    . $res->code . '; the user agent must not follow redirects',
            ) if $res->is_success;
            die VPNDetection::Error->from_response($res->code, $res->headers, $res->json);
        });
    });
}

# Stream one dataset file to a path, and return the bytes written.
sub download {
    my $self = shift;
    $self->_assert_blocking_ok('download');
    return $self->{client}->_wait($self->download_p(@_));
}

sub download_p {
    my ($self, $id, $format, $path, %options) = @_;
    # Everything a caller can get wrong is refused before the file is opened, so
    # a mistyped id cannot leave a stray .part behind.
    _assert_dataset('download', $id, $format);
    $self->{client}->_check_options('database->download', \%options, 'retries');
    Carp::croak('database->download: expected a destination path')
        if !defined $path || !length $path;

    # The bytes land beside the destination and are renamed into place, so a
    # transfer that dies half way leaves no short file that reads as a whole
    # dataset. Opened BEFORE the request: an unwritable path costs no quota.
    my $partial = "$path.part";
    open my $handle, '>', $partial
        or Carp::croak("database->download: cannot open $partial: $!");
    binmode $handle;

    return $self->_transfer_p('download', $id, $format, \%options, sub {
        # A failure writing is the caller's to read rather than ours to retry: a
        # full disk and a reset socket are different problems.
        print {$handle} $_[0] or die "could not write the dataset to $partial: $!";
    })->then(sub {
        my $written = shift;
        close $handle or die "could not write the dataset to $partial: $!";
        rename $partial, $path or die "could not move the dataset into place at $path: $!";
        return $written;
    })->catch(sub {
        my $error = shift;
        close $handle;
        unlink $partial;
        die $error;
    });
}

# One dataset file's bytes, in memory.
sub download_bytes {
    my $self = shift;
    $self->_assert_blocking_ok('download_bytes');
    return $self->{client}->_wait($self->download_bytes_p(@_));
}

sub download_bytes_p {
    my ($self, $id, $format, %options) = @_;
    _assert_dataset('download_bytes', $id, $format);
    my $bytes = '';
    return $self->_transfer_p('download_bytes', $id, $format, \%options, sub {
        $bytes .= $_[0];
    })->then(sub { return $bytes });
}

sub _new {
    my ($class, $client) = @_;
    return bless { client => $client }, $class;
}

# The 302 is followed as a SECOND request, and that transfer is issued exactly
# once: `retries` covers the API call that hands out the link, not a transfer
# that may have moved gigabytes before it failed.
sub _transfer_p {
    my ($self, $method, $id, $format, $options, $on_chunk) = @_;
    my $client = $self->{client};
    $client->_check_options("database->$method", $options, 'retries');
    return $self->download_url_p($id, $format, %$options)
        ->then(sub { $client->_stream_p(shift, $on_chunk) });
}

sub _body_p {
    my ($self, $method, $options, $path, @query) = @_;
    my $client = $self->{client};
    $client->_check_options("database->$method", $options, 'retries');
    my $url = $client->_url($path, @query);
    my $retries = defined $options->{retries} ? $options->{retries} : $client->{retries};
    return $client->_retry_p($retries, sub { $client->_json_p($url) });
}

sub _assert_dataset {
    my ($method, $id, $format) = @_;
    Carp::croak("database->$method: expected a dataset id") if !defined $id || !length $id;
    Carp::croak("database->$method: expected a format") if !defined $format || !length $format;
}

sub _location {
    my ($res) = @_;
    my $location = $res->headers->location;
    die VPNDetection::Error->new(
        kind => 'server_error', status => $res->code,
        message => 'the API redirected without a Location header',
    ) if !defined $location || !length $location;
    return $location;
}

sub _assert_blocking_ok {
    my ($self, $method) = @_;
    $self->{client}->_assert_blocking_ok("database->$method");
}

1;

__END__

=head1 NAME

VPNDetection::Database - the licensed dataset downloads

=head1 SYNOPSIS

    my $db = $client->database;

    my $datasets = $db->list;
    my $id = $datasets->[0]{versions}[0]{id};       # e.g. 'vpn_ip_v1'

    my $meta = $db->metadata($id);
    my $sums = $db->checksums($id, 'mmdb');

    my $url = $db->download_url($id, 'mmdb');       # transfer it yourself
    my $bytes = $db->download_bytes('cdn_ip_v1', 'csvgz');
    my $written = $db->download($id, 'mmdb', "./$id.mmdb");

=head1 DESCRIPTION

Access is granted by contract rather than self-serve, and needs a key carrying
the C<db.download> scope. Reached through L<VPNDetection/database>.

Every method has a C<_p> twin returning a L<Mojo::Promise>, and every method
takes a per-call C<retries> option.

=head1 METHODS

=head2 list

An array reference of the dataset B<families> your organization may download. A
license is held against a family, and each family carries every version of
itself:

    {
        base => 'vpn_ip',               # what the license is held against
        name => 'VPN IP',
        summary => 'IP ranges observed as VPN infrastructure.',
        license_type => 'standard',   # evaluation, standard or redistribute
        starts => '2026-09-04T07:49:45.118Z',
        expires => undef,               # undef when the license does not expire
        in_term => 1,                   # false once the term has ended
        standing => 'licensed',         # licensed, expired or unlicensed
        versions => [
            {
                id => 'vpn_ip_v1',      # this is what you download
                version => 1,
                summary => 'IP ranges observed as VPN infrastructure.',
                formats => [{ format => 'csvgz', bytes => 111013959 }, ...],
                sampleFormats => ['csvgz', 'mmdb'],
            },
        ],
    }

The id every other method takes is C<< $version->{id} >>, never C<< $family->{base} >>.

=head2 metadata($id)

One dataset's document: C<updated>, C<entries>, per-format C<schema>, C<sample>
and C<size>. Poll it to decide whether today's build is worth fetching, and read
C<< $meta->{size}{$format} >> to size a transfer before starting it.

=head2 checksums($id, $format)

The whole digest set for one published file, as a hash reference keyed by
algorithm. Which algorithms appear varies by dataset, so read the one you want
off the hash rather than expecting a fixed set.

=head2 downloads(%options)

Your organization's recent download attempts, newest first. C<limit> caps the
number returned.

=head2 download_url($id, $format)

A time-limited URL for one dataset file. The API answers C<302> and this returns
the C<Location>; the bytes are yours to transfer however suits a file that can
run to gigabytes. The link authorizes the START of a transfer, so one already
running is not interrupted when it lapses.

=head2 download($id, $format, $path)

Streams one dataset file to C<$path> and returns the bytes written. Nothing
beyond one chunk is ever held, whatever the dataset weighs.

The bytes land in a neighboring C<.part> file that is renamed on completion, so a
transfer that dies half way leaves nothing behind that reads as a whole dataset.
A body that stops early is raised rather than accepted: the file is never left
short and silent.

=head2 download_bytes($id, $format)

Downloads one dataset file and returns its bytes.

B<This holds the entire file in memory>, and the catalog spans five orders of
magnitude, from C<cdn_ip_v1> at 10 KB to C<resproxy_ip_90d_v1> at 1.79 GB. Reach
for it at the small end, where the bytes go straight into a parser, and use
C<download> for anything you have not measured.

=head1 TRANSFERS

C<download_url> hands out a presigned link, and C<download> and C<download_bytes>
follow it as a second request carrying B<no credential>: the link authorizes
itself, so forwarding the API key would hand it to a host with no business
holding it.

That transfer is issued exactly once. C<retries> covers the API call that hands
out the link, not a transfer that may already have moved gigabytes before it
failed, and the per-request timeout that bounds a lookup is lifted for it.

=cut
