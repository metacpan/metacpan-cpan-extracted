#!/usr/bin/perl

use strict; use warnings;

use File::Spec;
use English qw( -no_match_vars );
use FindBin qw( $Bin );
use Test::More;
use YAML::Any qw( LoadFile );

if ($OSNAME =~ m/MSWin/) {
    plan skip_all => 'MSWin32 not supported (Fixme!)';
}
plan tests => 2;

require Test::FileReferenced;

# Check if Test::FileReferenced displays correct prompt.

our @diag_output;

chdir File::Spec->catdir($Bin, q{..});
$ENV{'PATH'} = File::Spec->catdir($Bin, q{fake_bin});
chmod 0755, File::Spec->catfile($Bin, q{fake_bin}, q{diff});
chmod 0755, File::Spec->catfile($Bin, q{fake_bin}, q{kdiff});

Test::FileReferenced::is_referenced_ok("Foo", "Fake", sub { return; });
Test::FileReferenced::is_referenced_ok("Bar", "Miss", sub { return; });

Test::FileReferenced::at_exit();

is_deeply(
    \@diag_output,
    [
        q{No reference for test 'Miss' found. Test will fail.},
        q{Resulting and reference files differ. To see differences run one of:},
        q{      diff t#feature-display_prompt-result.yaml t#feature-display_prompt.yaml},
        q{     kdiff t#feature-display_prompt-result.yaml t#feature-display_prompt.yaml},
        qq{\n},
        q{If the differences ware intended, reference data can be updated by running:},
        q{        mv t#feature-display_prompt-result.yaml t#feature-display_prompt.yaml},
    ],
    "Prompt OK"
);

is_deeply(
    LoadFile(File::Spec->catdir($Bin, q{feature-display_prompt-result.yaml})),
    {
        Fake => 'Foo',
        Miss => 'Bar',
    },
    "Results OK"
);

# Overwrite 'diag':
package Test::More;

no warnings;
sub diag { # {{{
    my ( $msg ) = @_;
    $msg =~ s{[\/\\]}{#}sg; # Poor-man's platform independence.
    return push @diag_output, $msg;
} # }}}

sub fail { # {{{
    return 0;
} # }}}

# vim: fdm=marker
