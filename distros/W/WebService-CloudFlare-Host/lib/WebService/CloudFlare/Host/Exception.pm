package WebService::CloudFlare::Host::Exception;
use Moose;

has 'message' => ( is => 'ro', isa => 'Str' );
has 'layer' => ( is => 'ro', isa => 'Str' );
has 'function' => ( is => 'ro', isa => 'Str' );
has 'args' => ( is => 'ro', isa => 'Str' );

1;
