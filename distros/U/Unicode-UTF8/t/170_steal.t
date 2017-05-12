#!perl

use strict;
use warnings;

use Test::More   tests => 8;
use Scalar::Util qw[refaddr];

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                encode_utf8 ]);
}

{
    my %foo;

    # First two tests is for a bug in Perl <= 5.14.2
    # https://rt.perl.org/rt3/Public/Bug/Display.html?id=91844
    # http://perl5.git.perl.org/perl.git/commitdiff/3ed94dc04bd73c95

    $foo{bar} = 'baz';
    for my $x ($foo{bar}) {
        my $r1 = \decode_utf8 sub { delete $foo{bar} }->();
        my $r2 = \$x;
        isnt $r1, $r2, 'result of delete(helem) is copied when returned';
    }

    $foo{bar} = 'baz';
    for my $x ($foo{bar}) {
        my $r1 = \decode_utf8 sub { return delete $foo{bar} }->();
        my $r2 = \$x;
        isnt $r1, $r2, 'result of delete(helem) is copied when explicitly returned'
    }

    SKIP: {
        # http://search.cpan.org/dist/perl-5.17.10/pod/perldelta.pod#Internal_Changes
        # https://metacpan.org/module/DAGOLDEN/perl-5.19.1/pod/perldelta.pod#Internal-Changes
        skip 'New copy-on-write mechanism', 5 if (($] >= 5.017007 && $] <= 5.017009) || $] >= 5.019000);

        $foo{bar} = 'baz';
        {
            my $r1 = refaddr \$foo{bar};
            my $r2 = refaddr \decode_utf8 delete $foo{bar};
            is($r1, $r2, "decode_utf8 delete(helem) (native) is resued");
        }

        $foo{bar} = "Foo \xE2\x98\xBA";
        {
            my $r1 = refaddr \$foo{bar};
            my $r2 = refaddr \decode_utf8 delete $foo{bar};
            is($r1, $r2, "decode_utf8 delete(helem) (UTF-8) is resued");
        }

        utf8::upgrade($foo{bar} = "Foo \xE2\x98\xBA");
        {
            my $r1 = refaddr \$foo{bar};
            my $r2 = refaddr \decode_utf8 delete $foo{bar};
            is($r1, $r2, "decode_utf8 delete(helem) (upgraded UTF-8) is resued");
        }

        $foo{bar} = 'baz';
        {
            my $r1 = refaddr \$foo{bar};
            my $r2 = refaddr \encode_utf8 delete $foo{bar};
            is($r1, $r2, "encode_utf8 delete(helem) (native) is resued");
        }

        $foo{bar} = decode_utf8 "Foo \xE2\x98\xBA";
        {
            my $r1 = refaddr \$foo{bar};
            my $r2 = refaddr \encode_utf8 delete $foo{bar};
            is($r1, $r2, "encode_utf8 delete(helem) (UTF-8) is resued");
        }
    }
}

