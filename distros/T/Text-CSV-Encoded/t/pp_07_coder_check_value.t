
use strict;
use Test::More;

use lib qw(./t);
use _setup;

BEGIN {
    _setup->tests(2);
}

require './t/tests/07_coder_check_value_euc-jp.t';


__END__
