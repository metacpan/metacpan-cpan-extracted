#!/usr/bin/perl -w

use strict;
use warnings;

# use Test::More tests => 12;
use Test::Simple skip_all => "Deprecated";
use Test::Warn;

use Weather::Google;

my $gw = new Weather::Google();

# 1
is($gw->language(), undef, "default language: undef");

# 2
$gw->language("de");
is($gw->language(), "de", "set language via language(): 'de'");

$gw = new Weather::Google("Herne, Germany", {language => "de"});

# 3
is($gw->language(), "de", "set language via new(): 'de'");
is($gw->encoding, "latin1", "de is latin1 encoding.");


$gw->language("ja");
is($gw->language(), "ja", "set language via language(): 'ja'");

$gw = new Weather::Google("Tokyo, Japan", {language => "ja"});

is($gw->language(), "ja", "set language via new(): 'ja'");
is($gw->encoding, "utf-8", "ja is utf-8 encoding.");


# 4
warning_like {
    $gw = new Weather::Google( "Herne, Germany",
        { language => "unsupported" } );
} qr/^"unsupported" is not a supported ISO language code\./;

# 5
is($gw->language(), undef, "set unsupported language via new(): not set");
is($gw->encoding, 'utf-8', "unsupported language encoding: default utf-8");

# 6
warning_like {
    $gw->language("unsupported");
} qr/^"unsupported" is not a supported ISO language code\./;

# 7
is($gw->language(), undef, "set unsupported language via language(): not set");
