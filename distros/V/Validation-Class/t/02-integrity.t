use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

SKIP: {

    eval {
        require 'Perl/Critic.pm';
    };

    plan skip_all =>
        'Perl::Critic is not installed and/or DEVELOPMENT_TESTS is not set.'
        if $@ || ! $ENV{'DEVELOPMENT_TESTS'}
    ;

    my $lib     = $FindBin::RealBin . "/../lib/";
    my @profile = qw(
        -5
        --severity 4
        --exclude Modules::RequireVersionVar
        --exclude Subroutines::RequireArgUnpacking
        --exclude BuiltinFunctions::RequireBlockGrep
        --exclude Subroutines::ProhibitBuiltinHomonyms
        --exclude Modules::ProhibitAutomaticExportation
        --exclude TestingAndDebugging::ProhibitNoStrict
        --exclude TestingAndDebugging::ProhibitNoWarnings
        --exclude Variables::ProhibitConditionalDeclarations
        --exclude ValuesAndExpressions::ProhibitAccessOfPrivateData
        --exclude TestingAndDebugging::ProhibitProlongedStrictureOverride
    );

    ok ! system("perlcritic", @profile, $lib), "library passes critique";

}

done_testing;
