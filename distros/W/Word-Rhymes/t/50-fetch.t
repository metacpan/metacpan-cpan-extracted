use warnings;
use strict;

use Test::More;

use Word::Rhymes;

my $mod = 'Word::Rhymes';
my $f = 't/data/zoo.data';

# bad params
{
    my $o = $mod->new(file => $f);

    is eval {$o->fetch; 1}, undef, "fetch() without a word croaks ok";
    is eval {$o->fetch('zoo', '***'); 1}, undef, "fetch() with non-word context croaks ok";
}

done_testing;
