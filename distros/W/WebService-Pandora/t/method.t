use strict;
use warnings;

use Test::More tests => 2;

use WebService::Pandora::Method;

my $method = WebService::Pandora::Method->new( name => undef,
                                               host => undef );

# test out not providing a name and host
my $result = $method->execute();

is( $result, undef, 'undefined execute' );
is( $method->error(), 'Both the name and host must be provided to the constructor.', 'execute error string' );
