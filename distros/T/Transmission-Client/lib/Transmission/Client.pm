# ex:ts=4:sw=4:sts=4:et
package Transmission::Client;
# Copyright 2009-2013, Jan Henning Thorsen <jhthorsen@cpan.org>
#    and contributors
#
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

Transmission::Client - Interface to Transmission

=head1 VERSION

0.0806

=head1 DESCRIPTION

L<Transmission::Client> is the main module in a collection of modules
to communicate with Transmission. Transmission is a cross-platform
BitTorrent client that is:

=over

=item * Easy

=item * Lean

=item * Native

=item * Powerful

=item * Free

=back

If you want to communicate with "transmission-daemon", this is a module
which can help you with that.

The documentation is half copy/paste from the Transmission RPC spec:
L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt>

This module differs from L<P2P::Transmission> in (at least) two ways:
This one use L<Moose> and it won't die. The latter is especially
annoying in the constructor.

=head1 SYNOPSIS

 use Transmission::Client;

 my $client = Transmission::Client->new;
 my $torrent_id = 2;
 my $data = base64_encoded_data();

 $client->add(metainfo => $data) or confess $client->error;
 $client->remove($torrent_id) or confess $client->error;

 for my $torrent (@{ $client->torrents }) {
    print $torrent->name, "\n";
    for my $file (@{ $torrent->files }) {
        print "> ", $file->name, "\n";
    }
 }

 print $client->session->download_dir, "\n";

=head1 FAULT HANDLING

In C<0.06> L<Transmission::Client> can be constructed with "autodie" set
to true, to make this object confess instead of just setting L</error>.
Example:

    my $client = Transmission::Client->new(autodie => 1);

    eval {
        $self->add(filename => 'foo.torrent');
    } or do {
        # add() failed...
    };

=head1 SEE ALSO

L<Transmission::AttributeRole>
L<Transmission::Session>
L<Transmission::Torrent>
L<Transmission::Utils>

=cut

use Moose;
use DateTime;
use DateTime::Duration;
use JSON::MaybeXS;
use LWP::UserAgent;
use MIME::Base64;
use Transmission::Torrent;
use Transmission::Session;
use constant RPC_DEBUG => $ENV{'TC_RPC_DEBUG'};

our $VERSION = '0.0806';
our $SESSION_ID_HEADER_NAME = 'X-Transmission-Session-Id';
my $JSON = JSON::MaybeXS->new;

with 'Transmission::AttributeRole';

=head1 ATTRIBUTES

=head2 url

 $str = $self->url;

Returns an URL to where the Transmission rpc api is.
Default value is "http://localhost:9091/transmission/rpc";

=cut

has url => (
    is => 'ro',
    isa => 'Str',
    default => 'http://localhost:9091/transmission/rpc',
);

# this is subject for change!
has _url => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build__url {
    my $self = shift;
    my $url = $self->url;

    if($self->username or $self->password) {
        my $auth = join ':', $self->username, $self->password;
        $url =~ s,://,://$auth@,;
    }

    return $url;
}

=head2 error

 $str = $self->error;
 
Returns the last error known to the object. All methods can return
empty list in addition to what specified. Check this attribute if so happens.

Like L</autodie>? Create your object with C<autodie> set to true and this
module will throw exceptions in addition to setting this variable.

=cut

has error => (
    is => 'rw',
    isa => 'Str',
    default => '',
    clearer => '_clear_error',
    trigger => sub { $_[0]->_autodie and confess $_[1] },
);

has _autodie => (
    is => 'ro',
    init_arg => 'autodie',
    isa => 'Bool',
    default => 0,
);

=head2 username

 $str = $self->username;

Used to authenticate against Transmission.

=cut

has username => (
    is => 'ro',
    isa => 'Str',
    default => '',
);

=head2 password

 $str = $self->password;

Used to authenticate against Transmission.

=cut

has password => (
    is => 'ro',
    isa => 'Str',
    default => '',
);

=head2 timeout

 $int = $self->timeout;

Number of seconds to wait for RPC response.

=cut

has _ua => (
    is => 'rw',
    isa => 'LWP::UserAgent',
    lazy => 1,
    handles => [qw/timeout/],
    default => sub {
        LWP::UserAgent->new( agent => 'Transmission-Client' );
    },
);

=head2 session

 $session_obj = $self->session;
 $stats_obj = $self->stats;

Returns an instance of L<Transmission::Session>.
C<stats()> is a proxy method on L</session>.

=cut

has session => (
    is => 'ro',
    lazy => 1,
    predicate => 'has_session',
    handles => [qw/stats/],
    default => sub {
        Transmission::Session->new( client => $_[0] );
    },
);

