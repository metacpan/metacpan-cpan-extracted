package UUID::Generator::PurePerl::NodeID;

use strict;
use warnings;

use Carp;
use POSIX ;#qw( uname );
use Digest;
use Time::HiRes;
use UUID::Generator::PurePerl::RNG;
use UUID::Generator::PurePerl::Util;

our $USE_RANDOM_FACTOR_FOR_PSEUDO_NODE = 1;

my $singleton;
sub singleton {
    my $class = shift;

    if (! defined $singleton) {
        $singleton = $class->new();
    }

    return $singleton;
}

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    if (@_) {
        $self->{use_rand} = shift;
    }

    return $self;
}

sub node_id {
    my $self = shift;

    return $self->pseudo_node_id(0);
}

sub physical_node_id {
    my $self = shift;

    return;
}

sub pseudo_node_id {
    my $self = shift;

    my $use_rand = shift;
    if (! defined $use_rand) {
        $use_rand = $self->{use_rand} if ref $self;
        if (! defined $use_rand) {
            $use_rand = $USE_RANDOM_FACTOR_FOR_PSEUDO_NODE;
        }
    }

    my $id = digest_as_octets(6, $self->_pseudo_node_source($use_rand));

    # set MSB
    substr $id, 0, 1, chr(ord(substr($id, 0, 1)) | 0x80);

    return $id;
}

sub random_node_id {
    my $self = shift;

    if (! defined $self->{rng}) {
        my $seed = digest_as_32bit($self->_pseudo_node_source(1));

        my $rng = UUID::Generator::PurePerl::RNG->new($seed);

        $self->{rng} = $rng;
    }

    my $r1 = $self->{rng}->rand_32bit;
    my $r2 = $self->{rng}->rand_32bit;

    my $hi = ($r1 >> 8) ^ ($r2 & 0xff);
    my $lo = ($r2 >> 8) ^ ($r1 & 0xff);

    # set MSB
    $hi |= 0x80;

    my $id  = substr pack('V', $hi), 0, 3;
       $id .= substr pack('V', $lo), 0, 3;

    ## set MSB
    #substr $id, 0, 1, chr(ord(substr($r, 0, 1)) | 0x80);

    return $id;
}

sub _pseudo_node_source {
    my ($class, $use_rand) = @_;

    my @r;

    push @r, q{}  . Time::HiRes::time()     if $use_rand;
    push @r, q{:} . $$                      if $use_rand;
    push @r, join(q{:}, POSIX::uname());

    return wantarray ? @r : join q{}, @r;
}

1;
__END__
