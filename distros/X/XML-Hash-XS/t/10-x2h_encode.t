package main;
use strict;
use warnings;

use Test::More tests => 11;
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

use XML::Hash::XS 'xml2hash';
$XML::Hash::XS::keep_root = 0;

our $xml_decl_utf8 = qq{<?xml version="1.0" encoding="utf-8"?>};

SKIP: {
    use utf8;
    my $result = eval { xml2hash('t/test_cp1251.xml') };
    my $err = $@;
    chomp $err;
    skip $err, 1 if $err;
    is
        $result,
        'Привет!',
        'test cp1251',
    ;
}

SKIP: {
    my $result = eval { xml2hash('t/test_cp1251.xml', utf8 => 0) };
    my $err = $@;
    chomp $err;
    skip $err, 1 if $err;
    is
        $result,
        'Привет!',
        'test cp1251 utf8 off',
    ;
}

SKIP: {
    use utf8;
    my $result = eval { xml2hash('t/test_cp1251.xml', encoding => 'cp1251') };
    my $err = $@;
    chomp $err;
    skip $err, 1 if $err;
    is
        $result,
        'Привет!',
        'test cp1251 with encoding',
    ;
}

SKIP: {
    my $result = eval { xml2hash('t/test_cp1251.xml', encoding => 'iso-8859-1', utf8 => 0) };
    my $err = $@;
    chomp $err;
    skip $err, 1 if $err;
    is
        $result,
        'Ïðèâåò!',
        'test cp1251 without encoding',
    ;
}

SKIP: {
    my $result = eval { xml2hash('t/test_cp1251_wo_decl.xml', utf8 => 0) };
    my $err = $@;
    chomp $err;
    skip $err, 1 if $err;
    is
        $result,
        "\317\360\350\342\345\362!",
        'test cp1251 wo decl',
    ;
}

SKIP: {
    use utf8;
    my $result = eval { xml2hash('t/test_cp1251_wo_decl.xml', encoding => 'cp1251') };
    my $err = $@;
    chomp $err;
    skip $err, 1 if $err;
    is
        $result,
        "Привет!",
        'test cp1251 wo decl with encoding',
    ;
}

{
    use utf8;
    is
        xml2hash('t/test_utf8.xml'),
        "Привет!",
        'test utf8',
    ;
}

{
    use utf8;
    is
        xml2hash('t/test_utf8.xml', encoding => 'utf-8'),
        "Привет!",
        'test utf8 with encoding',
    ;
}

{
    is
        xml2hash('t/test_utf8.xml', utf8 => 0),
        "Привет!",
        'test utf8 with utf8 off',
    ;
}

{
    is
        xml2hash('<root>Привет!</root>', utf8 => 0),
        "Привет!",
        'test utf8 string with utf8 off',
    ;
}

{
    use utf8;
    is
        xml2hash('<root>Привет!</root>'),
        "Привет!",
        'test utf8 string with utf8 on',
    ;
}
