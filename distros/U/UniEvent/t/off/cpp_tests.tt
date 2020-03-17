use 5.012;
use warnings;

use UniEvent;
use CPP::catch;
use XS::Loader;

XS::Loader::load_tests();

catch_run($ENV{CPP_TEST} || '[panda-event]');
