use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
    use_ok('XUL::App');
    use_ok('XUL::App::I18N');
    use_ok('XUL::App::JSFile');
    use_ok('XUL::App::XPIFile');
    use_ok('XUL::App::XULFile');
    use_ok('XUL::App::Schema');
    use_ok('XUL::App::View::Base');
    use_ok('XUL::App::View::Install');
};

