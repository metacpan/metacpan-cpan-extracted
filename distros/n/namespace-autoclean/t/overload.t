use strict;
use warnings;
use Test::More 0.88;

sub main::iter { "welp" };
{
    package Foo;
    use overload
      'bool' => sub(){1},
      '<>' => \&main::iter,
      '0+' => 'numify',
      fallback => 1,
    ;
    use namespace::autoclean;
    sub numify { 219 }
    sub new { bless {}, $_[0] }
}

my $o = Foo->new;
is sprintf('%d', $o), 219, 'method name overload';
is sprintf('%s', $o), 219, 'fallback overload';
is scalar <$o>, 'welp', 'subref overload';

done_testing;
