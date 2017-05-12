use strict;
use warnings;
use utf8;
use Test::More;

use Test::Requires::Scanner;

my $ret = Test::Requires::Scanner->scan_string('use Test::Requires 0.99 {"DBI" => 1};');
is_deeply $ret, {
    DBI => 1,
};

$ret = Test::Requires::Scanner->scan_string('use Test::Requires {DBI => "1"};');
is_deeply $ret, {
    DBI => 1,
};

$ret = Test::Requires::Scanner->scan_string('use Test::Requires 0.99 "DBI";');
is_deeply $ret, {
    DBI => undef,
};

$ret = Test::Requires::Scanner->scan_string('use Test::Requires 0.99 ("DBI");
use Test::More 0.98');
is_deeply $ret, {
    DBI => undef,
};

$ret = Test::Requires::Scanner->scan_string(q{use Test::Requires ("CDBI", 'DBI')});
is_deeply [sort keys %$ret], ['CDBI', 'DBI'];

$ret = Test::Requires::Scanner->scan_string(q{use Test::Requires "CDBI", 'DBI'});
is_deeply [sort keys %$ret], ['CDBI', 'DBI'];

done_testing;
