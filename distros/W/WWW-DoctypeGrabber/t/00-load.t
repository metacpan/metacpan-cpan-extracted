#!/usr/bin/env perl

use Test::More tests => 12;

BEGIN {
    use_ok('Carp');
    use_ok('LWP::UserAgent');
    use_ok('Class::Accessor::Grouped');
    use_ok('overload');
	use_ok( 'WWW::DoctypeGrabber' );
}

diag( "Testing WWW::DoctypeGrabber $WWW::DoctypeGrabber::VERSION, Perl $], $^X" );

my $o = WWW::DoctypeGrabber->new;
isa_ok($o,'WWW::DoctypeGrabber');
can_ok($o, qw(new grab error result doctype raw));
isa_ok( $o->ua, 'LWP::UserAgent', 'ua()');

SKIP: {
    my $res = $o->grab('http://zoffix.com');
    unless ( $res ) {
        diag "Got error: " . $o->error;
        skip "Got network error", 4;
    }
    my $VAR1 = {
          "doctype" => "HTML 4.01 Strict + url",
          "xml_prolog" => 0,
          "non_white_space" => 0,
          "has_doctype" => 1,
            'mime' => 'text/html; charset=utf-8'
    };
    is_deeply( $o->result, $VAR1, 'return from result()');
    is_deeply( $res, $VAR1, 'return from grab()');
    is( $o->doctype, 'HTML 4.01 Strict + url', 'doctype()');
    is( "$o", 'HTML 4.01 Strict + url', 'overloads');

}
