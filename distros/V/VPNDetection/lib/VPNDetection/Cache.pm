package VPNDetection::Cache;

use strict;
use warnings;

use Time::HiRes ();

our $VERSION = '1.5.0';

# A node is [key, value, expires_at, older, newer]. The hash finds a node, the
# links order them by recency, so a get, a set and an eviction are each O(1). A
# recency ARRAY would be O(n) per touch, and once the cache is full that is every
# single insert.
use constant { KEY => 0, VALUE => 1, EXPIRES => 2, OLDER => 3, NEWER => 4 };

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

    my $expires = Time::HiRes::time() + $self->{ttl};
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
