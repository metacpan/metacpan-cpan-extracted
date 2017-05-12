use strict;
use warnings;

use Test::More;
use URI::Escape;
use URI::XSEscape;

exit main(@ARGV);

sub main {
    test_printable();
    test_non_printable();

    done_testing;
    return 0;
}

sub test_printable {
    my @strings = (
        '',
        'hello',
        'gonzo & ale',
        'I said this: you / them ~ us & me _will_ "do-it" NOW!',
        # 'http://www.google.co.jp/search?q=小飼弾',  ## This will fail, it is UTF8
    );
    foreach my $string (@strings) {
        my $escaped = URI::XSEscape::uri_escape($string);
        my $wanted = URI::Escape::uri_escape($string);
        is($escaped, $wanted,
           "escaping of printable string [$string] works");
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
        is($escaped, $wanted,
           "escaping of non-printable string [$show] works");
    }
}
