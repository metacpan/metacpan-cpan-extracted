use warnings;
use strict;

use Test::More;
use Word::Rhymes;

my $mod = 'Word::Rhymes';
my $f = 't/data/zoo.data';

# return_raw disabled (default)
{
    my $o = $mod->new(file => $f);
    my $no_raw = $o->fetch('zoo');
    is ref $no_raw, 'HASH', "without return_raw, data type is HASH ok";
}

# return_raw enabled
{
    my $o = $mod->new(file => $f, return_raw => 1);
    my $raw = $o->fetch('zoo');
    is ref $raw, 'ARRAY', "with return_raw, data type is ARRAY ok";
}

# return_raw enabled (method)
{
    my $o = $mod->new(file => $f);
    my $no_raw = $o->fetch('zoo');
    is ref $no_raw, 'HASH', "without return_raw (method), data type is HASH ok";

    $o->return_raw(1);
    my $raw = $o->fetch('zoo');
    is ref $raw, 'ARRAY', "with return_raw (method), data type is ARRAY ok";
}

done_testing;
