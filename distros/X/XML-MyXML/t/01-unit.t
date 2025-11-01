use strict;
use warnings;
use utf8;

use Test::More;

use XML::MyXML;
use XML::MyXML::Object;

my $unescape = \&XML::MyXML::Object::_string_unescape;

subtest '_string_unescape' => sub {
    is $unescape->("Alex"), "Alex", "Alex";
    is $unescape->("Al\"ex"), "Al\"ex", "Al\"ex";
    is $unescape->("Al\\\"ex"), "Al\"ex", "Al\\\"ex";
    is $unescape->("Al\\[ex"), "Al[ex", "Al\\[ex";
    is $unescape->("Al\\\\ex"), "Al\\ex", "Al\\\\ex";
};

my $decode = \&XML::MyXML::_decode;
subtest '_decode' => sub {
    is $decode->('A&#65;A'), 'AAA', '&#65;';
    is $decode->('A&#x41;A'), 'AAA', '&#x41;';
};

done_testing;
