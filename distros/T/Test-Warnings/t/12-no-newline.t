use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings ':no_end_test', 'warnings';

{
    my ($line, $file);

    my @warnings = warnings { warn "a normal warning"; $line = __LINE__; $file = __FILE__ };
    like(
        $warnings[0],
        qr/^a normal warning at \Q$file\E line $line\.?\n$/,
        'test the appearance of a normal warning',
    );
}

{
    my ($line, $file);
    my $original_handler = $SIG{__WARN__};

    my @warnings = warnings { $original_handler->('a warning with no newline'); $line = __LINE__; $file = __FILE__ };
    like(
        $warnings[0],
        qr/^a warning with no newline at \Q$file\E line $line\.?\n$/,
        'warning has origin properly added when it was lacking',
    );
}

done_testing;
