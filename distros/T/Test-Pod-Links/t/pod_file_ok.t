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

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use Test::Pod::Links;

use File::Temp;
use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::HTTP::HeadOnly;
use Local::HTTP::Tiny::Mock;

main();

sub main {
    my $class = 'Test::Pod::Links';

    {
        my $obj = $class->new;

        #
        like( exception { $obj->pod_file_ok() },                 qr{usage: pod_file_ok[(]FILE[)]}, 'pod_file_ok() throws an exception with too few arguments' );
        like( exception { $obj->pod_file_ok(undef) },            qr{usage: pod_file_ok[(]FILE[)]}, '... undef for a file name' );
        like( exception { $obj->pod_file_ok( 'file', 'name' ) }, qr{usage: pod_file_ok[(]FILE[)]}, '... too many arguments' );

        #
        my $tmp               = File::Temp->newdir;
        my $non_existing_file = "$tmp/no_such_file";

        #
        test_out("not ok 1 - Parse Pod ($non_existing_file)");
        test_fail(+3);
        test_diag(q{});
        test_diag("File $non_existing_file does not exist or is not a file");
        my $rc = $obj->pod_file_ok($non_existing_file);
        test_test('pod_file_ok fails on a non-existing file');

        is( $rc, undef, '... returns undef' );
    }

    {
        my $file = 'corpus/malformed.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new( ua => $ua );

        test_out("not ok 1 - Parse Pod ($file)");
        test_fail(+1);
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (malformed pod)');

        is( $rc, undef, '... returns undef' );
        is_deeply( [ $ua->history ], [], '... there were no head requests to the UA' );
    }

    {
        my $file = 'corpus/0_links.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new( ua => $ua );

        test_out("ok 1 - Parse Pod ($file)");
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with no links)');

        is( $rc, 1, '... returns 1' );
        is_deeply( [ $ua->history ], [], '... there were no head requests to the UA' );
    }

    {
        my $file = 'corpus/1_link_non_web.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new( ua => $ua );

        test_out("ok 1 - Parse Pod ($file)");
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with no web links)');

        is( $rc, 1, '... returns 1' );
        is_deeply( [ $ua->history ], [], '... there were no head requests to the UA' );
    }

    {
        my $file = 'corpus/1_link_web.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new( ua => $ua );

        test_out("ok 1 - Parse Pod ($file)");
        test_out("ok 2 - https://www.perl.com/ ($file)");
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with one web link)');

        is( $rc, 1, '... returns 1' );
        is_deeply( [ $ua->history ], [ sort qw(https://www.perl.com/) ], '... there was one head request to the UA' );
    }

    {
        my $file = 'corpus/7_links_4_web.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new( ua => $ua );

        test_out("ok 1 - Parse Pod ($file)");
        test_out("ok 2 - https://www.perl.com/ ($file)");
        test_out("ok 3 - https://www.cpan.org/ ($file)");
        test_out("ok 4 - https://metacpan.org/ ($file)");
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with three links (four web links. one duplicate))');

        is( $rc, 1, '... returns 1' );
        is_deeply( [ $ua->history ], [qw(https://www.perl.com/ https://www.cpan.org/ https://metacpan.org/)], '... there were two head requests to the UA' );

        # test "another" file with the same Test::Pod::Links object
        # there should be no further requests to the UA because of the cache
        test_out("ok 1 - Parse Pod ($file)");
        test_out("ok 2 - https://www.perl.com/ ($file)");
        test_out("ok 3 - https://www.cpan.org/ ($file)");
        test_out("ok 4 - https://metacpan.org/ ($file)");
        $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with three links (four web links. one duplicate))');

        is( $rc, 1, '... returns 1' );
        is_deeply( [ $ua->history ], [qw(https://www.perl.com/ https://www.cpan.org/ https://metacpan.org/)], '... there were two head requests to the UA' );
    }

    {
        my $file = 'corpus/3_links_1_dead.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new( ua => $ua );

        test_out("ok 1 - Parse Pod ($file)");
        test_out("ok 2 - https://www.perl.com/ ($file)");
        test_out("not ok 3 - http://192.0.2.7/ ($file)");
        test_out("ok 4 - https://metacpan.org/ ($file)");
        test_fail(+4);
        test_diag(q{});
        test_diag('Internal Exception');
        test_diag(q{});
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with three links (one dead))');

        is( $rc, undef, '... returns undef' );
        is_deeply( [ $ua->history ],     [qw(https://www.perl.com/ http://192.0.2.7/ https://metacpan.org/)], '... there were three head requests to the UA' );
        is_deeply( [ $ua->get_history ], [],                                                                  '... and no get request because the head request ran into an internal error' );
    }

    {
        my $file = 'corpus/5_links_1_dead.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new( ua => $ua );

        test_out("ok 1 - Parse Pod ($file)");
        test_out("not ok 2 - http://192.0.2.7/ ($file)");
        test_out("ok 3 - http://cpanmin.us/ ($file)");
        test_out("ok 4 - https://metacpan.org/ ($file)");
        test_out("ok 5 - https://www.cpan.org/ ($file)");
        test_out("ok 6 - https://www.perl.com/ ($file)");
        test_fail(+4);
        test_diag(q{});
        test_diag('Internal Exception');
        test_diag(q{});
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with five links (one dead))');

        is( $rc, undef, '... returns undef' );
        is_deeply(
            [ $ua->history ],
            [
                qw(
                  http://192.0.2.7/
                  http://cpanmin.us/
                  https://metacpan.org/
                  https://www.cpan.org/
                  https://www.perl.com/
                ),
            ],
            '... there were five head requests to the UA',
        );
    }

    {
        my $file = 'corpus/5_links_1_dead.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new(
            ua     => $ua,
            ignore => 'http://192.0.2.7/',
        );

        test_out("ok 1 - Parse Pod ($file)");
        test_out("ok 2 - http://cpanmin.us/ ($file)");
        test_out("ok 3 - https://metacpan.org/ ($file)");
        test_out("ok 4 - https://www.cpan.org/ ($file)");
        test_out("ok 5 - https://www.perl.com/ ($file)");
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with five links (one dead) / dead link ignored)');

        is( $rc, 1, '... returns 1' );
        is_deeply(
            [ $ua->history ],
            [
                qw(
                  http://cpanmin.us/
                  https://metacpan.org/
                  https://www.cpan.org/
                  https://www.perl.com/
                ),
            ],
            '... there were four head requests to the UA',
        );
    }

    {
        my $file = 'corpus/5_links_1_dead.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new(
            ua           => $ua,
            ignore_match => qr{ ^ HTTP \Q://\E }xsi,
        );

        test_out("ok 1 - Parse Pod ($file)");
        test_out("ok 2 - https://metacpan.org/ ($file)");
        test_out("ok 3 - https://www.cpan.org/ ($file)");
        test_out("ok 4 - https://www.perl.com/ ($file)");
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with five links (one dead) / dead link ignored)');

        is( $rc, 1, '... returns 1' );
        is_deeply(
            [ $ua->history ],
            [
                qw(
                  https://metacpan.org/
                  https://www.cpan.org/
                  https://www.perl.com/
                ),
            ],
            '... there were three head requests to the UA',
        );
    }

    {
        my $file = 'corpus/5_links_1_dead.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new(
            ua           => $ua,
            ignore       => 'http://192.0.2.7/',
            ignore_match => '^http(?:s)?://[^/]*cpan[.]',
        );

        test_out("ok 1 - Parse Pod ($file)");
        test_out("ok 2 - http://cpanmin.us/ ($file)");
        test_out("ok 3 - https://www.perl.com/ ($file)");
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with five links (one dead) / dead link ignored)');

        is( $rc, 1, '... returns 1' );
        is_deeply(
            [ $ua->history ],
            [
                qw(
                  http://cpanmin.us/
                  https://www.perl.com/
                ),
            ],
            '... there were two head requests to the UA',
        );
    }

    {
        my $file = 'corpus/2_links_head_not_allowed.pod';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new( ua => $ua );

        test_out("ok 1 - Parse Pod ($file)");
        test_out("ok 2 - https://news.ycombinator.com/ ($file)");
        test_out("not ok 3 - https://www.example.net/not_found ($file)");
        test_fail(+4);
        test_diag(q{});
        test_diag('Not Found');
        test_diag(q{});
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (pod file with two links whose server does not answer head requests)');

        is( $rc, undef, '... returns undef' );
        is_deeply(
            [ $ua->history ],
            [
                qw(
                  https://news.ycombinator.com/
                  https://www.example.net/not_found
                ),
            ],
            '... there were two head requests to the UA',
        );
        is_deeply(
            [ $ua->get_history ],
            [
                qw(
                  https://news.ycombinator.com/
                  https://www.example.net/not_found
                ),
            ],
            '... and both were retried with a get request',
        );
    }

    {
        my $file = 'corpus/1_link_web.pod';

        my $obj = $class->new( ua => Local::HTTP::HeadOnly->new() );

        test_out("ok 1 - Parse Pod ($file)");
        test_out("not ok 2 - https://www.perl.com/ ($file)");
        test_fail(+4);
        test_diag(q{});
        test_diag('Not Allowed');
        test_diag(q{});
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (a ua without a get method is not retried)');

        is( $rc, undef, '... returns undef' );
    }

    {
        my $file = 'corpus/hello';

        my $ua  = Local::HTTP::Tiny::Mock->new();
        my $obj = $class->new( ua => $ua );

        test_out("ok 1 - Parse Pod ($file)");
        my $rc = $obj->pod_file_ok($file);
        test_test('pod_file_ok (perl file without pod)');

        is( $rc, 1, '... returns 1' );
        is_deeply( [ $ua->history ], [], '... there were no head requests to the UA' );
    }

    #
    done_testing();

    exit 0;
}
