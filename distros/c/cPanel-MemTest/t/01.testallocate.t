use Test::More tests => 6;
use Test::Warn;

BEGIN {
    use_ok('cPanel::MemTest', 'testallocate');
}

diag( "Testing cPanel::MemTest $cPanel::MemTest::VERSION" );


is( testallocate(100),  100, 'simple allocate');
is(alloc_with_warn(0),    0, 'Error on allocating no memory');
is(alloc_with_warn(1025), 0, 'Max mem to alloc is 1024 Meg.');

sub alloc_with_warn {
  my $size = shift;
  my $got; 
  warning_is {$got = testallocate($size)} "Unable to allocate $size Megabytes of memory (Invalid Argument)", "warning message complains about bad values";
  return $got;
}
