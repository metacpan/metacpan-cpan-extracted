use Test::More;
use 5.01;
my $warnings_installed;
BEGIN {
  $warnings_installed = 2;
    eval {require Test::Warnings};
  if ($@) {
    plan skip_all => 'Test::Warnings not installed';
    exit;
  }else{
    plan (tests => 3 + $warnings_installed);
    Test::Warnings->import(':all');
  }
    use_ok 't::testparser';
}
t::testparser->init(qw|Start_Test Start_test End_test Endtest|, sub{lc $_[1]});
my @w = warnings {t::testparser->new};
is(scalar @w ,$warnings_installed, "$warnings_installed warnings were issued in new");
foreach $w (@w){
  ok($w =~ qr/((?-x:Start_(?i:t)est and Start_(?i:t)est translate to the same handler)
	     |(?-x:the sub End_?test overrides the handler for End_?test)
	     )(?-x: at $0)/x, $1);
}
