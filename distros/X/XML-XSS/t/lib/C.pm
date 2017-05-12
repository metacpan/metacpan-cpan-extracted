package C;

use Moose;
use XML::XSS;

extends 'XML::XSS';

style foo => ( 
    content => 'FOO',
);


1;
