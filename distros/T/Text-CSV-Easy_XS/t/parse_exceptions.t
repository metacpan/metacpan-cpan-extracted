#!perl
use strict;
use warnings FATAL => 'all';
use 5.010;

use Test::More;

use Text::CSV::Easy_XS qw(csv_parse);

test_exceptions(
    q{1,ab"c}      => qr/quote found in middle of the field: ab"c/,
    q{1, "bad"}    => qr/quote found in middle of the field:  "bad"/,
    q{1,"}         => qr/unterminated string: 1,"/,
    qq{abc,de\nfg} => qr/newline found in unquoted string: de\nfg/,
    q{"ab"cd,2}    => qr/invalid field: "ab"cd,2/,
);

done_testing();

sub test_exceptions {
    my @tests = @_;    # array instead of hash to maintain order

    for ( my $i = 0 ; $i < @tests ; $i += 2 ) {
        my ( $csv, $qr ) = @tests[ $i, $i + 1 ];
        my $csv_clean = _clean($csv);

        eval { csv_parse($csv) };
        like( $@, $qr, "$csv_clean raised exception" );
    }
}

sub _clean {
    my $str = shift;
    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;
    return $str;
}
