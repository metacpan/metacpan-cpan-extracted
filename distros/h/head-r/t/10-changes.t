### 10-changes.t --- Check if our Changes file fits  -*- Perl -*-

use strict;
use warnings;

use Test::More;

eval { require Test::CPAN::Changes; };
plan ("skip_all"
      => ("Test::CPAN::Changes is required for this test"))
    if ($@);

plan (qw (tests 4));

## NB: changes_file_ok () accounts for 4 tests
Test::CPAN::Changes::changes_file_ok ();

## Local variables:
## coding: us-ascii
## End:
### 10-changes.t ends here