=head2 torrents

 $array_ref = $self->torrents;
 $self->clear_torrents;

Returns an array-ref of L<Transmission::Torrent> objects. Default value
is a full list of all known torrents, with as little data as possible read
from Transmission. This means that each request on a attribute on an object
will require a new request to Transmission. See L</read_torrents> for more
information.

=cut

has torrents => (
    is => 'rw',
    traits => ['Array'],
    lazy => 1,
    clearer => "clear_torrents",
    builder => "read_torrents",
    predicate => 'has_torrents',
    handles => {
        torrent_list => 'elements',
    },
);

=head2 version

 $str = $self->version;

Get Transmission version.

=cut

has version => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_version {
    my $self = shift;

    if(my $data = $self->rpc('session-get')) {
        return $data->{'version'} || q();
    }

    return q();
}

=head2 session_id

 $self->session_id($str);
 $str = $self->session_id;

The session ID used to communicate with Transmission.

=cut

has session_id => (
    is => 'rw',
    isa => 'Str',
    default => '',
    trigger => sub {
        $_[0]->_ua->default_header($SESSION_ID_HEADER_NAME => $_[1]);
    },
);

=head1 METHODS

=head2 add

 $bool = $self->add(%args);

 key              | value type | description
 -----------------+------------+------------------------------------
 download_dir     | string     | path to download the torrent to
 filename         | string     | filename or URL of the .torrent file
 metainfo         | string     | torrent content
 paused           | boolean    | if true, don't start the torrent
 peer_limit       | number     | maximum number of peers

Either "filename" or "metainfo" MUST be included. All other arguments are
optional.

See "3.4 Adding a torrent" from
L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt>

=cut

sub add {
    my $self = shift;
    my %args = @_;

    if($args{'filename'} and $args{'metainfo'}) {
        $self->error("Filename and metainfo argument crash");
        return;
    }
    elsif($args{'filename'}) {
        return $self->rpc('torrent-add', %args);
    }
    elsif($args{'metainfo'}) {
        $args{'metainfo'} = encode_base64($args{'metainfo'});
        return $self->rpc('torrent-add', %args);
    }
    else {
        $self->error("Need either filename or metainfo argument");
        return;
    }
}

=head2 remove

 $bool = $self->remove(%args);

 key                | value type | description
 -------------------+------------+------------------------------------
 ids                | array      | torrent list, as described in 3.1
 delete_local_data  | boolean    | delete local data. (default: false)

C<ids> can also be the string "all". C<ids> is required.

See "3.4 Removing a torrent" from
L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt>

=cut

sub remove {
    my $self = shift;

    if($self->_do_ids_action('torrent-remove' => @_)) {
        $self->clear_torrents; # torrent list might be out of sync
        return 1;
    }
    else {
        return 0;
    }
}

=head2 move

 $bool = $self->move(%args);


 string      | value type | description
 ------------+------------+------------------------------------
 ids         | array      | torrent list, as described in 3.1
 location    | string     | the new torrent location
 move        | boolean    | if true, move from previous location.
             |            | otherwise, search "location" for files

C<ids> can also be the string "all". C<ids> and C<location> is required.

See "3.5 moving a torrent" from
L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt>

=cut

sub move {
    my $self = shift;
    my %args = @_;

    if(!defined $args{'location'}) {
        $self->error("location argument is required");
        return;
    }

    return $self->_do_ids_action('torrent-set-location' => %args);
}

=head2 start

 $bool = $self->start($ids);

Will start one or more torrents.
C<$ids> can be a single int, an array of ints or the string "all".

=head2 stop

 $bool = $self->stop($ids);

Will stop one or more torrents.
C<$ids> can be a single int, an array of ints or the string "all".

=head2 verify

 $bool = $self->stop($ids);

Will verify one or more torrents.
C<$ids> can be a single int, an array of ints or the string "all".

=cut

sub start {
    return shift->_do_ids_action('torrent-start' => @_);
}

sub stop {
    return shift->_do_ids_action('torrent-stop' => @_);
}

sub verify {
    return shift->_do_ids_action('torrent-verify' => @_);
}

sub _do_ids_action {
    my $self = shift;
    my $method = shift;
    my %args = @_ == 1 ? (ids => $_[0]) : @_;
    my $ids;

    unless(defined $args{'ids'}) {
        $self->error('ids is required as argument');
        return;
    }

    unless(ref $args{'ids'} eq 'ARRAY') {
        if($args{'ids'} eq 'all') {
            delete $args{'ids'};
        }
        else {
            $args{'ids'} = [$args{'ids'}];
        }
    }

    return $self->rpc($method, %args) ? 1 : 0;
}

