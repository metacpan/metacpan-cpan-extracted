package XML::Grammar::Fiction::Builder;

use strict;
use warnings;

use base 'XML::Grammar::Builder';

sub get_test_run_test_files
{
    return [glob("t/*.t t/*/*.t")]
}

1;
