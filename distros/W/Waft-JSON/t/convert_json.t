
use Test;
BEGIN { plan tests => 1 };

use strict;
use vars qw( @ISA );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Waft with => '::JSON';

my $data = { foo => 1, bar => [2, 3, 4] };
my $json = q/{"bar":[2,3,4],"foo":1}/;

ok( __PACKAGE__->convert_json($data) eq $json );
