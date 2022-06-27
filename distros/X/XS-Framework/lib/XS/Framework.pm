package XS::Framework;
use 5.018;
use Config;
use next::XS;
use XS::libpanda;
use XS::ErrorCode();
use XS::STL::ErrorCode();
use XS::STL::ErrorCategory();

our $VERSION = '1.5.3';

# threads::shared doesn't respect the fact that PL_destroyhook might be in use by other modules and doesn't proxy call to next hook
# so that we must hook after threads::shared
if ($Config{useithreads}) {
    require threads;
    require threads::shared;
    no warnings 'redefine';
    my $orig_threads_create = \&threads::create;
    *threads::create = sub {
        __at_thread_create();
        goto &$orig_threads_create;
    };
}

XS::Loader::load();

END {
    __at_perl_destroy();
}

1;
