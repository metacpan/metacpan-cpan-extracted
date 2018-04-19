#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Test::Pod::Links;

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::HTTP::NoUA;

main();

sub main {

    my $class = 'Test::Pod::Links';

    {
        my $obj = $class->new();
        isa_ok( $obj, $class, "new() returns a $class object" );

        ok( exists $obj->{_cache}, '_cache attribute exists' );
        is( ref $obj->{_cache}, ref {}, '... and is initialized to a hash ref' );
        is( scalar keys %{ $obj->{_cache} }, 0, '... without any entries' );

        ok( exists $obj->{_ua}, '_ua attribute exists' );
        isa_ok( $obj->{_ua}, 'HTTP::Tiny', '... which isa HTTP::Tiny object' );

        like( exception { $class->new( ua => 'hello world' ) }, q{/ua must have method 'head'/}, q{new throws an exception if 'ua' argument has no method head} );

        ok( exists $obj->{_ignore_regex}, '_ignore_regex attribute exists' );
        is( $obj->{_ignore_regex}, undef, '... and is initialized to undef' );
    }

    {
        my $ua = bless {}, 'Local::HTTP::NoUA';
        my $obj = $class->new( ua => $ua );

        isa_ok( $obj, $class, "new( ua => ...)) returns a $class object" );
        isa_ok( $obj->_ua, 'Local::HTTP::NoUA', '... and configures the ua' );
    }

    # single link as scalar
    {
        my $obj = $class->new( ignore => 'link' );

        isa_ok( $obj, $class, "new( ignore => 'link')) returns a $class object" );
        my $re = qr{^\Qlink\E$};
        $re = "$re";
        is( $obj->_ignore_regex, qr{$re}, '... and _ignore_regex is correct' );

        ok( 'link' =~ $obj->_ignore_regex,  q{... matches 'link'} );
        ok( 'link2' !~ $obj->_ignore_regex, q{... does not match 'link2'} );
    }

    # single link as array ref
    {
        my $obj = $class->new( ignore => ['link'] );

        isa_ok( $obj, $class, "new( ignore => [ 'link' ] )) returns a $class object" );
        my $re = qr{^\Qlink\E$};
        $re = "$re";
        is( $obj->_ignore_regex, qr{$re}, '... and _ignore_regex is correct' );

        ok( 'link' =~ $obj->_ignore_regex,  q{... matches 'link'} );
        ok( 'link2' !~ $obj->_ignore_regex, q{... does not match 'link2'} );
    }

    # two link
    {
        my $obj = $class->new( ignore => [ 'link', 'link2' ] );

        isa_ok( $obj, $class, "new( ignore => [ 'link', 'link2' ] )) returns a $class object" );
        my $link  = qr{^\Qlink\E$};
        my $link2 = qr{^\Qlink2\E$};
        my $re    = qr{$link|$link2};
        is( $obj->_ignore_regex, $re, '... and _ignore_regex is correct' );

        ok( 'link' =~ $obj->_ignore_regex,  q{... matches 'link'} );
        ok( 'link2' =~ $obj->_ignore_regex, q{... matches 'link2'} );
        ok( 'link3' !~ $obj->_ignore_regex, q{... does not match 'link3'} );
    }

    # single regex as scalar
    {
        my $obj = $class->new( ignore_match => 'l[iI].k' );

        isa_ok( $obj, $class, "new( ignore_match => 'l[iI].k') returns a $class object" );
        is( $obj->_ignore_regex, qr{l[iI].k}, '... and _ignore_regex is correct' );

        ok( 'link' =~ $obj->_ignore_regex,  q{... matches 'link'} );
        ok( 'lInk' =~ $obj->_ignore_regex,  q{... matches 'lInk'} );
        ok( 'link2' =~ $obj->_ignore_regex, q{... matches 'link2'} );
        ok( 'LINK' !~ $obj->_ignore_regex,  q{... does not match LINK'} );
    }

    # single regex as scalar
    {
        my $obj = $class->new( ignore_match => qr{l[iI].k} );

        isa_ok( $obj, $class, "new( ignore_match => qr{l[iI].k}) returns a $class object" );
        my $re = qr{l[iI].k};
        $re = "$re";
        is( $obj->_ignore_regex, qr{$re}, '... and _ignore_regex is correct' );

        ok( 'link' =~ $obj->_ignore_regex,  q{... matches 'link'} );
        ok( 'lInk' =~ $obj->_ignore_regex,  q{... matches 'lInk'} );
        ok( 'link2' =~ $obj->_ignore_regex, q{... matches 'link2'} );
        ok( 'LINK' !~ $obj->_ignore_regex,  q{... does not match LINK'} );
    }

    # single regex as array ref
    {
        my $obj = $class->new( ignore_match => ['l[iI].k'] );

        isa_ok( $obj, $class, "new( ignore_match => [ 'l[iI].k' ]) returns a $class object" );
        is( $obj->_ignore_regex, qr{l[iI].k}, '... and _ignore_regex is correct' );

        ok( 'link' =~ $obj->_ignore_regex,  q{... matches 'link'} );
        ok( 'lInk' =~ $obj->_ignore_regex,  q{... matches 'lInk'} );
        ok( 'link2' =~ $obj->_ignore_regex, q{... matches 'link2'} );
        ok( 'LINK' !~ $obj->_ignore_regex,  q{... does not match LINK'} );
        ok( 'li_nk' !~ $obj->_ignore_regex, q{... does not match li_nk'} );
    }

    # two regex
    {
        my $obj = $class->new( ignore_match => [ 'l[iI].k', qr{^li_nk$} ] );

        isa_ok( $obj, $class, "new( ignore_match => [ 'l[iI].k', qr{^li_nk\$} ]) returns a $class object" );
        my $re1 = 'l[iI].k';
        my $re2 = qr{^li_nk$};
        is( $obj->_ignore_regex, qr{$re1|$re2}, '... and _ignore_regex is correct' );

        ok( 'link' =~ $obj->_ignore_regex,  q{... matches 'link'} );
        ok( 'lInk' =~ $obj->_ignore_regex,  q{... matches 'lInk'} );
        ok( 'link2' =~ $obj->_ignore_regex, q{... matches 'link2'} );
        ok( 'LINK' !~ $obj->_ignore_regex,  q{... does not match LINK'} );
        ok( 'li_nk' =~ $obj->_ignore_regex, q{... matches li_nk'} );
    }

    # ignore and ignore_match
    {
        my $obj = $class->new( ignore => 'link', ignore_match => ['LINK$'] );

        isa_ok( $obj, $class, "new( ignore => [ 'l[iI].k', qr{^li_nk\$} ]) returns a $class object" );
        my $link  = 'LINK$';
        my $link2 = qr{^link$};
        is( $obj->_ignore_regex, qr{$link|$link2}, '... and _ignore_regex is correct' );

        ok( 'link' =~ $obj->_ignore_regex,    q{... matches 'link'} );
        ok( 'lInk' !~ $obj->_ignore_regex,    q{... does not match 'lInk'} );
        ok( 'link2' !~ $obj->_ignore_regex,   q{... does not match 'link2'} );
        ok( 'LINK' =~ $obj->_ignore_regex,    q{... matches LINK'} );
        ok( 'abcLINK' =~ $obj->_ignore_regex, q{... matches abcLINK'} );
        ok( 'LINKabc' !~ $obj->_ignore_regex, q{... does not match LINKabc'} );
    }

    #
    {
        like( exception { $class->new( 1, 2, 3 ) }, qr{Odd number of arguments}, 'throws an exception on even number of arguments' );

        my $ua = bless {}, 'Local::HTTP::NoUA';
        like( exception { $class->new( ua => $ua, ignore => 'link', no_such_argument => 12, ignore_match => [ 'L.*NK', 'ABC' ] ) }, qr{new[(][)] knows nothing about argument 'no_such_argument'}, 'throws an exception on unknown argument' );
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
