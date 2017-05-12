# ex:ts=4:sw=4:sts=4:et
package Transmission::Session;
# See Transmission::Client for copyright statement.

=head1 NAME

Transmission::Session - Transmission session

=head1 DESCRIPTION

See "4 Session requests" from
L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt>

This class holds data, regarding the Transmission session.

=cut

use Moose;
use Transmission::Types ':all';
use Transmission::Stats;

BEGIN {
    with 'Transmission::AttributeRole';
}

=head1 ATTRIBUTES

=head2 stats

 $stats_obj = $self->stats;
 
Returns a L<Transmission::Stats> object.

=cut

has stats => (
    is => 'ro',
    isa => 'Object',
    lazy => 1,
    default => sub {
        Transmission::Stats->new(client => $_[0]->client);
    }
);

=head2 alt_speed_down

 $number = $self->alt_speed_down

max global download speed (in K/s)

=head2 alt_speed_enabled

 $boolean = $self->alt_speed_enabled

true means use the alt speeds

=head2 alt_speed_time_begin

 $number = $self->alt_speed_time_begin

when to turn on alt speeds (units: minutes after midnight)

=head2 alt_speed_time_enabled

 $boolean = $self->alt_speed_time_enabled

true means the scheduled on/off times are used

=head2 alt_speed_time_end

 $number = $self->alt_speed_time_end

when to turn off alt speeds (units: same)

=head2 alt_speed_time_day

 $number = $self->alt_speed_time_day

what day(s) to turn on alt speeds (look at tr_sched_day)

=head2 alt_speed_up

 $number = $self->alt_speed_up

max global upload speed (in K/s)

=head2 blocklist_enabled

 $boolean = $self->blocklist_enabled

true means enabled

=head2 dht_enabled

 $boolean = $self->dht_enabled

true means allow dht in public torrents

=head2 encryption

 $string = $self->encryption

"required", "preferred", "tolerated"

=head2 download_dir

 $string = $self->download_dir

default path to download torrents

=head2 peer_limit_global

 $number = $self->peer_limit_global

maximum global number of peers

=head2 peer_limit_per_torrent

 $number = $self->peer_limit_per_torrent

maximum global number of peers

=head2 pex_enabled

 $boolean = $self->pex_enabled

true means allow pex in public torrents

=head2 peer_port

 $number = $self->peer_port

port number

=head2 peer_port_random_on_start

 $boolean = $self->peer_port_random_on_start

true means pick a random peer port on launch

=head2 port_forwarding_enabled

 $boolean = $self->port_forwarding_enabled

true means enabled

=head2 seedRatioLimit

 $double = $self->seedRatioLimit

the default seed ratio for torrents to use

=head2 seedRatioLimited

 $boolean = $self->seedRatioLimited

true if seedRatioLimit is honored by default

=head2 speed_limit_down

 $number = $self->speed_limit_down

max global download speed (in K/s)

=head2 speed_limit_down_enabled

 $boolean = $self->speed_limit_down_enabled

true means enabled

=head2 speed_limit_up

 $number = $self->speed_limit_up

max global upload speed (in K/s)

=head2 speed_limit_up_enabled

 $boolean = $self->speed_limit_up_enabled

true means enabled

=cut

BEGIN {
    my %both = (
        'alt-speed-down'             => number,
        'alt-speed-enabled'          => boolean,
        'alt-speed-time-begin'       => number,
        'alt-speed-time-enabled'     => boolean,
        'alt-speed-time-end'         => number,
        'alt-speed-time-day'         => number,
        'alt-speed-up'               => number,
        'blocklist-enabled'          => boolean,
        'dht-enabled'                => boolean,
        'encryption'                 => string,
        'download-dir'               => string,
        'peer-limit-global'          => number,
        'peer-limit-per-torrent'     => number,
        'pex-enabled'                => boolean,
        'peer-port'                  => number,
        'peer-port-random-on-start'  => boolean,
        'port-forwarding-enabled'    => boolean,
        'seedRatioLimit'             => number,
        'seedRatioLimited'           => boolean,
        'speed-limit-down'           => number,
        'speed-limit-down-enabled'   => boolean,
        'speed-limit-up'             => number,
        'speed-limit-up-enabled'     => boolean,
    );

    for my $camel (keys %both) {
        my $name = __PACKAGE__->_camel2Normal($camel);
        __PACKAGE__->meta->add_attribute($name => (
            is => 'rw',
            isa => $both{$camel},
            coerce => 1,
            lazy => 1,
            clearer => "clear_$name",
            trigger => sub {
                return if($_[0]->lazy_write);
                $_[0]->client->rpc('session-set' => $camel =>
                    ($both{$camel} eq boolean and $_[1])  ? 'true'
                  : ($both{$camel} eq boolean and !$_[1]) ? 'false'
                  :                                         $_[1]
                );
            },
            default => sub {
                my $self = shift;
                my $val = delete $self->_tmp_store->{$name};

                if(defined $val) {
                    return $val;
                }
                else {
                    $self->_clear_tmp_store;
                    return delete $self->_tmp_store->{$name};
                }
            },
        ));
    }

    __PACKAGE__->meta->add_attribute(_tmp_store => (
        is => 'ro',
        isa => 'HashRef',
        lazy => 1,
        builder => 'read_all',
        clearer => '_clear_tmp_store',
    ));

    __PACKAGE__->meta->add_method(read_all => sub {
        my $self = shift;
        my $lazy = $self->lazy_write;
        my($rpc, %res);

        $rpc = $self->client->rpc('session-get') or return;

        $self->lazy_write(1);

        for my $camel (keys %both) {
            my $name = __PACKAGE__->_camel2Normal($camel);
            $res{$name} = $rpc->{$camel};
            $self->$name($rpc->{$camel});
        }

        $self->lazy_write($lazy);

        return \%res;
 
    });
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
