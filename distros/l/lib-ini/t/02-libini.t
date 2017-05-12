use strict;
use warnings;

use Test::Most;
use File::chdir;
use File::Temp  qw(tempdir);
use File::Slurp qw(write_file);
use lib::ini;

### generate test packages

{
    package lib::ini::testplugin;

    our @inc;

    sub import {
        my ($class, %args) = @_;
        unshift @inc, $class->generate_inc(%args);
    }
}

{
    package lib::ini::plugin::mylib;
    use base 'lib::ini::testplugin';

    sub generate_inc { return 'mylib' }
}

{
    package lib::ini::plugin::theirlib;
    use base 'lib::ini::testplugin';

    sub generate_inc { return 'theirlib' }
}

{
    package lib::ini::plugin::multilib;
    use base 'lib::ini::testplugin';

    sub generate_inc {
        my ($class, %args) = @_;
        return @{$args{dir}};
    }
}

### test data and expected results

my @tests = (
    [ '01 add to inc',                  "[mylib]",                                 ['mylib']             ],
    [ '02 add to inc twice',            "[mylib]\n[mylib]",                        ['mylib','mylib']     ],
    [ '03 add to inc from two plugins', "[mylib]\n[theirlib]",                     ['theirlib','mylib']  ],
    [ '04 add to inc with args',        "[multilib]\ndir=one\ndir=two\ndir=three", ['one','two','three'] ],
);

### run tests

foreach my $test ( @tests ) {
    my ($name, $config, $expected) = @$test;

    my $tempdir = tempdir;
    $CWD = $tempdir;
    write_file('lib.ini', $config);

    lib::ini->import;

    is_deeply \@lib::ini::testplugin::inc, $expected, $name;

    undef @lib::ini::testplugin::inc;
}

done_testing;
