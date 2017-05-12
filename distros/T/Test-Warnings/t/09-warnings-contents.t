use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings ':all';

{
    my @lines;
    my @warnings = warnings {
        warn 'testing 1 2 3';   push @lines, __LINE__;
    };

    my $file = __FILE__;
    is_deeply(
        \@warnings,
        [
            "testing 1 2 3 at $file line $lines[0].\n",
        ],
        'warnings() successfully captured the warning',
    );

    my $warning = warning {
        warn 'testing 1 2 3';   push @lines, __LINE__;
    };
    is(
        $warning,
        "testing 1 2 3 at $file line $lines[1].\n",
        'warning() successfully the warning as a string',
    );
}

{
    my @lines;
    my @warnings = warnings {
        warn 'testing 1 2 3';   push @lines, __LINE__;
        warn 'another warning'; push @lines, __LINE__;
    };

    my $file = __FILE__;
    is_deeply(
        \@warnings,
        [
            "testing 1 2 3 at $file line $lines[0].\n",
            "another warning at $file line $lines[1].\n",
        ],
        'warnings() successfully captured all warnings',
    );

    my $warning = warning {
        warn 'testing 1 2 3';   push @lines, __LINE__;
        warn 'another warning'; push @lines, __LINE__;
    };
    is_deeply(
        $warning,
        [
            "testing 1 2 3 at $file line $lines[2].\n",
            "another warning at $file line $lines[3].\n",
        ],
        'warning() successfully captured all warnings as a scalar ref',
    );
}

{
    my @warnings = warnings {
        note 'no warning here';
        note 'nor here';
    };

    is_deeply(
        \@warnings,
        [ ],
        'warnings() successfully captured all warnings (none!)',
    );

    my $warning = warning {
        note 'no warning here';
        note 'nor here';
    };

    is_deeply(
        $warning,
        [ ],
        'warning() successfully captured all warnings (none!)',
    );

    is(@$warning, 0, 'warning() reports zero warnings caught');
}

done_testing;
