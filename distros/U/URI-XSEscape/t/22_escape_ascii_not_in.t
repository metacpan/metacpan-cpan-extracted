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
    my @not_ins = (
        '^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/:-',
        '^a-zA-Z0-9._/:-',
    );
    foreach my $string (@strings) {
        foreach my $not_in (@not_ins) {
            my $escaped = URI::XSEscape::uri_escape($string, $not_in);
            my $wanted = URI::Escape::uri_escape($string, $not_in);
            is($escaped, $wanted,
            "escaping of printable string [$string] not in [$not_in] works");
        }
    }
}

sub test_non_printable {
    my @strings = (
        [ 10, ],
        [ 10, 13, ],
    );
    my @not_ins = (
        '^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/:-',
        '^a-zA-Z0-9._/:-',
    );
    foreach my $chars (@strings) {
        foreach my $not_in (@not_ins) {
            my $string = join('', map { chr($_) } @$chars);
            my $show = join(':', map { $_ } @$chars);
            my $escaped = URI::XSEscape::uri_escape($string, $not_in);
            my $wanted = URI::Escape::uri_escape($string, $not_in);
            is($escaped, $wanted,
               "escaping of non-printable string [$show] not in [$not_in] works");
        }
    }
}
