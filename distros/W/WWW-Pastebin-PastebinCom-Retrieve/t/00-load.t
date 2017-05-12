#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 16;
my $ID = 'f525c4cec';
my $URI = 'http://pastebin.com/f525c4cec';

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('HTML::TokeParser::Simple');
    use_ok('HTML::Entities');
    use_ok('WWW::Pastebin::Base::Retrieve');
	use_ok( 'WWW::Pastebin::PastebinCom::Retrieve' );
}

diag( "Testing WWW::Pastebin::PastebinCom::Retrieve $WWW::Pastebin::PastebinCom::Retrieve::VERSION, Perl $], $^X" );

my $o = WWW::Pastebin::PastebinCom::Retrieve->new(timeout=>10);

isa_ok($o,'WWW::Pastebin::PastebinCom::Retrieve');
can_ok($o, qw(retrieve new _parse uri ua id content results));
isa_ok( $o->ua, 'LWP::UserAgent');

my $o_ref = $o->retrieve($URI);
SKIP: {
    unless ( defined $o_ref ) {
        diag "Got retrieve error: " . $o->error;
        ok( (defined $o->error and length $o->error), 'error got a message');
        skip "Got error", 6;
    }

    is_deeply( $o_ref, _make_dump(),
        'return from retrieve() matches the dump'
    );

    isa_ok($o->uri, 'URI::http', '->uri() is a URI object');
    is( $o->uri, $URI, '->uri() must have uri to paste');
    is( $o->content, $o_ref->{content}, 'content ()');
    is( "$o", $o->content, 'overloads');
    is( $o->id, $ID, 'id() must return paste ID');
    is_deeply( $o->results, $o_ref, 'results()');
}


sub _make_dump {
    return {
          "lang" => "Perl",
          "posted_on" => "Sat 22 Mar 16:07",
          "content" => "sub error {\r\n    my \$self = shift;\r\n    if ( \@_ ) {\r\n        \$self->{ ERROR } = shift;\r\n    }\r\n    return \$self->{ ERROR };\r\n}\r\n\r\nsub content {\r\n    my \$self = shift;\r\n    if ( \@_ ) {\r\n        \$self->{ CONTENT } = shift;\r\n    }\r\n    return \$self->{ CONTENT };\r\n}",
          "name" => "Zoffix"
        };
}