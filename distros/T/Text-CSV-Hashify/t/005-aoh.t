# perl
# t/005-aoh.t - check 'aoh' storage format
use strict;
use warnings;
use Carp;
use Scalar::Util qw( reftype looks_like_number );
use Text::CSV::Hashify;
use Test::More tests => 23;

my ($obj, $source, $k, $href, $aref, $z, $limit);

{
    $source = "./t/data/dupe_key_names.csv";
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file    => $source,
            format  => 'aoh',
        } );
    };
    is($@, '', "Correct call to 'new()'");
    ok($obj, "'new()' returned true value");
    isa_ok($obj, 'Text::CSV::Hashify');
    is(reftype($obj->{all}), 'ARRAY', "Record data stored as array");
    
    $aref = $obj->all();
    $k = 6;
    is(scalar(@{$aref}), $k,
        "'all()' returned array with $k elements");
    
    $k = [ qw| id ssn first_name last_name address city state zip | ];
    $aref = $obj->fields();
    is_deeply($aref, $k, "'fields()' returned expected list of fields");
    
    $k = { 
        id => 1,
        ssn => '999-99-9999',
        first_name => 'Alice',
        last_name => 'Zoltan',
        address => '360 5 Avenue, Suite 1299',
        city => 'New York',
        state => 'NY',
        zip => '10001',
    };
    {
        local $@;
        eval { $href = $obj->record(); };
        like($@, qr/Argument to 'record\(\)' either not defined or non-empty/,
            "'record()' failed due to lack of argument");
    }
    {
        local $@;
        eval { $href = $obj->record(''); };
        like($@, qr/^Argument to 'record\(\)' either not defined or non-empty/,
            "'record()' failed due to lack of argument");
    }
    $href = $obj->record(0);
    is_deeply($href, $k, "'record()' returned expected data from one record");
    
    $k = { 
        id => 4,
        ssn => '999-99-9996',
        first_name => 'Dennis',
        last_name => 'Waterstone',
        address => '870 Oliver Alley, #5B',
        city => 'Oklahoma City',
        state => 'OK',
        zip => '77777',
    };
    $href = $obj->record(3);
    is_deeply($href, $k, "'record()' returned expected data from one record");
    
    $k = { 
        id => 4,
        ssn => '999-99-9995',
        first_name => 'Enrique',
        last_name => 'Victor',
        address => '929 Milltown Manor',
        city => 'Milwaukee',
        state => 'WI',
        zip => '53707',
    };
    $href = $obj->record(4);
    is_deeply($href, $k, "'record()' returned expected data from one record");
    
    {
        local $@;
        eval { $z = $obj->datum('1'); };
        like($@, qr/^'datum\(\)' needs two arguments/,
            "'datum()' failed due to insufficient number of arguments");
    }
    {
        local $@;
        eval { $z = $obj->datum(undef, 'last_name'); };
        $k = 0;
        like($@,
            qr/^Argument to 'datum\(\)' at index '$k' either not defined or non-empty/,
            "'datum()' failed due to undefined argument");
    }
    {
        local $@;
        eval { $z = $obj->datum(1, ''); };
        $k = 1;
        like($@,
            qr/^Argument to 'datum\(\)' at index '$k' either not defined or non-empty/,
            "'datum()' failed due to undefined argument");
    }
    $k = 'Zoltan';
    $z = $obj->datum('0','last_name');
    is($z, $k, "'datum()' returned expected datum $k");
    
    $k = 'Waterstone';
    $z = $obj->datum('3','last_name');
    is($z, $k, "'datum()' returned expected datum $k");
    
    $k = 'Victor';
    $z = $obj->datum('4','last_name');
    is($z, $k, "'datum()' returned expected datum $k");
    
    {
        local $@;
        eval { $aref = $obj->keys(); };
        like($@, qr/^'keys\(\)' method not appropriate when 'format' is 'aoh'/,
            "'keys' method properly died when format was 'aoh'");
    }
}

{
    $source = "./t/data/dupe_key_names.csv";
    $limit = 4;
    local $@;
    eval {
        $obj = Text::CSV::Hashify->new( {
            file        => $source,
            format      => 'aoh',
            max_rows    => $limit,
        } );
    };
    is($@, '', "Correct call to 'new()'");
    ok($obj, "'new()' returned true value");
    isa_ok($obj, 'Text::CSV::Hashify');
    is(reftype($obj->{all}), 'ARRAY', "Record data stored as array");
    is(scalar(@{$obj->{all}}), $limit,
        "'new()' parsed only '$limit' records requested");
}

