package Test::Mountebank::Stub;

use Moose;
our $VERSION = '0.001';
use Method::Signatures;
use Test::Mountebank::Predicate::Equals;
use Test::Mountebank::Response::Is;
use JSON::Tiny qw(encode_json);
use Carp;

has predicates => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_predicates    => 'elements',
        add_predicate     => 'push',
        map_predicates    => 'map',
        has_predicates    => 'count',
        has_no_predicates => 'is_empty',
    },
);

has responses => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_responses    => 'elements',
        add_response     => 'push',
        map_responses    => 'map',
        has_responses    => 'count',
        has_no_responses => 'is_empty',
    },
);

method predicate(@args) {
    $self->add_predicate(Test::Mountebank::Predicate::Equals->new(@args));
    return $self;
}

method response(@args) {
    $self->add_response(Test::Mountebank::Response::Is->new(@args));
    return $self;
}

method as_hashref() {
    croak "A stub must have at least one predicate" if $self->has_no_predicates;
    croak "A stub must have at least one response"  if $self->has_no_responses;
    return {
        responses  => [ $self->map_responses( sub { $_->as_hashref } ) ],
        predicates => [ $self->map_predicates( sub { $_->as_hashref } ) ],
    };
}

method as_json() {
    return encode_json( $self->as_hashref() );
}

1;
