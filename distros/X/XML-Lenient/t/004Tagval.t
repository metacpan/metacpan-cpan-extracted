use strict;
use warnings;
use Test::More;
use XML::Lenient;
no warnings "uninitialized";

my $p = XML::Lenient->new();
my $ml = '<a href="www.example.com">Click</a>';
my $val = $p->tagval($ml, 'a');
is ($val, 'href="www.example.com"', 'Simple tagval works');
$ml = '<a></a><a href="www.example.com">Click</a>';
$val = $p->tagval($ml, 'a', 2);
ok ('href="www.example.com"' eq $val, 'Indexed tagval works');
$ml = '<a><a href="www.example.com">Click</a></a>';
$val = $p->tagval($ml, 'a', 2);
is ($val, 'href="www.example.com"', 'Nested tagval works');
$val = $p->tagval($ml, '');
ok ('' eq $val, 'Returns zero length string with no tag');
$val = $p->tagval($ml, undef);
ok ('' eq $val, 'Returns zero length string with undef tag');
$val = $p->tagval($ml, 'x');
ok ('' eq $val, 'Returns zero length string with valid tag not in ML');
$ml = '<a href ="/Clubs">Clubs</a><a href ="/Movements">Movements</a>';
$val = $p->tagval($ml, 'a', 2);
is ($val, 'href ="/Movements"', 'More complicated indexed tagval works');

done_testing;