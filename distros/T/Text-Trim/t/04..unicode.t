use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('Text::Trim') }

SKIP: {
    eval { require Encode };
    if ($@) {
        skip("Unicode tests require Encode.pm (core with 5.7.3 and later)", 3);
    }
    import Encode qw( decode :fallbacks );

    # unicode non-breaking space;
    my $nbsp = "\xc2\xa0";

    my $text = my $orig = decode('UTF-8', "$nbsp$nbsp\tFoo Bar Baz$nbsp\t\r\n", FB_WARN());
    my $expected = 'Foo Bar Baz';

    is(trim($text), $expected, 'trim with unicode whitespace works');
    is($text,       $orig,     'original string unaffected');
    trim($text);
    is($text,       $expected, 'works in void context too');
}


__END__

vim: ft=perl ts=8 sts=4 sw=4 sr et
