use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;

use Validator::LIVR;

# "$" matches only at the end of the value
sub check_like {
    my ( $rule, %values ) = @_;
    my $validator = Validator::LIVR->new({ field => { like => $rule } });

    for my $value ( sort keys %values ) {
        $validator->validate({ field => $value });
        my $got = $validator->get_errors && $validator->get_errors->{field};

        ( my $name = $value ) =~ s/\n/\\n/g;
        my $pattern = ref $rule ? join( ', ', @$rule ) : $rule;
        is( $got, $values{$value} ? undef : 'WRONG_FORMAT',
            ( $values{$value} ? 'Should accept ' : 'Should reject ' ) . "$name for $pattern" );
    }
}

check_like( '^[0-9]{5}$',
    '12345'           => 1,
    "12345\n"         => 0,
    "12345\n<script>" => 0,
    "<script>\n12345" => 0,
);

check_like( [ '^[a-z]+$', 'i' ],
    'Perl'   => 1,
    "Perl\n" => 0,
);

check_like( '^\$[0-9]+$',
    '$10'   => 1,
    "\$10\n" => 0,
);

check_like( '^[$^]+$',
    '$^$' => 1,
    'a'   => 0,
);

check_like( '^[]$]+$',
    ']$' => 1,
);

check_like( '^[[:alpha:]$]+$',
    'ab$' => 1,
    "ab\n" => 0,
);

check_like( '[0-9]+',
    "abc\n123" => 1,
);

done_testing;
