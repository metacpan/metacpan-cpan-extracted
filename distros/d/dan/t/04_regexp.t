use strict;
use warnings;
use Test::More;
plan tests => 6;

my $data = 'foo';

use dan;
if ($data =~ /bar/) {
    ok 1;
} else {
    ok 0;
}
no dan;

use dan cat_decode => sub {
    my $str = shift;
    $str =~ s/baz/foo/;
    $str;
};
if ($data =~ /(baz)/) {
    ok 1;
} else {
    ok 0;
}
no dan;
is $1, $data;
is $1, 'foo';

my $data2 = 'boofy';
use dan;
$data2 =~ s/boofy/soozy/;
no dan;
isnt $data2, 'soozy';
is $data2, 'boofy';
