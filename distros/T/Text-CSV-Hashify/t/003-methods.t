# perl
# t/003-methods.t - check constructor
use strict;
use warnings;
use Carp;
use Scalar::Util qw( reftype looks_like_number );
use Text::CSV::Hashify;
use Test::More tests => 22;

my ($obj, $source, $key, $href, $aref, $k, $z);

$source = "./t/data/names.csv";
$key = 'id';
$obj = Text::CSV::Hashify->new( {
    file    => $source,
    key     => $key,
} );
ok($obj, "'new()' returned true value");

$href = $obj->all();
$k = 12;
is(scalar(keys %{$href}), $k,
    "'all()' returned hashref with $k elements");

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
$href = $obj->record(1);
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
$z = $obj->datum('1','last_name');
is($z, $k, "'datum()' returned expected datum $k");

$k = [ (1..12) ];
$aref = $obj->keys();
is_deeply($aref, $k, "Got expected list of unique keys");

# If another field in the same CSV file has all unique entries, we can use it
# as the 'key' as well.

$source = "./t/data/names.csv";
$key = 'ssn';
$obj = Text::CSV::Hashify->new( {
    file    => $source,
    key     => $key,
} );
ok($obj, "'new()' returned true value");

$href = $obj->all();
$k = 12;
is(scalar(keys %{$href}), $k,
    "'all()' returned hashref with $k elements");

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
$href = $obj->record('999-99-9999');
is_deeply($href, $k, "'record()' returned expected data from one record");

{
    local $@;
    eval { $z = $obj->datum('999-99-9999'); };
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
    eval { $z = $obj->datum('999-99-9999', ''); };
    $k = 1;
    like($@,
        qr/^Argument to 'datum\(\)' at index '$k' either not defined or non-empty/,
        "'datum()' failed due to undefined argument");
}
$k = 'Zoltan';
$z = $obj->datum('999-99-9999','last_name');
is($z, $k, "'datum()' returned expected datum $k");

$k = [ reverse( map { '999-99-' . $_ } (9988..9999) ) ];
$aref = $obj->keys();
is_deeply($aref, $k, "Got expected list of unique keys");

