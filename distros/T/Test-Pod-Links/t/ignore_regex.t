#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2018-2026 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Test::Pod::Links;

main();

sub main {
    my $class = 'Test::Pod::Links';

    my $obj = $class->new();

    ok( exists $obj->{_ignore_regex}, '_ignore_regex attribute exists' );
    is( $obj->{_ignore_regex}, undef, '... and is initialized to undef' );
    is( $obj->_ignore_regex,   undef, '... and the accessor can read the attribute' );

    is( $obj->_ignore_regex('hello world'), 'hello world', '... and write to it' );
    is( $obj->{_ignore_regex},              'hello world', '... attribute is updated' );

    is( $obj->_ignore_regex( 1, 2, 3 ), 1, '_ignore_regex silently ignores superfluous arguments' );

    done_testing();

    exit 0;
}
