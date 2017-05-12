# ex:ts=4:sw=4:sts=4:et
package Transmission::Torrent;
# See Transmission::Client for copyright statement.

=head1 NAME

Transmission::Torrent - Transmission torrent object

=head1 DESCRIPTION

See "3.2 Torrent Mutators" and "3.3 Torrent accessors" from
L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt>

This class handles data related to a torrent known to Transmission.

=head1 SEE ALSO

L<Transmission::AttributeRole>

=cut

use Moose;
use List::MoreUtils qw(uniq);
use Transmission::Torrent::File;
use Transmission::Types ':all';

BEGIN {
    with 'Transmission::AttributeRole';
}

=head1 ATTRIBUTES

=head2 id

 $id = $self->id;

Returns the id that identifies this torrent in transmission.

=cut

has id => (
    is => 'ro',
    isa => 'Int',
    writer => '_set_id',
    required => 1,
);

=head2 bandwidth_priority

 $self->bandwidth_priority($num);

This torrent's bandwidth.

=head2 download_limit

 $self->download_limit($num);

Maximum download speed (in K/s).

=head2 download_limited

 $self->download_limited($bool);

True if "downloadLimit" is honored.

=head2 honors_session_limits

 $self->honors_session_limits($bool);

True if session upload limits are honored.

=head2 location

 $self->location($str);

New location of the torrent's content

=head2 peer_limit

 $self->peer_limit($num);

Maximum number of peers

=head2 seed_ratio_limit

 $self->seed_ratio_limit($num);

Session seeding ratio.

=head2 seed_ratio_mode

 $self->seed_ratio_mode($num);

Which ratio to use. See tr_ratiolimit.

=head2 upload_limit

 $self->upload_limit($num);

Maximum upload speed (in K/s)

=head2 upload_limited

 $self->upload_limited($bool);

True if "upload_limit" is honored

=head2 activity_date

 $num = $self->activity_date;

=head2 added_date

 $num = $self->added_date;

=head2 bandwidth_priority

 $num = $self->bandwidth_priority;

=head2 comment

 $str = $self->comment;

=head2 corrupt_ever

 $num = $self->corrupt_ever;

=head2 creator

 $str = $self->creator;

=head2 date_created

 $num = $self->date_created;

=head2 desired_available

 $num = $self->desired_available;

=head2 done_date

 $num = $self->done_date;

=head2 download_dir

 $str = $self->download_dir;

=head2 downloaded_ever

 $num = $self->downloaded_ever;

=head2 downloaders

 $num = $self->downloaders;

=head2 download_limit

 $num = $self->download_limit;

=head2 download_limited

 $bool = $self->download_limited;

=head2 error

 $num = $self->error;

=head2 error_string

 $str = $self->error_string;

=head2 eta

 $num = $self->eta;

=head2 hash_str

 $str = $self->hash_string;

=head2 have_unchecked

 $num = $self->have_unchecked;

=head2 have_valid

 $num = $self->have_valid;

=head2 honors_session_limits

 $bool = $self->honors_session_limits;

=head2 is_private

 $bool = $self->is_private;

=head2 leechers

 $num = $self->leechers;

=head2 left_until_done

 $num = $self->left_until_done;

=head2 manual_announce_time

 $num = $self->manual_announce_time;

=head2 max_connected_peers

 $num = $self->max_connected_peers;

=head2 name

 $str = $self->name;

=head2 peer

 $num = $self->peer;

=head2 peers_connected

 $num = $self->peers_connected;

=head2 peers_getting_from_us

 $num = $self->peers_getting_from_us;

=head2 peers_known

 $num = $self->peers_known;

=head2 peers_sending_to_us

 $num = $self->peers_sending_to_us;

=head2 percent_done

 $num = $self->percent_done;

=head2 pieces

 $str = $self->pieces;

=head2 piece_count

 $num = $self->piece_count;

=head2 piece_size

 $num = $self->piece_size;

=head2 rate_download

 $num = $self->rate_download;

=head2 rate_upload

 $num = $self->rate_upload;

=head2 recheck_progress

 $num = $self->recheck_progress;

=head2 seeders

 $num = $self->seeders;

=head2 seed_ratio_limit

 $num = $self->seed_ratio_limit;

=head2 seed_ratio_mode

 $num = $self->seed_ratio_mode;

=head2 size_when_done

 $num = $self->size_when_done;

=head2 start_date

 $num = $self->start_date;

=head2 status

 $str = $self->status;

=head2 swarm_speed

 $num = $self->swarm_speed;

