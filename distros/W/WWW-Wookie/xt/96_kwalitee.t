# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;
use English qw(-no_match_vars);

use Test::More;

our $VERSION = v1.1.5;

if (
    !eval {
        require Test::Kwalitee;
        Test::Kwalitee->import( 'tests' => [qw( -has_meta_yml)] );
    }
  )
{
    Test::More::plan( 'skip_all' => 'Test::Kwalitee not installed; skipping' );
}
