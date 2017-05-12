use strict;
use warnings;
use Test::More;
use Test::Differences;
use File::Spec;
use HTML::Tiny;

use TextMate::JumpTo qw(jumpto);

my $manifest = File::Spec->rel2abs( 'MANIFEST' );
my $h        = HTML::Tiny->new;

my @cases = (
    {
        name         => 'empty args',
        args         => [],
        expect_error => qr{one\s+or\s+more},
    },
    {
        name         => 'odd args',
        args         => ['file'],
        expect_error => qr{needs\s+a\s+list},
    },
    {
        name   => 'file only, MANIFEST',
        args   => [ file => 'MANIFEST' ],
        expect => [
            [
                "txmt://open?url=file%3a%2f%2f"
                  . $h->url_encode( $manifest ),
                undef
            ]
        ],
    },
    {
        name   => 'background MANIFEST',
        args   => [ file => 'MANIFEST', bg => 1 ],
        expect => [
            [
                "txmt://open?url=file%3a%2f%2f"
                  . $h->url_encode( $manifest ),
                1
            ]
        ],
    },
    {
        name   => 'file, line, col, MANIFEST',
        args   => [ file => 'MANIFEST', line => 10, column => 3 ],
        expect => [
            [
                "txmt://open?column=3&line=10&url=file%3a%2f%2f"
                  . $h->url_encode( $manifest ),
                undef
            ]
        ],
    },

);

plan tests => 2 * @cases;

{
    my @log = ();

    no warnings 'redefine';
    *TextMate::JumpTo::_open = sub { push @log, [@_] };

    sub get_log { splice @log }
}

for my $test ( @cases ) {
    my $name = $test->{name};
    eval { jumpto( @{ $test->{args} } ) };
    if ( my $err = $test->{expect_error} ) {
        like $@, $err, "$name: error OK";
        pass "$name: dummy";
    }
    else {
        ok !$@, "$name: no error OK";
        eq_or_diff [ get_log() ], $test->{expect}, "$name: result OK";
    }
}
