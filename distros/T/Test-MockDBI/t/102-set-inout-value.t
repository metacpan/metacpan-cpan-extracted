use strict;
use warnings;

use Test::More;
use Test::Warn;
use_ok('Test::MockDBI');


my $mockinst = Test::MockDBI::get_instance();

{
  #Call should fail if no sql is provided
  warning_like{
    ok(!$mockinst->set_inout_value(undef, 1, 15), "undef provided as sql");
  } qr/Parameter SQL must be a scalar string/, "Calling set_inout_value without sql generates warning";
  
}
{
  #Call should fail if no sql is provided
  warning_like{
    ok(!$mockinst->set_inout_value('CALL proc(?)', 'asdf'), "p_num is not numeric");
  } qr/Parameter p_num must be numeric/, "Calling set_inout_value without a numeric p_num generates a warning";
  
}
done_testing();