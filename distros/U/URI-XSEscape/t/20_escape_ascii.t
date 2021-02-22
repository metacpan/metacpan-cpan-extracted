use strict;
use warnings;

use Test::More;

BEGIN { $ENV{'PERL_URI_XSESCAPE'} = 0 }

use URI::Escape;
use URI::XSEscape;

exit main(@ARGV);

sub main {
    test_printable();
    test_non_printable();
    test_numbers();

    done_testing;
    return 0;
}

sub test_printable {
    my @strings = (
        '',
        'hello',
        'gonzo & ale',
        'I said this: you / them ~ us & me _will_ "do-it" NOW!',
        'http://www.google.co.jp/search?q=小飼弾',
    );
    foreach my $string (@strings) {
        my $upgraded = $string;
        utf8::upgrade($upgraded);

        my $escaped = URI::XSEscape::uri_escape($string);
        my $wanted = URI::Escape::uri_escape($string);
        $wanted =~ tr<A-F><a-f>;
        is($escaped, $wanted,
           "escaping of printable string [$string] works");

        my $escaped_upgraded = URI::XSEscape::uri_escape($upgraded);
        is($escaped_upgraded, $escaped,
           "… and upgraded form is escaped the same way");
    }
}

sub test_numbers {
    my @nums = (
        0,
        1,
        0xffff,
        1.2345,
    );

    for my $num (@nums) {
        my $escaped = URI::XSEscape::uri_escape(q<> . $num);
        my $wanted = URI::Escape::uri_escape($num);
        $wanted =~ tr<A-F><a-f>;
        is($escaped, $wanted,
           "escaping of number $num works");
    }
}

sub test_non_printable {
    my @strings = (
        [ 10, ],
        [ 10, 13, ],
        [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
    );
    foreach my $chars (@strings) {
        my $string = join('', map { chr($_) } @$chars);
        my $show = join(':', map { $_ } @$chars);
        my $escaped = URI::XSEscape::uri_escape($string);
        my $wanted = URI::Escape::uri_escape($string);
        $wanted =~ tr<A-F><a-f>;
        is($escaped, $wanted,
           "escaping of non-printable string [$show] works");
    }
}
