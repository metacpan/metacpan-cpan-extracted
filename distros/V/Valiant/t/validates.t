{
  package Local::A;

  use Moo;

  with 'Valiant::Util::Ancestors';
  with 'Valiant::Validates';

  has equals => (is=>'ro', default=>303);


  __PACKAGE__->validates(equals => (numericality => [5,100]));
}

use Test::Most;

ok my $a = Local::A->new;
ok $a->invalid;

is_deeply +{$a->errors->to_hash}, +{
  "equals",
    [
      "must be less than or equal to 100",
    ]
  };

done_testing;
