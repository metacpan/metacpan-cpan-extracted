use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;

use Win32::Unicode::File qw/filename_normalize/;

close STDERR; # warnings to be quiet

dies_ok { filename_normalize() };

sub normalize { filename_normalize(shift) }

for (@{test_data()}) {
    is normalize( $_->{input} ), $_->{expected}, $_->{desc};
}

done_testing;

sub test_data {
    return [
        {
            desc     => 'test [ \ ]',
            input    => 'test_is_\_filename.txt',
            expected => 'test_is_￥_filename.txt',
        },
        {
            desc     => 'test [ / ]',
            input    => 'test_is_/_filename.txt',
            expected => 'test_is_／_filename.txt',
        },
        {
            desc     => 'test [ : ]',
            input    => 'test_is_:_filename.txt',
            expected => 'test_is_：_filename.txt',
        },
        {
            desc     => 'test [ * ]',
            input    => 'test_is_*_filename.txt',
            expected => 'test_is_＊_filename.txt',
        },
        {
            desc     => 'test [ ? ]',
            input    => 'test_is_?_filename.txt',
            expected => 'test_is_？_filename.txt',
        },
        {
            desc     => 'test [ " ]',
            input    => 'test_is_"_filename.txt',
            expected => 'test_is_″_filename.txt',
        },
        {
            desc     => 'test [ < ]',
            input    => 'test_is_<_filename.txt',
            expected => 'test_is_＜_filename.txt',
        },
        {
            desc     => 'test [ > ]',
            input    => 'test_is_>_filename.txt',
            expected => 'test_is_＞_filename.txt',
        },
        {
            desc     => 'test [ | ]',
            input    => 'test_is_|_filename.txt',
            expected => 'test_is_｜_filename.txt',
        },
    ];
};
