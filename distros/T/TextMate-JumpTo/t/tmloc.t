use strict;
use warnings;
use Test::More;
use Test::Differences;
use File::Spec;
use HTML::Tiny;

use TextMate::JumpTo qw(tm_location);

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
        expect => "txmt://open?url=file%3a%2f%2f"
          . $h->url_encode( $manifest ),
    },
    {
        name   => 'file, line, col, MANIFEST',
        args   => [ file => 'MANIFEST', line => 10, column => 3 ],
        expect => "txmt://open?column=3&line=10&url=file%3a%2f%2f"
          . $h->url_encode( $manifest ),
    },

);

plan tests => 2 * @cases;

for my $test ( @cases ) {
    my $name = $test->{name};
    my $url = eval { tm_location( @{ $test->{args} } ) };
    if ( my $err = $test->{expect_error} ) {
        like $@, $err, "$name: error OK";
        pass "$name: dummy";
    }
    else {
        ok !$@, "$name: no error OK";
        is $url, $test->{expect}, "$name: result OK";
    }
}
