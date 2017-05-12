package WebService::Cath::FuncNet::Types;

use MooseX::Types
    -declare => [qw(
        Float
    )];

use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw( Int Str Object );
use Math::BigFloat;

subtype 'Float'
    => as 'Object'
    => where { $_->isa( 'Math::BigFloat' ) };

coerce 'Float'
    => from 'Str'
    => via { Math::BigFloat->new( $_ ) };

1;
