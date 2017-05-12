package A;

use Moose;
use XML::XSS;

extends 'XML::XSS';

my $master = __PACKAGE__->master;

$master->set( a => { content => 'A' } );
$master->set( '#comment' => { rename => 'comment' } );
$master->set( '#pi' => { pre => '[pi]' } );
$master->set( '#text' => { pre => '[text]' } );

1;
