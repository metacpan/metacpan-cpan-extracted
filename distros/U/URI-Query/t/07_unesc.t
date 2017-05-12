# Test input unescaping
# 
# Fixing bug #35170: https://rt.cpan.org/Public/Bug/Display.html?id=35170
#
# RFC2396: Within a query component, the characters ";", "/", "?", 
#    ":", "@", "&", "=", "+", ",", and "$" are reserved.
#

use strict;
use Test::More;
BEGIN { use_ok( 'URI::Query' ) }

my $data_esc = {
  group     => 'prod%2Cinfra%2Ctest',
  'op%3Aset'  => 'x%3Dy',
};
my $data_unesc = {
  group     => 'prod,infra,test',
  'op:set'  => 'x=y',
};
my $qs_esc = 'group=prod%2Cinfra%2Ctest&op%3Aset=x%3Dy';
my ($qq, $qs);

ok($qq = URI::Query->new($qs_esc), 'qq string constructor ok');
is_deeply(scalar $qq->hash, $data_unesc, '$qq->hash keys and values are unescaped');
is("$qq", $qs_esc, 'stringified keys/values escaped ok');

ok($qq = URI::Query->new($data_esc), 'qq hashref constructor ok');
is_deeply(scalar $qq->hash, $data_unesc, '$qq->hash keys and values are unescaped');
is("$qq", $qs_esc, 'stringified keys/values escaped ok');

ok($qq = URI::Query->new(%$data_esc), 'qq hash constructor ok');
is_deeply(scalar $qq->hash, $data_unesc, '$qq->hash keys and values are unescaped');
is("$qq", $qs_esc, 'stringified keys/values escaped ok');

done_testing;

