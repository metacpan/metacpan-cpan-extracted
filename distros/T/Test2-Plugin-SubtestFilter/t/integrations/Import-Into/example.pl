use FindBin qw($Bin);
use lib "$Bin";

use TestSugar;

subtest 'foo' => sub {
    pass;
};

subtest 'bar' => sub {
    pass;
};

done_testing;
