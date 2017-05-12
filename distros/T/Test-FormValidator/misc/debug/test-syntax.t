  use strict;

  use Test::More 'no_plan';
  use Test::Builder::Tester;

  ok(0, 'this should fail');

  test_out('not ok 1 - tbt fail');
  ok(0, 'tbt fail');
  test_fail(-1);
  test_test('caught failed tests');

  my $check = '#     Failed test (t/04-test-methods.t at line 66)';


  if( $check =~ /\A(.*)#     (Failed .*test) \((.*?) at line (\d+)\)\z/ ) {
      print STDERR "manual match passes!\n";
  }
  else {
      print STDERR "manual match fails!\n";
  }

  my $transformed = Test::Tester::Tie->_translate_Failed_check($check);

  print STDERR "check:        [$check]\n";
  print STDERR "transformed:  [$transformed]\n";
  print STDERR "\$transformed eq \$check: "
               . ($transformed eq $check? 'yes' : 'no')
               . "\n";
  print STDERR "TB Version:   $Test::Builder::VERSION\n";
  print STDERR "TBT Version:  $Test::Builder::Tester::VERSION\n";
  print STDERR "Perl Version: $]\n";
  print STDERR "OS:           $^O\n";