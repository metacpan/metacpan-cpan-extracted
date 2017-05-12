package MyUtil;

use base qw/Util::Any/;
our $Utils =
  {
   list    => [['List::Util' => 'lu_']],
   -list   => [['List::Util' => 'lu_']],
   ':list' => [['List::Util' => 'lu_']],
   error   => ['Ktat::Ktat::Ktat'],
  };

1;
