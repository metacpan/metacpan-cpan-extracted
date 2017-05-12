#!/usr/bin/perl

use strict; use warnings;

use FindBin qw( $Bin );
use Test::More tests => 1;

require Test::FileReferenced;

# Check if Test::FileReferenced is able to hide the prompt.

our @diag_output;

chdir $Bin .q{/../};
$ENV{'PATH'} = $Bin .q{/fake_bin},
chmod 0755, $Bin . q{/fake_bin/diff};
chmod 0755, $Bin . q{/fake_bin/kdiff};

Test::FileReferenced::is_referenced_ok("Foo", "Fake", sub { return; });

$ENV{'FILE_REFERENCED_NO_PROMPT'} = 1;

Test::FileReferenced::at_exit();

is_deeply(
    \@diag_output,
    [
    ],
    "Prompt IS hidden"
);

# Overwrite 'diag':
package Test::More;

no warnings;
sub diag { # {{{
    return push @diag_output, @_;
} # }}}

# vim: fdm=marker
