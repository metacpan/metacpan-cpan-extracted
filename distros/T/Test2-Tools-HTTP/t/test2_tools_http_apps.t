use Test2::V0 -no_srand => 1;
use Test2::Tools::HTTP::Apps;

subtest 'singleton' => sub {

  my $apps1 = Test2::Tools::HTTP::Apps->new;
  my $apps2 = Test2::Tools::HTTP::Apps->new;

  ref_is $apps1, $apps2;

};

done_testing;
