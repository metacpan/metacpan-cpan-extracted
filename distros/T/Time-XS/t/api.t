use Test::More;
use Test::Catch;
use Time::XS;

XS::Loader::load('MyTest');
catch_run('api');

done_testing();
