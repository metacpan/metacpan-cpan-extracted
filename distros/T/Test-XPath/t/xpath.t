#!/usr/bin/perl -w

use strict;
use Test::More tests => 57;
#use Test::More 'no_plan';
use File::Spec::Functions 'catfile';
use utf8;

BEGIN { use_ok 'Test::XPath' or die; }

# Try failure.
eval { Test::XPath->new };
like $@, qr{Test::XPath->new requires the "xml", "file", or "doc" parameter},
    'Should get an exception for invalid params';

my $xml = '<foo xmlns="http://w3.org/ex"><bar>first</bar><bar>post</bar></foo>';
my $html = '<html><head><title>Hello</title><body><p><em><b>first</b></em></p><p><em><b>post</b></em></p></body></html>';

ok my $xp = Test::XPath->new(
    xml => $xml,
), 'Should be able to create an object';
isa_ok $xp, 'Test::XPath';
isa_ok $xp->{xpc}, 'XML::LibXML::XPathContext';

ok +Test::XPath->new(
    xml         => $xml,
    options     => {
        no_network  => 1,
        keep_blanks => 1,
        suppress_errors => 1
    },
), 'Should be able to configure the parser';

ok $xp = Test::XPath->new(
    xml     => $html,
    is_html => 1,
), 'Should be able to parse HTML';
isa_ok $xp, 'Test::XPath';
isa_ok $xp->{xpc}, 'XML::LibXML::XPathContext';

# Do some tests with it.
$xp->ok('/html/head/title', 'Should find the title');

# Try a recursive call.
$xp->ok( '/html/body/p', sub {
    shift->ok('./em', sub {
        $_->ok('./b', 'Find b under em');
    }, 'Find em under para');
}, 'Find paragraphs');

# Make sure that find_value() works.
is $xp->find_value('/html/head/title'), 'Hello', 'find_value should work';

# Try is, like, and cmp_ok.
$xp->is( '/html/head/title', 'Hello', 'is should work');
$xp->isnt( '/html/head/title', 'Bye', 'isnt should work');
$xp->like( '/html/head/title', qr{^Hel{2}o$}, 'like should work');
$xp->unlike( '/html/head/title', qr{^Bye$}, 'unlike should work');
$xp->cmp_ok('/html/head/title', 'eq', 'Hello', 'cmp_ok should work');

# Try multiples.
$xp->is('/html/body/p', 'firstpost', 'Two values should concatenate');

# Try loading a file.
my $file = catfile qw(t menu.xml);
ok $xp = Test::XPath->new( file => $file ), 'Should create with file';

# Do some tests on the XML.
$xp->is('/menu/restaurant', 'Trébol', 'Should find Unicode value in file');

# Use recursive ok() to ensure all items have the appropriate parts.
my $i = 0;
$xp->ok('/menu/item', sub {
    ++$i;
    $_->ok('./name', "Item $i should have a name");
    $_->ok('./price', "Item $i should have a price");
    $_->ok('./description', "Item $i should have a description");
}, 'Should have items' );

# Hey, so no try using the doc param.
ok $xp = Test::XPath->new(
    doc => XML::LibXML->new->parse_file($file),
), 'Should create with doc';
$xp->is('/menu/restaurant', 'Trébol', 'Should find Unicode value in doc');

# Use a namespace.
ok $xp = Test::XPath->new(
    xml   => $xml,
    xmlns => { 'ex' => 'http://w3.org/ex' },
), 'Should create with real namespace';
$xp->ok('/ex:foo/ex:bar', 'We should find an ex:bar');
$xp->is('/ex:foo/ex:bar[1]', 'first', 'Should be able to check the first ex:bar value');