=head2 times_completed

 $num = $self->times_completed;

=head2 total_size

 $num = $self->total_size;

=head2 torrent_file

 $str = $self->torrent_file;

=head2 uploaded_ever

 $num = $self->uploaded_ever;

=head2 upload_limit

 $num = $self->upload_limit;

=head2 upload_limited

 $bool = $self->upload_limited;

=head2 upload_ratio

 $num = $self->upload_ratio;

=head2 webseeds_sending_to_us

 $num = $self->webseeds_sending_to_us;

=cut

BEGIN {
    my $create_setter = sub {
        my $camel = $_[0];

        return sub {
            return if($_[0]->lazy_write);
            $_[0]->client->rpc('torrent-set' =>
                ids => [ $_[0]->id ], $camel => $_[1],
            );
        };
    };

    my $create_getter = sub {
        my $camel = $_[0];

        return sub {
            my $data = $_[0]->client->rpc('torrent-get' =>
                            ids => [ $_[0]->id ],
                            fields => [ $camel ],
                        );

            return unless($data);
            return $data->{'torrents'}[0]{$camel};
        };
    };

    my %SET = (
        #'files-wanted'          => array,
        #'files-unwanted'        => array,
        'location'              => string,
        'peer-limit'            => number,
        #'priority-high'         => array,
        #'priority-low'          => array,
        #'priority-normal'       => array,
    );
    our %BOTH = ( # meant for internal usage
        bandwidthPriority     => number,
        downloadLimit         => number,
        downloadLimited       => boolean,
        honorsSessionLimits   => boolean,
        seedRatioLimit        => double,
        seedRatioMode         => number,
        uploadLimit           => number,
        uploadLimited         => boolean,
    );
    our %READ = ( # meant for internal usage
        activityDate                => number,
        addedDate                   => number,
        comment                     => string,
        corruptEver                 => number,
        creator                     => string,
        dateCreated                 => number,
        desiredAvailable            => number,
        doneDate                    => number,
        downloadDir                 => string,
        downloadedEver              => number,
        downloaders                 => number,
        error                       => number,
        errorString                 => string,
        eta                         => number,
        hashString                  => string,
        haveUnchecked               => number,
        haveValid                   => number,
        isPrivate                   => boolean,
        leechers                    => number,
        leftUntilDone               => number,
        manualAnnounceTime          => number,
        maxConnectedPeers           => number,
        name                        => string,
        peersConnected              => number,
        peersGettingFromUs          => number,
        peersKnown                  => number,
        peersSendingToUs            => number,
        percentDone                 => double,
        pieceCount                  => number,
        pieceSize                   => number,
        rateDownload                => number,
        rateUpload                  => number,
        recheckProgress             => double,
        seeders                     => number,
        sizeWhenDone                => number,
        startDate                   => number,
        status                      => string,
        swarmSpeed                  => number,
        timesCompleted              => number,
        totalSize                   => number,
        torrentFile                 => string,
        uploadedEver                => number,
        uploadRatio                 => double,
        webseedsSendingToUs         => number,
    );
        #peers                       => array,
        #peersFrom                   => object,
        #pieces                      => string,
        #priorities                  => array,
        #trackers                    => array,
        #trackerStats                => array,
        #wanted                      => array,
        #webseeds                    => array,

    for my $camel (keys %SET) {
        my $name = __PACKAGE__->_camel2Normal($camel);
        my $setter = $create_setter->($camel);

        __PACKAGE__->meta->add_method("write_$name" => $setter);

        has $name => (
            is => 'rw',
            isa => $SET{$camel},
            coerce => 1,
            trigger => $setter,
        );
    }

    for my $camel (keys %BOTH) {
        my $name = __PACKAGE__->_camel2Normal($camel);
        my $setter = $create_setter->($camel);
        my $getter = $create_getter->($camel);

        __PACKAGE__->meta->add_method("write_$name" => $setter);

        has $name => (
            is => 'rw',
            isa => $BOTH{$camel},
            coerce => 1,
            lazy => 1,
            trigger => $setter,
            default => $getter,
        );
    }

    for my $camel (keys %READ) {
        my $name = __PACKAGE__->_camel2Normal($camel);
        my $getter = $create_getter->($camel);

        has $name => (
            is => 'ro',
            isa => $READ{$camel},
            coerce => 1,
            writer => "_set_$name",
            lazy => 1,
            default => $getter,
        );
    }

    __PACKAGE__->meta->add_method(read => sub {
        my $self = shift;
        my @fields = uniq(@_, 'id'); # id should always be requested
        my $lazy = $self->lazy_write;
        my $data;

        $data = $self->client->rpc('torrent-get' =>
                    ids => [ $self->id ],
                    fields => [ @fields ],
                ) or return;

        $data = $data->{'torrents'}[0] or return;

        # prevent from fireing off trigger in attributes
        $self->lazy_write(1);

        for my $camel (keys %$data) {
            my $name = __PACKAGE__->_camel2Normal($camel);
            my $writer = $READ{$camel} ? "_set_$name" : $name;

            $self->$writer($data->{$camel});
        }

        # reset lazy_write
        $self->lazy_write($lazy);

        return 1;
    });

    __PACKAGE__->meta->add_method(read_all => sub {
        my $self = shift;
        return $self->read(keys %BOTH, keys %READ);
    });

    $READ{'id'} = 'Int'; # this is required to be read
}

