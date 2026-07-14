#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 19;
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
        skip "Got error", 9;
    }

    # The paste body is fetched verbatim from pastebin.com/raw/<id> and must
    # match byte-for-byte. name/lang are still scraped from the paste page;
    # posted_on is checked loosely since pastebin.com's date format has
    # changed over the years (it now renders e.g. "Mar 22nd, 2008").
    is( $o_ref->{content}, _expected_content(),
        'content matches the raw paste body exactly'
    );
    is( $o_ref->{name}, 'Zoffix', 'name() metadata scraped from page' );
    is( $o_ref->{lang}, 'Perl',   'lang() metadata scraped from page' );
    like( $o_ref->{posted_on}, qr/2008/,
        'posted_on() references the correct year'
    );

    isa_ok($o->uri, 'URI::http', '->uri() is a URI object');
    is( $o->uri, $URI, '->uri() must have uri to paste');
    is( $o->content, $o_ref->{content}, 'content ()');
    is( "$o", $o->content, 'overloads');
    is( $o->id, $ID, 'id() must return paste ID');
    is_deeply( $o->results, $o_ref, 'results()');
}


sub _expected_content {
    return "sub error {\r\n    my \$self = shift;\r\n    if ( \@_ ) {\r\n        \$self->{ ERROR } = shift;\r\n    }\r\n    return \$self->{ ERROR };\r\n}\r\n\r\nsub content {\r\n    my \$self = shift;\r\n    if ( \@_ ) {\r\n        \$self->{ CONTENT } = shift;\r\n    }\r\n    return \$self->{ CONTENT };\r\n}";
}