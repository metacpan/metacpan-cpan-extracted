package XS::Framework;
use 5.018;
use Config;
use next::XS;
use CPP::panda::lib;

our $VERSION = '1.1.0';

# threads::shared doesn't respect the fact that PL_destroyhook might be in use by other modules and doesn't proxy call to next hook
# so that we must hook after threads::shared
if ($Config{useithreads}) {
    require threads;
    require threads::shared;
}

XS::Loader::load();

END {
    __at_perl_destroy();
}

1;
