package WebService::FuncNet::Predictor::Types;

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

=head1 REVISION INFO

  Revision:      $Rev: 62 $
  Last editor:   $Author: isillitoe $
  Last updated:  $Date: 2009-07-06 16:01:23 +0100 (Mon, 06 Jul 2009) $

The latest source code for this project can be checked out from:

  https://funcnet.svn.sf.net/svnroot/funcnet/trunk

=cut
