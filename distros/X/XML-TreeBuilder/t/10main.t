#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More tests => 8;

BEGIN {
    use_ok('XML::TreeBuilder');
}

my $x = XML::TreeBuilder->new;
$x->store_comments(1);
$x->store_pis(1);
$x->store_declarations(1);
$x->parse(qq{<!-- myorp --><Gee><foo Id="me" xml:foo="lal">Hello World</foo>}
        . qq{<lor/><!-- foo --></Gee><!-- glarg -->} );

my $y = XML::Element->new_from_lol(
    [   'Gee',
        [ '~comment', { 'text' => ' myorp ' } ],
        [ 'foo', { 'Id' => 'me', 'xml:foo' => 'lal' }, 'Hello World' ],
        ['lor'],
        [ '~comment', { 'text' => ' foo ' } ],
        [ '~comment', { 'text' => ' glarg ' } ],
    ]
);

ok( $x->same_as($y), "same as" );

unless ( $ENV{'HARNESS_ACTIVE'} ) {
    $x->dump;
    $y->dump;
}

#print "\n", $x->as_Lisp_form, "\n";
#print "\n", $x->as_XML, "\n\n";
#print "\n", $y->as_XML, "\n\n";
$x->delete;
$y->delete;

$x = XML::TreeBuilder->new( { NoExpand => 1, ErrorContext => 2 } );
$x->store_comments(1);
$x->store_pis(1);
$x->store_declarations(1);
$x->parse(qq{<!-- myorp --><Gee><foo Id="me" xml:foo="lal">Hello World</foo>}
        . qq{<lor/><!-- foo --></Gee><!-- glarg -->} );

$y = XML::Element->new_from_lol(
    [   'Gee',
        [ '~comment', { 'text' => ' myorp ' } ],
        [ 'foo', { 'Id' => 'me', 'xml:foo' => 'lal' }, 'Hello World' ],
        ['lor'],
        [ '~comment', { 'text' => ' foo ' } ],
        [ '~comment', { 'text' => ' glarg ' } ],
    ]
);

ok( $x->same_as($y), "same as" );

my $z = XML::TreeBuilder->new( { NoExpand => 1, ErrorContext => 2 } );
$z->store_cdata(1);
$z->parsefile("t/parse_test.xml");
is(
    $z->as_XML(),
    q{<p id="&id;">Here &amp;foo; There
<![CDATA[
&foo;
]]>
&foo;
</p>
},
    'Decoded ampersand and cdata'
);
$z->delete_ignorable_whitespace();

my $za = XML::TreeBuilder->new( { NoExpand => 1, ErrorContext => 2 } );
$za->store_declarations(1);
$za->store_pis(1);
$za->store_declarations(1);
$za->parse(
    qq{<?xml version='1.0' encoding='utf-8' ?>
<!DOCTYPE para PUBLIC "-//OASIS//DTD DocBook XML V4.5//EN" "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" [
<!ENTITY ent_name "ent_value">
]>
<para>Here &amp;foo; There</para>
}
);

## BUGBUG isn't this backwards and the DOCTYPE should be before the 'para' tag?
like(
    $za->as_XML(),
    qr{<para><!DOCTYPE para http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd -//OASIS//DTD DocBook XML V4.5//EN 1><!ENTITY ent_name ent_value   >Here &amp;foo; There</para>},
    'Entities'
);

eval { my $xf = XML::TreeBuilder->new( NoExpand => 1 ); };

like(
    $@,
    qr/new expects an anonymous hash.* for it's parameters, not a/,
    'new expects a hash'
);
ok( $x->same_as($y), "same as" );

my $zb = XML::TreeBuilder->new( { NoExpand => 0, ErrorContext => 2 } );
$zb->parse_file("t/parse_test.xml");
like(
    $zb->as_XML(),
    qr{<p id="this.is.an.id">Here &foo; There\n\n&foo;\n\nThis is FOO\n</p>},
    'Expand entity'
);
__END__
