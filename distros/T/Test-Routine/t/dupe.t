use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/lib';

{
  my $err = exception { require NoGood };
  like(
    $err,
    qr/with the same name/,
    "having two tests with the same name is disallowed",
  );
}

{
  my $err = exception { require NoGood2 };
  like(
    $err,
    qr/there's already a subroutine named/,
    "a test/subroutine name mismatch is not allowed",
  );
}

done_testing;
