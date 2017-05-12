use t::boilerplate;

use English      qw( -no_match_vars );
use Scalar::Util qw( blessed );
use Test::More;

use Unexpected;
use Unexpected::Functions;
use Unexpected::Functions { into => 'main' };
use Unexpected::Functions qw( :all );

eval { eval { throw 'Bite Me' }; throw_on_error }; my $e = $EVAL_ERROR;
is $e->error, 'Bite Me', 'Throw_on_error function';
is blessed $e, 'Unexpected', 'Function throw correct class';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
