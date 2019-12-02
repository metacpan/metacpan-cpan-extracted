# ex:ts=4:sw=4:sts=4:et
package Transmission::Stats;
# See Transmission::Client for copyright statement.

=head1 NAME

Transmission::Stats - Transmission session statistics

=head1 DESCRIPTION

See "4.2 Sesion statistics" from
L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt>

=cut

use Moose;
use Transmission::Types ':all';

with 'Transmission::AttributeRole';

=head1 ATTRIBUTES

=head2 active_torrent_count

 $num = $self->active_torrent_count;

=head2 download_speed

 $num = $self->download_speed;

=head2 paused_torrent_count

 $num = $self->paused_torrent_count;

=head2 torrent_count

 $num = $self->torrent_count;

=head2 upload_speed

 $num = $self->upload_speed;

=head1 METHODS

=head2 read_all

Initialize/update stats attributes using Transmission RPC (C<session-stats>).
Also returns all attributes as a hash reference (named as per the attributes of
the class).

=cut

my %both = (
    activeTorrentCount  => number,
    downloadSpeed       => number,
    pausedTorrentCount  => number,
    torrentCount        => number,
    uploadSpeed         => number,
);

for my $camel (keys %both) {
    (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;

    has $name => (
        is      => 'ro',
        isa     => $both{$camel},
        coerce  => 1,
        writer  => "_set_$name",
        clearer => "clear_$name",
        lazy    => 1,
        default => sub {
            my $self = shift;
            my $val = delete $self->_tmp_store->{$name};

            return $val if defined $val;

            $self->_clear_tmp_store;
            return delete $self->_tmp_store->{$name};
        },
    );
}

has _tmp_store => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => 'read_all',
    clearer => '_clear_tmp_store',
);

sub read_all {
    my $self = shift;
    my $lazy = $self->lazy_write;
    my(%res, $rpc);

    $rpc = $self->client->rpc('session-stats') or return;

    $self->lazy_write(1);

    for my $camel (keys %both) {
        my $name = __PACKAGE__->_camel2Normal($camel);
        my $writer = "_set_$name";
        $res{$name} = $rpc->{$camel};
        $self->$writer($rpc->{$camel});
    }

    $self->lazy_write($lazy);

    return \%res;
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
