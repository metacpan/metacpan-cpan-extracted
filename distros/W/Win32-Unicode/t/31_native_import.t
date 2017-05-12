use strict;
use warnings;
use utf8;
use Test::More;

use Win32::Unicode '-native';

my @subs = qw{
    printf warn say die error
    open close opendir closedir readdir
    file_type file_size copy move unlink touch rename
    mkdir rmdir getcwd chdir find finddepth mkpath rmtree mvtree cptree dir_size
};

require_ok 'Win32::Unicode::Native';
can_ok 'main', $_ for @subs;

ok tied *STDOUT, 'Win32::Unicode::Tie';

done_testing;
