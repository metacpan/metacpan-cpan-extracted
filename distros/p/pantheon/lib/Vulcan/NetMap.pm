package Vulcan::NetMap;

=head1 NAME

Vulcan::NetMap - network mappings of data centers

=head1 SYNOPSIS

 use Vulcan::NetMap;

 my $map = Vulcan::NetMap->load( '/conf/file' );
 my $info = $map->search( $ip );

=cut
use strict;
use warnings;

use Carp;
use YAML::XS;

use constant { MAX => 32 };

sub new { load( @_ ) };

=head1 CONFIG

A YAML file, containing a HASH of subnet definitions indexed by data centers.
Each subnet definition should be a HASH of masks indexed by subnets. e.g.

 ---
 dc1:
   10.141.0.0: 255.255.0.0
   111.13.65.1: 255.255.255.0
 dc2:
   10.138.0.0: 16
   10.139.0.0: 16
   106.120.160.0: 24

=cut
sub load
{
    my ( $class, $conf ) = splice @_;
    my ( $error, %mask, %self ) = "Invalid config: $conf";

    eval { $conf = YAML::XS::LoadFile $conf };
    confess "$error: $@" if $@;
    confess "$error: not HASH" if ref $conf ne 'HASH';

    while ( my ( $dc, $conf ) = each %$conf )
    {
        my $error = "$error: $dc";
        confess "$error: not HASH" if ref $conf ne 'HASH';

        while ( my ( $net, $mask ) = each %$conf )
        {
            my $error = "$error: $net";

            confess "$error: invalid subnet" unless $net = $class->ip2n( $net );
            confess "$error: invalid netmask"
                unless $mask{$mask} ||= $class->mask( $mask );

            $self{$dc}{ $net & $mask{$mask} } = $mask{$mask};
        }
    }
    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 dc( %param )

Returns a list of data centers in the config.
List is sorted by I<size> or I<segment> if $param{sort} is defined.

=cut
sub dc
{
    my ( $self, %param ) = splice @_;
    my @dc = sort keys %$self;
    
    if ( my $sort = $param{sort} )
    {
        my %size;
        if ( $sort =~ /size/i )
        {
            my $mask = 2 ** MAX - 1;
            for my $dc ( @dc )
            {
                my $size = 0;
                map { $size += $_ ^ $mask } values %{ $self->{$dc} };
                $size{$dc} = $size;
            }
        }
        elsif ( $sort =~ /seg/i )
        {
            %size = map { $_ => 0 + keys %{ $self->{$_} } } @dc;
        }
        @dc = sort { $size{$a} <=> $size{$b} } keys %size;
    }
    return wantarray ? @dc : \@dc;
}

=head3 search( $ip, %param )

Returns I<dc>, I<net>, I<mask> of $ip if within the net map.
I<net> and I<mask> are returned in integer if $param{int} is defined. 

=cut
sub search
{
    my ( $self, $ip, %param ) = splice @_;
    my %info;

    if ( $ip = $self->ip2n( $ip ) )
    {
        while ( my ( $dc, $conf ) = each %$self )
        {
            my %mask = reverse %$conf;
            map { my $net = $ip & $_; last if %info = ( $_ = $conf->{$net} )
                ? ( dc => $dc, net => $net, mask => $_ ) : () } keys %mask;
        }
    }

    map { $info{$_} = $self->n2ip( $info{$_} ) } qw( net mask )
        if %info && ! $param{int};

    return wantarray ? %info : keys %info ? \%info : undef;
}

=head3 mask( $mask )

Returns the integer value of a (dotted or decimal) netmask.

=cut
sub mask
{
    my ( $class, $mask ) = splice @_;

    return undef unless $mask = $mask !~ /^\d+$/
        ? $class->ip2n( $mask ) : $mask < MAX
        ? ( 2 ** $mask - 1 ) << ( MAX - $mask ) : undef;
    return split( /0+/, sprintf '%032b', $mask ) > 1 ? undef : $mask;
}

=head3 ip2n( $ip )

Returns the integer value of a dotted ip.

=cut
sub ip2n
{
    my ( $class, $ip ) = splice @_;
    return undef unless my @ip = $ip =~ qr/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/o;
    return unpack N => pack C4 => @ip;
}

=head3 n2ip( $int )

Returns dotted ip form of an integer.

=cut
sub n2ip
{
    my ( $class, $ip ) = splice @_;
    return $ip =~ /^\d+$/ ? join '.', unpack C4 => pack N => $ip : undef;
}

1;
