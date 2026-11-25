package VPNDetection::Cache;

use strict;
use warnings;

use Scalar::Util ();
use Time::HiRes ();

our $VERSION = '3.19.1';

# A node is [key, value, expires_at, older, newer]. The hash finds a node, the
# links order them by recency, so a get, a set and an eviction are each O(1). A
# recency ARRAY would be O(n) per touch, and once the cache is full that is every
# single insert.
use constant { KEY => 0, VALUE => 1, EXPIRES => 2, OLDER => 3, NEWER => 4 };

# The longest a spent trial's or a reached cap's answer is held, in seconds.
use constant REDUCED_TTL => 60;

sub new {
    my ($class, %args) = @_;
    return bless {
        max => $args{max},
        ttl => $args{ttl},
        nodes => {},
        newest => undef,
        oldest => undef,
    }, $class;
}

# undef is a miss. A hit is always a blessed result, so the two never collide.
sub get {
    my ($self, $key) = @_;
    my $node = $self->{nodes}{$key};
    return undef unless $node;
    if ($node->[EXPIRES] <= Time::HiRes::time()) {
        $self->_forget($node);
        return undef;
    }
    $self->_promote($node);
    return $node->[VALUE];
}

sub set {
    my ($self, $key, $value) = @_;
    return unless $self->{max} > 0;

    my $expires = Time::HiRes::time() + $self->_life_of($value);
    if (my $node = $self->{nodes}{$key}) {
        @{$node}[VALUE, EXPIRES] = ($value, $expires);
        $self->_promote($node);
        return;
    }

    my $node = [$key, $value, $expires, undef, undef];
    $self->{nodes}{$key} = $node;
    $self->_link($node);
    $self->_forget($self->{oldest}) while keys %{$self->{nodes}} > $self->{max};
}

sub size {
    return scalar keys %{ $_[0]{nodes} };
}

# When the answer held for $key goes stale, as Time::HiRes::time() reads, or undef.
sub expiry {
    my ($self, $key) = @_;
    my $node = $self->{nodes}{$key};
    return $node ? $node->[EXPIRES] : undef;
}

# A reduced answer, a spent trial's or a reached cap's, ends with a renewed trial
# or a raised cap, so it stays a minute at most rather than the TTL. It is still
# cached, or a busy process would send every repeat of an address to the API.
sub _life_of {
    my ($self, $value) = @_;
    my $reduced = Scalar::Util::blessed($value) && $value->can('trial_expired')
        && ($value->trial_expired || $value->cap_reached);
    return $self->{ttl} unless $reduced;
    return $self->{ttl} < REDUCED_TTL ? $self->{ttl} : REDUCED_TTL;
}

sub _promote {
    my ($self, $node) = @_;
    return if $self->{newest} && $self->{newest} == $node;
    $self->_unlink($node);
    $self->_link($node);
}

sub _forget {
    my ($self, $node) = @_;
    $self->_unlink($node);
    delete $self->{nodes}{ $node->[KEY] };
}

sub _link {
    my ($self, $node) = @_;
    $node->[OLDER] = $self->{newest};
    $node->[NEWER] = undef;
    $self->{newest}[NEWER] = $node if $self->{newest};
    $self->{newest} = $node;
    $self->{oldest} = $node unless $self->{oldest};
}

sub _unlink {
    my ($self, $node) = @_;
    my ($older, $newer) = @{$node}[OLDER, NEWER];
    $older->[NEWER] = $newer if $older;
    $newer->[OLDER] = $older if $newer;
    $self->{newest} = $older if $self->{newest} && $self->{newest} == $node;
    $self->{oldest} = $newer if $self->{oldest} && $self->{oldest} == $node;
    @{$node}[OLDER, NEWER] = (undef, undef);
}

1;

__END__

=head1 NAME

VPNDetection::Cache - the per-client LRU behind C<< $client->lookup >>

=head1 DESCRIPTION

Implementation detail. Size and lifetime are the C<cache_size> and C<cache_ttl>
options to L<VPNDetection/new>.

=cut
