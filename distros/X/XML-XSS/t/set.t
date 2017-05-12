
use strict;
use warnings;

use Test::More tests => 1;    # last test to print

use XML::XSS;

my $xss = XML::XSS->new;

$xss->set(
    a => { content => 'A' },
    b => { content => 'B' },
);

is $xss->render('<doc><a/><b/></doc>') => '<doc>AB</doc>',
  'set deals with more than one element';

