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
        'gonzo % ale',
        'gonzo &% ale',
        'I said this: you / them ~ us & me _will_ "do-it" NOW!',
    );
    my @ins = (
        '&',
        '%',
        ': /"',
        '0-9-',
        '^a-zA-Z0-9._/:-',
    );
    foreach my $string (@strings) {
        foreach my $in (@ins) {
            my $escaped = URI::XSEscape::uri_escape($string, $in);
            my $wanted = URI::Escape::uri_escape($string, $in);
            is($escaped, $wanted,
            "escaping of printable string [$string] in [$in] works");
        }
    }
}

sub test_non_printable {
    my @strings = (
        [ 10, ],
        [ 10, 13, ],
    );
    my @ins = (
        '&',
        '%',
        ': /"',
        # '^a-zA-Z0-9._/:-',
    );
    foreach my $chars (@strings) {
        foreach my $in (@ins) {
            my $string = join('', map { chr($_) } @$chars);
            my $show = join(':', map { $_ } @$chars);
            my $escaped = URI::XSEscape::uri_escape($string, $in);
            my $wanted = URI::Escape::uri_escape($string, $in);
            is($escaped, $wanted,
               "escaping of non-printable string [$show] in [$in] works");
        }
    }
}
