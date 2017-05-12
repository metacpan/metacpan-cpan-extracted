#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;




my $html = '<div class="container"><div class="foo">Hello</div><div class="bar">Goodbye</div></div>';

is j($html)->find('.foo')->remove->end->as_html, '<div class="container"><div class="bar">Goodbye</div></div>', 'remove';
is j($html)->remove('.foo')->as_html, '<div class="container"><div class="bar">Goodbye</div></div>', 'end()';


done_testing;
