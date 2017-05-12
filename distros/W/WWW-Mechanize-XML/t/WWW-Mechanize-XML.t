#!perl

use strict;
use warnings;

use Test::More tests => 42;
use Test::Exception;
use Cwd;
my $cwd = getcwd();

use_ok('WWW::Mechanize::XML');
my $mech;

foreach my $option (qw(
    quiet
    stack_depth
    )) {
    foreach (0..1) {
        $mech = WWW::Mechanize::XML->new( $option => $_ );
        is($mech->$option, $_, "Mechanize option set: $option => $_");
    }
}

foreach my $option (qw(
    validation
    recover
    expand_entities
    keep_blanks
    pedantic_parser
    line_numbers
    load_ext_dtd
    complete_attributes
    expand_xinclude
    clean_namespaces
    )) {
    foreach (0..1) {
        $mech = WWW::Mechanize::XML->new( xml_parser_options => { $option => $_ } );
        is($mech->{xml_parser}->$option, $_, "Mechanize parser option set: $option => $_");
    }
}

foreach my $option (qw(
    foo
    bar
    )) {
    throws_ok {
        $mech = WWW::Mechanize::XML->new( xml_parser_options => { $option => 1 } );
    } qr/Invalid parser option/, "Invalid parser option: $option";
}

$mech = WWW::Mechanize::XML->new();
my $dom;

ok($mech->get("file://$cwd/t/files/valid.xml"), 'got valid xml file');
lives_ok {
    $dom = $mech->xml();
} 'got xml dom from valid xml';
isa_ok($dom, 'XML::LibXML::Document');

ok($mech->get("file://$cwd/t/files/invalid.xml"), 'got invalid xml file');
throws_ok {
    $dom = $mech->xml();
} qr/Opening\sand\sending\stag\smismatch/, 'xml is invalid';



# test error throwing
ok($mech->get("file://$cwd/t/files/error.xml"), 'got error xml');
ok($dom = $mech->xml(), 'error xml response caused no exception');

$mech = WWW::Mechanize::XML->new( xml_error_options => {
        trigger_xpath => '/rsp/@stat'
});
ok($mech->get("file://$cwd/t/files/error.xml"), 'got error xml');
throws_ok {
    $dom = $mech->xml();
} qr/fail/, 'error xml response caused exception - fail';


$mech = WWW::Mechanize::XML->new( xml_error_options => {
        trigger_xpath => '/rsp/@stat',
        trigger_value => 'foo'
});
ok($mech->get("file://$cwd/t/files/error.xml"), 'got error xml');
lives_ok {
    $dom = $mech->xml();
} "trigger value of 'foo' did not cause exception";


$mech = WWW::Mechanize::XML->new( xml_error_options => {
        trigger_xpath => '/rsp/@stat',
        trigger_value => 'fail'
});
ok($mech->get("file://$cwd/t/files/error.xml"), 'got error xml');
throws_ok {
    $dom = $mech->xml();
} qr/fail/, "trigger value of 'fail' did cause exception";


$mech = WWW::Mechanize::XML->new( xml_error_options => {
        trigger_xpath => '/rsp/@stat',
        trigger_value => 'fail',
        message_xpath => '/rsp/err/@msg'
});
ok($mech->get("file://$cwd/t/files/error.xml"), 'got error xml');
throws_ok {
    $dom = $mech->xml();
} qr/some\serror\shas\soccurred/, 'message xpath used for failure message';
