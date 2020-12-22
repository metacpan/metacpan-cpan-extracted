use warnings;
use strict;

use Test::More;

use Word::Rhymes;

my $mod = 'Word::Rhymes';

#
# file
#

# new param default
{
    my $o = $mod->new;
    is $o->file, '', "default file is blank ok";
}

# file does not exist
{
    is
        eval {$mod->new(file => 'blah.blah'); 1},
        undef,
        "file does not exist croaks ok";

    like $@, qr/does not exist/, "...and error is sane";
}

# file isn't a file
{
    is
        eval {
            $mod->new(file => 'lib/');
            1
        },
        undef,
        "file isn't a file fails ok";

    like $@, qr/valid file/, "...and error is sane";
}

# no file (only for coverage purposes)
{
    if ($ENV{WORD_RHYMES_NO_FILE}) {
        is ref $mod->new->fetch('zoo'), 'HASH', "no file fetches from internet ok";
    }
}

# method
{
    my $o = $mod->new;

    is
        eval {$o->file('blah.blah'); 1},
        undef,
        "method file() does not exist croaks ok";

    like $@, qr/does not exist/, "...and error is sane";

    is
        eval {$o->file('lib/'); 1},
        undef,
        "file() croaks if the file isn't a real file ok";

    like $@, qr/valid file/, "...and error is sane";
}

done_testing;