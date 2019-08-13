use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Test2::Plugin::TodoFailOnSuccess') };

diag(qq(Test2::Plugin::TodoFailOnSuccess Perl $], $^X));

done_testing;

