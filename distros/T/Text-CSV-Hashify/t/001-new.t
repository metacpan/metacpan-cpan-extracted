# perl
# t/001-new.t - check constructor
use strict;
use warnings;
use utf8;
use Carp;
use Scalar::Util qw( reftype looks_like_number );
use Test::More tests => 26;
use lib ('./lib');
use Text::CSV::Hashify;

my ($obj, $source, $key, $k, $limit);

{
    $source = "./t/data/names.csv";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new(
            file    => $source,
            key     => $key,
        );
    };
    like($@, qr/^Argument to 'new\(\)' must be hashref/,
        "'new()' died to lack of hashref as argument");
}

{
    $source = "./t/data/names.csv";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( [
            'file', $source, 'key', $key,
        ] );
    };
    like($@, qr/^Argument to 'new\(\)' must be hashref/,
        "'new()' died to lack of hashref as argument");
}

{
    $source = "./t/data/names.csv";
    $key = 'id';
    local $@;
    $k = 'xyz';
    eval {
        $obj = Text::CSV::Hashify->new( {
            file    => $source,
            key     => $key,
            format  => $k,
        } );
    };
    like($@, qr/^Entry '$k' for format is invalid/,
        "'new()' died due to bad argument for 'format' option");
}

{
    $source = "./t/data/names.csv";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            key => $key,
        } );
    };
    $k = 'file';
    like($@, qr/^Argument to 'new\(\)' must have '$k' element/,
        "'new()' died to lack of '$k' element in hashref argument");
}

{
    $source = "./t/data/names.csv";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file    => $source,
        } );
    };
    $k = 'key';
    like($@, qr/^Argument to 'new\(\)' must have 'key' element unless 'format' element is 'aoh'/,
        "'new()' died to lack of 'key' element in hashref argument when 'format' element was not 'aoh'");
}

{
    $source = "./t/data/foobar";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file    => $source,
            key     => $key,
        } );
    };
    like($@, qr/^Cannot locate file '$source'/,
        "'new()' died because '$source' was not found");
}

{
    $source = "./t/data/names.csv";
    $key = 'id';
    $limit = 'foobar';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file        => $source,
            key         => $key,
            max_rows    => $limit,
        } );
    };
            # "'max_rows' option, if defined, must be numeric";
    like($@, qr/^'max_rows' option, if defined, must be numeric/,
        "'max_rows' option to new() must be numeric");
}

{
    $source = "./t/data/names.csv";
    $key = 'id';
    $limit = '٤٠'; # 40 in Eastern Arabic numerals
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file        => $source,
            key         => $key,
            max_rows    => $limit,
        } );
    };
    like($@, qr/^'max_rows' option, if defined, must be numeric/,
        "'max_rows' option to new() must be in Western Arabic numerals");
}

{
    $source = "./t/data/names.csv";
    $key = 'id';
    $limit = '2٧'; # Western Arabic 2 followed by Eastern Arabic 7
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file        => $source,
            key         => $key,
            max_rows    => $limit,
        } );
    };
    like($@, qr/^'max_rows' option, if defined, must be numeric/,
        "'max_rows' option to new() must be only in Western Arabic numerals");
}

{
    $source = "./t/data/dupe_field_names.csv";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file    => $source,
            key     => $key,
        } );
    };
    $k = 'ssn';
    like($@, qr/^/,
        "'new()' died due to duplicate field '$k' in '$source'");
}

{
    $source = "./t/data/dupe_key_names.csv";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file    => $source,
            key     => $key,
        } );
    };
    $k = 4;
    like($@, qr/^Key '$k' already seen/,
        "'new()' died due to record with duplicate key '$k' in '$source'");
}

{   # Correct call to new()
    $source = "./t/data/names.csv";
    $key = 'id';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file    => $source,
            key     => $key,
        } );
    };
    is($@, '', "Correct call to 'new()'");
    ok($obj, "'new()' returned true value");
    isa_ok($obj, 'Text::CSV::Hashify');
    is(reftype($obj->{all}), 'HASH', "Record data stored as hash");
}

{   # Correct call to new() with 'max_rows' option
    $source = "./t/data/names.csv";
    $key = 'id';
    $limit = 10;
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file        => $source,
            key         => $key,
            max_rows    => $limit,
        } );
    };
    is($@, '', "Correct call to 'new()'");
    ok($obj, "'new()' returned true value");
    isa_ok($obj, 'Text::CSV::Hashify');
    is(scalar keys (%{$obj->{all}}), $limit,
        "'new()' parsed only '$limit' records requested");
}

{   # Correct call to new() with irrelevant 'max_rows' option
    $source = "./t/data/names.csv";
    $key = 'id';
    $limit = 70;
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file        => $source,
            key         => $key,
            max_rows    => $limit,
        } );
    };
    is($@, '', "Correct call to 'new()'");
    ok($obj, "'new()' returned true value");
    isa_ok($obj, 'Text::CSV::Hashify');
    is(scalar keys (%{$obj->{all}}), 12,
        "Value '$limit' of 'max_rows' option ignored; not enough records in '$source'");
}

{   # Correct call to new() with superfluous 'format' option
    $source = "./t/data/names.csv";
    $key = 'id';
    $k = 'hoh';
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file        => $source,
            key         => $key,
            format      => $k,
        } );
    };
    is($@, '', "Correct call to 'new()'");
    ok($obj, "'new()' returned true value");
    isa_ok($obj, 'Text::CSV::Hashify');
}
