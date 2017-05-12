#!/home/jake/debugperl/bin/perl

# $Id: example.pl,v 1.1 1997/04/30 21:06:46 jake Exp $

use Tie::Dict;

tie %foo, Tie::Dict, 'out.organic.com', '/tmp/foo';

$foo{'this'} = 'that';
$foo{'that'} = 'theother';

print $foo{'this'} . "\n";
print $foo{'that'} . "\n";

untie %foo;
