use Test::More qw/no_plan/;

use_ok("Tie::Trace");

tie my %hash, "Tie::Trace";
my $self = (tied %hash);

ok($self->_matching([qr/hoge/], "hogehoge"));
ok($self->_matching([qr/foo/], "foobar"));
is($self->_matching(['hoge'], "hogehoge"), 0);
is($self->_matching(['foo'], "foobar"), 0);
ok($self->_matching([qr/hoge/, 'hoge'], "hogehoge"));
ok($self->_matching([qr/foo/, 'foo'], "foobar"));
ok($self->_matching([qr/hoge/, 'hoge'], "hoge"));
ok($self->_matching([qr/foo/, 'foo'], "foo"));
ok($self->_matching([qr/foo/, 'foo'], "foo"));
ok($self->_dumper([1, 2, 3], "[1,2,3]"));

my %hash2;
{
  no warnings;
  $Tie::Trace::QUIET = 1;
}

$hash{1} = \%hash2;
is((tied %hash2)->parent, tied %hash, "parent");
