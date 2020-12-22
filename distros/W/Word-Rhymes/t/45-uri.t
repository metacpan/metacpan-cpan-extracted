use warnings;
use strict;

use Test::More;
use Word::Rhymes;

my $mod = 'Word::Rhymes';

# _uri
{
    my $o = $mod->new;

    is
        $o->_uri('zoo'),
        'http://api.datamuse.com/words?max=1000&rel_rhy=zoo',
        "_uri() with word but not context ok";

    is
        $o->_uri('zoo', 'farm'),
        'http://api.datamuse.com/words?max=1000&ml=farm&rel_rhy=zoo',
        "_uri() with word and context ok";
}

done_testing;
