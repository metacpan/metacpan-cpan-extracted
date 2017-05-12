package Test::Mountebank::Imposter;

use Moose;
our $VERSION = '0.001';
use Method::Signatures;
use Test::Mountebank::Stub;
use JSON::Tiny qw(encode_json);
use Carp;

has protocol => ( is => 'rw', isa => 'Str', default => 'http' );
has port     => ( is => 'rw', isa => 'Int', default => 4545 );

has stubs   => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_stubs    => 'elements',
        add_stub     => 'push',
        map_stubs    => 'map',
        filter_stubs => 'grep',
        has_stubs    => 'count',
        has_no_stubs => 'is_empty',
    },
);

method stub() {
    my $stub = Test::Mountebank::Stub->new(@_);
    $self->add_stub($stub);
    return $stub;
}

method as_hashref() {
    croak "An imposter must have at least one stub" if $self->has_no_stubs;
    return {
        stubs    => [ $self->map_stubs( sub { $_->as_hashref } ) ],
        protocol => $self->protocol,
        port     => $self->port,
    };
}

method as_json() {
    return encode_json( $self->as_hashref() );
}

1;
