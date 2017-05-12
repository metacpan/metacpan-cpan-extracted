package MyStylesheet;

use Moose;
use XML::XSS;

extends 'XML::XSS';

style foo => ( 
    pre => '[pre-foo]',
    post => '[post-foo]',
);

1;


