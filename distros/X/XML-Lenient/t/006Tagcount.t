use strict;
use warnings;
use Test::More;
use Method::Signatures;
use XML::Lenient;

my $ml = '<div><div><div><div>asdf</div></div></div></div>';
my $p = XML::Lenient->new;
my $n = $p->tagcount($ml, 'div');
ok (4 == $n, 'Correct number of div tags');
$n = $p->tagcount($ml, 'x');
ok (0 == $n, 'Correct number of x tags');

done_testing;