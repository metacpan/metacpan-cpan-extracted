package minimal_warnings;

use strict;
use warnings;
use Test::More;

sub generate_only_some_warnings {
    my @warning_messages;
    local $SIG{__WARN__} = sub {
        my ($message) = @_;
        push @warning_messages, $message;
    };

    # No warnings thrown for this slightly dodgy code.
    my $foo;
    my $bar = $foo . q{ damn, that was an undef wasn't it?};

    # We do get a warning for this, though.
    my $number = 42;
    my $string = 'Life, the Universe and Everything';
    my $not_number = $number + $string;

    is(scalar @warning_messages, 1, 'Only one warning');
    like(
        $warning_messages[0],
        qr/isn't numeric/,
        'Warning for numeric'
    );
}

1;
