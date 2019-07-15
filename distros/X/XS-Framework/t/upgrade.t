use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use XS::Framework;

my $obj;

# undefs to HV
$obj = bless \(my $a = undef), 'AAA';
XS::Framework::obj2hv($obj);
ok($obj->{key} = 1);
is($obj->{key}, 1);
ok defined $a;
XS::Framework::obj2hv($obj);


# undefs to AV
$obj = bless \(my $d = undef), 'AAA';
XS::Framework::obj2av($obj);
ok($obj->[9] = 1);
is($obj->[9], 1);

# numbers
$obj = bless \(my $b = 1), 'AAA';
ok(!eval {XS::Framework::obj2hv($obj); 1});
ok(!eval {$obj->{key} = 1; 1});

$obj = bless \(my $e = 1.0213), 'AAA';
ok(!eval {XS::Framework::obj2av($obj); 1});
ok(!eval {$obj->[9] = 1; 1});

# strings
$obj = bless \(my $c = 'asd'), 'AAA';
ok(!eval {XS::Framework::obj2hv($obj); 1});
ok(!eval {$obj->{key} = 1; 1});

done_testing();
