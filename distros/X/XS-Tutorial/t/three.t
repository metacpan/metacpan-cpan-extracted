package Tie::Test;
require Tie::Scalar;
@ISA = 'Tie::Scalar';
sub FETCH { 'foobar' }
sub new { bless {}, shift }

package main;
use Test::More;
use Encode qw(encode decode);

BEGIN { use_ok 'XS::Tutorial::Three' }

subtest 'get_tied_value' => sub {
  tie my $foo, 'Tie::Test';
  is XS::Tutorial::Three::get_tied_value($foo), 'foobar', 'returns magic value when passed a tied scalar';
};

subtest 'is_utf8' => sub {
  my $heart = decode 'UTF-8', "♥";
  ok XS::Tutorial::Three::is_utf8($heart), 'black heart suit is utf8';
  ok !XS::Tutorial::Three::is_utf8("1"), '1 is not utf8';
};

subtest 'is_downgradeable' => sub {
  my $imp = decode 'UTF-8', "😈";
  ok !XS::Tutorial::Three::is_downgradeable($imp), 'imp is not downgradeable';
  ok XS::Tutorial::Three::is_downgradeable('foobar'), '"foobar" is downgradeable';
};

done_testing;