=head2 files

 $array_ref = $self->files;
 $self->clear_files;

Returns an array of L<Transmission::Torrent::File>s.

=cut

has files => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_files {
    my $self = shift;
    my $files = [];
    my $stats = [];
    my $id = 0;
    my $data;

    $data = $self->client->rpc('torrent-get' =>
                ids => [ $self->id ],
                fields => [ qw/ files fileStats / ],
            );

    return [] unless($data);

    $files = $data->{'torrents'}[0]{'files'};
    $stats = $data->{'torrents'}[0]{'fileStats'};

    # this has to be true: @$files == @$stats
    while(@$stats) {
        my $stats = shift @$stats or last;
        my $file = shift @$files;

        push @$files,
            Transmission::Torrent::File->new(id => $id, %$stats, %$file);

        $id++;
    }

    return $files;
}

=head1 METHODS

=head2 BUILDARGS

 $hash_ref = $self->BUILDARGS(\%args);

Convert keys in C<%args> from "CamelCase" to "camel_case".

=cut

sub BUILDARGS {
    my $self = shift;
    my $args = $self->SUPER::BUILDARGS(@_);

    $self->_camel2Normal($args);

    return $args;
}

=head2 read

 $bool = $self->read('id', 'name', 'eta');

This method will refresh all requested attributes in one RPC request, while
calling one and one attribute, results in one-and-one request.

=head2 read_all

 $bool = $self->read_all;

Similar to L</read>, but requests all attributes.

=head2 start

See L<Transmission::Client::start()>.

=head2 stop

See L<Transmission::Client::stop()>.

=head2 verify

See L<Transmission::Client::verify()>.

=cut

{
    for my $name (qw/ start stop verify /) {
        __PACKAGE__->meta->add_method($name => sub {
            $_[0]->client->$name(ids => $_[0]->id);
        });
    }
}

=head2 move

 $bool = $self->move($path);

Will move the torrent content to C<$path>.

=cut

sub move {
    my $self = shift;
    my $path = shift;

    unless($path) {
        $self->client_error("Required argument 'path' is missing");
        return;
    }

    return $self->client->move(
        ids => [$self->id],
        location => $path,
        move => 1,
    );
}

=head2 write_wanted

 $bool = $self->write_wanted;

Will write "wanted" information from L</files> to transmission.

=cut

sub write_wanted {
    my $self = shift;
    my %wanted = ( wanted => [], unwanted => [] );
    my $ok;

    for my $file (@{ $self->files }) {
        push @{ $wanted{ $file->wanted ? 'wanted' : 'unwanted' } }, $file->id;
    }

    for my $key (qw/wanted unwanted/) {
        # Transmission interpret an empty list to mean all files
        next unless @{$wanted{$key}};

        $self->client->rpc('torrent-set' =>
            ids => [ $self->id ], "files-$key" => $wanted{$key}
        ) or return;
    }

    return 1;
}

=head2 write_priority

 $bool = $self->write_priority;

Will write "priorty" information from L</files> to transmission.

=cut

sub write_priority {
    my $self = shift;
    my %priority = ( low => [], normal => [], high => [] );
    my %map = ( -1 => 'low', 0 => 'normal', 1 => 'high' );

    for my $file (@{ $self->files }) {
        my $key = $map{ $file->priority } || 'normal';
        push @{ $priority{$key} }, $file->id;
    }

    for my $key (qw/low normal high/) {
        $self->client->rpc('torrent-set' =>
            ids => [ $self->id ], "priority-$key" => $priority{$key}
        ) or return;
    }

    return 1;
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>.

=cut

1;
