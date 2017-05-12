#!perl -w
use strict;
use Test::More;
use UNIVERSAL::source_location_for;
use Path::Class;
use FindBin::libs;
use Chi;

_is(
    Chi->source_location_for('child_method'),
    file(__FILE__)->dir->subdir(qw(lib))->file('Chi.pm')->absolute,
    6
);

_is(
    Chi->source_location_for('parent_method'),
    file(__FILE__)->dir->subdir(qw(lib))->file('Par.pm')->absolute,
    5
);

_is(
    Chi->source_location_for('null'),
    undef,
    undef
);

done_testing;

sub _is {
    my ($path, $line_num, $ex_path, $ex_line_num) = @_;
    is $path, $ex_path;
    is $line_num, $ex_line_num;
}
