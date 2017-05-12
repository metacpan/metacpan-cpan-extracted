package Beta;

use Moose;
use XML::XSS;

extends 'A';

my $master = __PACKAGE__->master;

$master->set( b => { content => 'B' } );

1;
