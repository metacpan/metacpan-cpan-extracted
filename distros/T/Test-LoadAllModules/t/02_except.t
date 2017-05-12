use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Test::LoadAllModules;

BEGIN {
    all_uses_ok(
        search_path => 'MyApp',
        except      => [ 'MyApp::Test', qr/MyApp::RegEx*/ ]
    );
}
