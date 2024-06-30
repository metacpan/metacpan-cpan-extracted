# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

our $VERSION = v1.1.5;
if ( !eval { require Test::Spelling; } ) {
    Test::More::plan(
        'skip_all' => q{Test::Spelling required to check spelling of POD} );
}

Test::Spelling::all_pod_files_spelling_ok();
