package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
use Test2::Tools::LoadModule qw{ :private };

BEGIN {
    # We do this in a BEGIN block to prevent the compiler from seeing
    # our 'use ...' statements unless we can actually run the tests.
    $] lt '5.010'
	and plan skip_all => "The hints mechanism does not work under Perl $]";
}

is __get_hint_hash( 0 ), {
    load_error	=> DEFAULT_LOAD_ERROR,
}, 'Default hint hash';

{
    my $load_error_error;
    BEGIN { $load_error_error = 'Error:  %s'; }

    use Test2::Tools::LoadModule -load_error => $load_error_error;

    is __get_hint_hash( 0 ), {
	load_error	=> $load_error_error,
    }, "load_error set to '$load_error_error'";

    my $load_error_1;
    BEGIN { $load_error_1 = 1; }

    use Test2::Tools::LoadModule -load_error => $load_error_1;

    is __get_hint_hash( 0 ), {
	load_error	=> DEFAULT_LOAD_ERROR,
    }, "setting load_error to '$load_error_1' restores default";

    my $load_error_0;
    BEGIN { $load_error_0 = 0; }

    use Test2::Tools::LoadModule -load_error => $load_error_0;

    is __get_hint_hash( 0 ), {
	load_error	=> $load_error_0,
    }, "load_error set to '$load_error_0'";

}

is __get_hint_hash( 0 ), {
    load_error	=> DEFAULT_LOAD_ERROR,
}, 'Scope exit restores default hint hash';



done_testing;

1;

# ex: set textwidth=72 :
