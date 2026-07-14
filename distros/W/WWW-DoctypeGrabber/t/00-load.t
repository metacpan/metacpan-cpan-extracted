#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 22;
use File::Spec::Functions qw(rel2abs catfile catdir);
use File::Basename qw(dirname);

# Turn a fixture file name into a file:// URI pointing at t/fixtures/<name>.
sub fixture_uri {
    my $name = shift;
    my $fixture_dir = catdir( dirname( rel2abs(__FILE__) ), 'fixtures' );
    my $path = rel2abs( catfile( $fixture_dir, $name ) );
    $path =~ s{\\}{/}g;              # Windows-friendly separators
    $path =~ s{^([A-Za-z]):}{/$1:};  # drive letter -> /C:/...
    return "file://$path";
}

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

# The rest of the tests feed the parser known, static HTML fixtures over the
# file:// protocol so the suite is deterministic and does not depend on any
# external web page (which used to churn and break these tests repeatedly).
SKIP: {
    eval { require LWP::Protocol::file; 1 }
        or skip "LWP::Protocol::file not available", 14;

    # HTML5 doctype
    is_deeply(
        $o->grab( fixture_uri('html5.html') ),
        {
            doctype         => '<!DOCTYPE html>',
            has_doctype     => 1,
            mime            => 'text/html',
            non_white_space => 0,
            xml_prolog      => 0,
        },
        'HTML5 doctype: grab() result',
    );
    is( $o->doctype, '<!DOCTYPE html>', 'HTML5 doctype: doctype()' );

    # HTML 4.01 Strict with matching DTD url
    is_deeply(
        $o->grab( fixture_uri('html401strict.html') ),
        {
            doctype         => 'HTML 4.01 Strict + url',
            has_doctype     => 1,
            mime            => 'text/html',
            non_white_space => 0,
            xml_prolog      => 0,
        },
        'HTML 4.01 Strict: grab() result',
    );
    is( $o->doctype, 'HTML 4.01 Strict + url', 'HTML 4.01 Strict: doctype()' );
    is( "$o", 'HTML 4.01 Strict + url', 'HTML 4.01 Strict: overloaded stringification' );

    # HTML 4.01 Transitional with matching DTD url
    is_deeply(
        $o->grab( fixture_uri('html401trans.html') ),
        {
            doctype         => 'HTML 4.01 Transitional + url',
            has_doctype     => 1,
            mime            => 'text/html',
            non_white_space => 0,
            xml_prolog      => 0,
        },
        'HTML 4.01 Transitional: grab() result',
    );
    is( $o->doctype, 'HTML 4.01 Transitional + url',
        'HTML 4.01 Transitional: doctype()' );

    # XHTML 1.0 Strict with matching DTD url and an XML prolog
    is_deeply(
        $o->grab( fixture_uri('xhtml10strict.html') ),
        {
            doctype         => 'XHTML 1.0 Strict + url',
            has_doctype     => 1,
            mime            => 'text/html',
            non_white_space => 0,
            xml_prolog      => 1,
        },
        'XHTML 1.0 Strict: grab() result',
    );
    is( $o->doctype, 'XHTML 1.0 Strict + url + 1 XML prolog',
        'XHTML 1.0 Strict: doctype() reports the XML prolog' );

    # No doctype at all
    is_deeply(
        $o->grab( fixture_uri('nodoctype.html') ),
        {
            doctype         => '',
            has_doctype     => 0,
            mime            => 'text/html',
            non_white_space => 0,
            xml_prolog      => 0,
        },
        'No doctype: grab() result',
    );
    is( $o->doctype, 'NO DOCTYPE', 'No doctype: doctype()' );
    is( "$o", 'NO DOCTYPE', 'No doctype: overloaded stringification' );

    # result() returns the same ref as the last grab()
    my $last = $o->grab( fixture_uri('nodoctype.html') );
    is_deeply( $o->result, $last, 'result() matches last grab()' );

    # raw mode returns the doctype string verbatim
    my $raw = WWW::DoctypeGrabber->new( raw => 1 );
    is( $raw->grab( fixture_uri('html401strict.html') ),
        '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" '
            . '"http://www.w3.org/TR/html4/strict.dtd">',
        'raw mode returns verbatim doctype' );
}
