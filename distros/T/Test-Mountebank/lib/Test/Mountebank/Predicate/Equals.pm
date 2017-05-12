package Test::Mountebank::Predicate::Equals;

use Moose;
our $VERSION = '0.001';

use Test::Mountebank::Types qw( HTTPHeaders );
use MooseX::Types::HTTPMethod qw(HTTPMethod11);
use JSON::Tiny qw(encode_json);

has method      => ( is => 'ro', isa => HTTPMethod11 );
has path        => ( is => 'ro', isa => 'Str' );
has body        => ( is => 'ro', isa => 'Str' );
has requestFrom => ( is => 'ro', isa => 'Str' );
has query       => ( is => 'ro', isa => 'HashRef' );
has headers     => ( is => 'ro', isa => HTTPHeaders, coerce => 1 );

sub as_hashref {
    my $self = shift;
    my $hashref = ();
    for (qw/ method path query body requestFrom /) {
        $hashref->{$_} = $self->$_, if $self->$_;
    }
    if ($self->headers) {
        my %headers = $self->headers->flatten;
        $hashref->{headers} = \%headers;
    }
    return { equals => $hashref };
}

1;
