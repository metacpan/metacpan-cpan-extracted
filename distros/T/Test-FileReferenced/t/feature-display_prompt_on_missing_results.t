#!/usr/bin/perl

use strict; use warnings;

use FindBin qw( $Bin );
use Test::More tests => 1;

require Test::FileReferenced;

# Check if Test::FileReferenced displays correct prompt.

our @diag_output;

chdir File::Spec->catdir($Bin, q{..});

Test::FileReferenced::is_referenced_ok("Foo", "Fake", sub { return; });

Test::FileReferenced::at_exit();

is_deeply(
    \@diag_output,
    [
        q{No reference file found. All calls to is_referenced_ok WILL fail.},
        q{No reference for test 'Fake' found. Test will fail.},
        q{No reference file found. It'a a good idea to create one from scratch manually.},
        q{To inspect current results run:},
        q{       cat t#feature-display_prompt_on_missing_results-result.yaml},
        qq{\n},
        q{If You trust Your test output, You can use it to initialize deference file, by running:},
        q{        mv t#feature-display_prompt_on_missing_results-result.yaml t#feature-display_prompt_on_missing_results.yaml},
    ],
    "Prompt OK"
);

# Overwrite 'diag':
package Test::More;

no warnings;
sub diag { # {{{ 
    my ( $msg ) = @_;
    $msg =~ s{[\/\\]}{#}sg; # Poor-man's platform independence.
    return push @diag_output, $msg;
} # }}}

sub fail {
    return 1;
}

# vim: fdm=marker
