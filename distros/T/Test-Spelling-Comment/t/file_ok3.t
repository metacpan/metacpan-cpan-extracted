#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::More 0.88;
use Test::TempDir::Tiny;

use File::Spec;

package Test::Spelling::Comment;
use subs qw(close);

package main;

use Test::Spelling::Comment 0.003;

main();

sub main {
    my $class = 'Test::Spelling::Comment';

    *Test::Spelling::Comment::close = sub { return };

    my $obj = $class->new;

    my $tmp  = tempdir();
    my $file = File::Spec->catfile( $tmp, 'file.pm' );

    _touch($file);

    #
    test_out("not ok 1 - $file");
    test_fail(+3);
    test_diag(q{});
    test_err(qr{[#]\s+\QCannot read file '$file': \E.*\n?});
    my $rc = $obj->file_ok($file);
    test_test('file_ok fails if file cannot be read');

    is( $rc, undef, '... returns undef' );

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

sub _touch {
    my ( $file, @content ) = @_;

    if ( open my $fh, '>', $file ) {
        if ( print {$fh} @content ) {
            return if close $fh;
        }
    }

    BAIL_OUT("Cannot write file '$file': $!");
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
