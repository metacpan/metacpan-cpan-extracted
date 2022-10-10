use 5.012;
use warnings;
use Test::More;
use XS::Framework;
use Scalar::Util qw(reftype);

my $obj;

# undefs to HV
my $aaa = undef;
$obj = bless \($aaa), 'AAA';
is(Scalar::Util::reftype(\$aaa), 'SCALAR');
XS::Framework::obj2hv($obj);
ok($obj->{key} = 1);
is($obj->{key}, 1);
is(Scalar::Util::reftype(\$aaa), 'HASH');
XS::Framework::obj2hv($obj);


# undefs to AV
my $ddd = undef;
$obj = bless \($ddd), 'AAA';
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
