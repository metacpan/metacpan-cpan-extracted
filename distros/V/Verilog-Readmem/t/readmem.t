
use warnings;
use strict;
use Test::More tests => 32;

# Check if module loads ok
BEGIN { use_ok('Verilog::Readmem', qw(parse_readmem)) }

# Check module version number
BEGIN { use_ok('Verilog::Readmem', '0.05') }


my @aoa_expect;
my $ref_actual;
my $dir = 't/hdl';
my $file;


# numeric-mode tests

$file = 'split.hex';
@aoa_expect = ( [qw(0 1 2 3)] );
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'just_data.hex';
@aoa_expect = ( [qw(
    0
    1
    2
    3
    47806
    56030
    5
    1
    2
    3
    4
    3822
    56797
    2882400001
    4660
    1911
    0
    14539980
    64222
    291
    291
    1929
    4294967295
    439078383
)]);
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'addr_before_data.hex';
@aoa_expect = ( [qw(10 4095 64222 65537 6 7)] );
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'multi_block.hex';
@aoa_expect = (
      [qw(0 291 4 5 6 7)]
    , [qw(16 17 18 19 20)]
    , [qw(32 255 238 221)]
    , [qw(64 153 2184 1911)]
);
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'multi_block0.hex';
@aoa_expect = (
      [qw(0 5 4 3 2 1)]
    , [qw(0 10 11 12)]
    , [qw(0 0 9 3)]
    , [qw(0 2 4 6 8)]
);
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'big.hex';
@aoa_expect = ( [(0, 0 .. 65535)] );
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);

# Same as above, but string=>0 for coverage
$ref_actual = parse_readmem({filename => "$dir/$file", string=>0});
is_deeply($ref_actual, \@aoa_expect, $file);


# string-mode tests

$file = 'data_x.bin';
@aoa_expect = ( [qw(0 0 1 1111 10101 011x1 110011)] );
$ref_actual = parse_readmem({filename => "$dir/$file", string=>1, binary=>1});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'data_x.hex';
@aoa_expect = ( [qw(0 6 7 9 3x 55 22)] );
$ref_actual = parse_readmem({filename => "$dir/$file", string=>1, binary=>0});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'data_z.bin';
@aoa_expect = ( [qw(2 0 1 0 1 z 1)] );
$ref_actual = parse_readmem({filename => "$dir/$file", string=>1, binary=>1});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'data_z.hex';
@aoa_expect = ( [qw(0 6 7 9 zz90 55 22)] );
$ref_actual = parse_readmem({filename => "$dir/$file", string=>1, binary=>0});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'addr_after_data.hex';
@aoa_expect = ( [qw(0 0 1 2)], [qw(___5__ 5 6 7 1xz8_9x xxzz zxzx)] );
$ref_actual = parse_readmem({string  =>  1, filename=>"$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);


# corner case: 2 blocks at same address

$file = 'multi_block_misc.hex';
@aoa_expect = (
      [qw(2 5 10 4 11)]
    , [qw(8 15 14 13 12)]
    , [qw(4 255)]
    , [qw(0 0)]
    , [qw(4 221)]
);
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);


# corner case: no data

$file = 'empty.dat';
@aoa_expect = ();
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'just_addr.dat';
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);

$file = 'just_comments.dat';
$ref_actual = parse_readmem({filename => "$dir/$file"});
is_deeply($ref_actual, \@aoa_expect, $file);


# Check error messages

$@ = '';
eval { $ref_actual = parse_readmem() };
like($@, qr/filename is required/, 'die if no option hash');

$file = 'ill_data.hex';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file"}) };
like($@, qr/unsupported characters in 2-state readmemh input/, "die on $file");

$file = 'ill_data.hex';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file", string=>1}) };
like($@, qr/unsupported characters in 4-state readmemh input/, "die on $file");

$file = 'ill_data.bin';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file", binary=>1}) };
like($@, qr/unsupported characters in 2-state readmemb input/, "die on $file");

$file = 'ill_data.bin';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file", binary=>1, string=>1}) };
like($@, qr/unsupported characters in 4-state readmemb input/, "die on $file");

$file = 'ill_data.dat';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file"}) };
like($@, qr/illegal leading underscore for data/, "die on $file");

$file = 'wide_data.hex';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file"}) };
like($@, qr/Hex value exceeds 32-bits/, "die on $file");

$file = 'wide_data.bin';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file", binary=>1}) };
like($@, qr/Binary value exceeds 32-bits/, "die on $file");

$file = 'wide_addr.dat';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file", binary=>1}) };
like($@, qr/Hex address exceeds 32-bits/, "die on $file");

$file = 'ill_addr_hex.dat';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file", string=>1}) };
like($@, qr/unsupported characters in 2-state string address/, "die on $file");

$file = 'ill_addr_hex.dat';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file"}) };
like($@, qr/unsupported characters in 2-state address/, "die on $file");

$file = 'ill_addr_x.dat';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file"}) };
like($@, qr/unsupported characters in 2-state address/, "die on $file");

$file = 'ill_addr_z.dat';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file"}) };
like($@, qr/unsupported characters in 2-state address/, "die on $file");

$file = 'file-does-not-exist.dat';
$@ = '';
eval { $ref_actual = parse_readmem({filename => "$dir/$file"}) };
like($@, qr/Can not open file/, 'die if file does not exist');

