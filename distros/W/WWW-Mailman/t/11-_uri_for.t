use warnings;
use strict;
use Test::More;

use WWW::Mailman;

$WWW::Mailman::VERSION ||= 'undefined';

my @base = (
    'http://lists.example.com/mailman',
    'https://lists.example.com/mailman',
    'http://lists.example.com/prefix/mailman',
);
my @tests = (
    [ '!base/listinfo/!list', 'listinfo' ],
    [ '!base/options/!list', 'options' ],
    [ '!base/admin/!list/privacy/sender', 'admin', 'privacy', 'sender' ],
    [ '!base/admindb/!list', 'admindb' ],
);

plan tests => @base * @tests;

for my $base (@base) {

    # create the base object
    my $m = WWW::Mailman->new();
    $m->uri("$base/listinfo/example");

    # try a number of actions
    for my $test (@tests) {
        my ( $uri, @args ) = @$test;
        $uri =~ s/!base/$base/;
        $uri =~ s/!list/example/;
        is( $m->_uri_for(@args), $uri, $uri );
    }
}