=head2 read_torrents

 @list = $self->read_torrents(%args);
 $array_ref = $self->read_torrents(%args);

 key         | value type | description
 ------------+------------+------------------------------------
 ids         | array      | optional torrent list, as described in 3.1.
 lazy_read   |            | will create objects with as little data as possible.

=over 4

=item List context

Returns a list of L<Transmission::Torrent> objects and sets the L</torrents>
attribute.

=item Scalar context

Returns an array-ref of L<Transmission::Torrent>.

=back

=cut

sub read_torrents {
    my $self = shift;
    my %args = @_ == 1 ? (ids => $_[0]) : @_;
    my $list;

    # set fields...
    if(exists $args{'fields'}) { # ... based on user input
        # We should always request id
        push @{$args{'fields'}}, 'id' unless
            grep {'id' eq $_} @{$args{'fields'}};
    }
    elsif($args{'lazy_read'}) { # ... as few fields as possible
        $args{'fields'} = ['id'];
    }
    else { # ... all fields
        $args{'fields'} = [
            keys %Transmission::Torrent::READ,
            keys %Transmission::Torrent::BOTH,
        ];
    }

    # set ids
    if($args{'ids'}) {
        if($args{'ids'} eq 'all') {
            delete $args{'ids'};
        }
        elsif(ref $args{'ids'} eq "") {
            $args{'ids'} = [ $args{'ids'} ];
        }
    }

    if(my $data = $self->rpc('torrent-get' => %args)) {
        $list = $data->{'torrents'};
    }
    else {
        $list = [];
    }

    for my $torrent (@$list) {
        $torrent = Transmission::Torrent->new(
                        client => $self,
                        id => $torrent->{'id'},
                        %$torrent,
                   );
    }

    if(wantarray) {
        $self->torrents($list);
        return @$list;
    }
    else {
        return $list;
    }
}

=head2 rpc

 $any = $self->rpc($method, %args);

Communicate with backend. This methods is meant for internal use.

=cut

sub rpc {
    my $self = shift;
    my $method = shift or return;
    my %args = @_;
    my $nested = delete $args{'_nested'}; # internal flag
    my($tag, $res, $post);

    $method = $self->_normal2Camel($method);

    # The keys need to be dashes as well
    # _normal2Camel modifies a hashref in places
    $self->_normal2Camel( \%args );

    # make sure ids are numeric
    if(ref $args{'ids'} eq 'ARRAY') {
        for my $id (@{ $args{'ids'} }) {
            # Need to convert string integer to "real" integer
            #   FLAGS = (IOK,POK,pIOK,pPOK)
            #   IV = 42
            # ...to...
            #   FLAGS = (PADTMP,IOK,pIOK)
            #   IV = 42
            $id += 0 if($id =~ /^\d+$/);
        }
    }

    $tag  = int rand 2*16 - 1;
    $post = $JSON->encode({
                method    => $method,
                tag       => $tag,
                arguments => \%args,
            });

    $res = $self->_ua->post($self->_url, Content => $post);

    if(RPC_DEBUG) {
        print "post: $post\n";
        print "status_line: ", $res->status_line, "\n";
    }

    unless($res->is_success) {
        if($res->code == 409 and !$nested) {
            $self->session_id($res->header($SESSION_ID_HEADER_NAME));
            return $self->rpc($method => %args, _nested => 1);
        }
        else {
            $self->error($res->status_line);
            return;
        }
    }

    $res = $JSON->decode($res->content);

    unless($res->{'tag'} == $tag) {
        $self->error("Tag mismatch");
        return;
    }
    unless($res->{'result'} eq 'success') {
        $self->error($res->{'result'});
        return;
    }

    $self->_clear_error;

    return $res->{'arguments'};
}

=head2 read_all

 1 == $self->read_all;

This method will try to populate ALL torrent, session and stats information,
using three requests.

=cut

sub read_all {
    my $self = shift;

    $self->session->read_all;
    $self->stats->read_all;
    () = $self->read_torrents;

    return 1;
}

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 COPYRIGHT AND AUTHORS

Copyright 2009-2019 by Transmission::Client contributors

See C<git log --format="%aN E<lt>%aEE<gt>" | sort | uniq> in the git repository
for the reference list of contributors.

=head2 CONTRIBUTORS

=over

=item * Jan Henning Thorsen (original author)

=item * Olof Johansson (current maintainer)

=item * Andrew Fresh

=item * Yanick Champoux

=back

=cut

no MIME::Base64;
no Moose;
1;
