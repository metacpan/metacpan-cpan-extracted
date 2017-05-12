#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 9;

BEGIN {
    use_ok('XML::Entities')
}

my $all = XML::Entities::Data::all();
my @allkeys   = keys   %$all;
my @allvalues = values %$all;
my $passed;

ok(single_ascii(), "Single entity in ASCII string");
sub single_ascii {
    for my $i (0 .. $#allkeys) {
        my $entname = $allkeys[$i];
        my $entchar = $allvalues[$i];
        my $entcode = "&$entname";
        $entcode =~ s/;?$/;/;
        my $prefix = "Here be entity: ";
        my $suffix = " not unknown to us.\n";
        my $encoded = $prefix . $entcode . $suffix;
        my $decoded = $prefix . $entchar . $suffix;
        if ((my $v = XML::Entities::decode('all', $encoded)) ne $decoded) {
            diag("Expected '$decoded', got '$v'");
            return 0
        }
    }
    return 1
}

ok(single_unicode(), "Single entity in UNICODE string");
sub single_unicode {
    for my $i (0 .. $#allkeys) {
        my $entname = $allkeys[$i];
        my $entchar = $allvalues[$i];
        my $entcode = "&$entname";
        $entcode =~ s/;?$/;/;
        my $prefix = "日本語が好きです";
        my $suffix = "čeština je krásná";
        my $encoded = $prefix . $entcode . $suffix;
        my $decoded = $prefix . $entchar . $suffix;
        if ((my $v = XML::Entities::decode('all', $encoded)) ne $decoded) {
            diag("Expected '$decoded', got '$v'");
            return 0
        }
    }
    return 1
}

ok(multi_unicode(), "Multiple entities");
sub multi_unicode {
    for (my $i = 1; $i < $#allkeys; $i += 3) {
        my $ent1name = $allkeys[$i-1];
        my $ent2name = $allkeys[$i];
        my $ent3name = $allkeys[$i+1];
        my $ent1char = $allvalues[$i-1];
        my $ent2char = $allvalues[$i];
        my $ent3char = $allvalues[$i+1];
        my $ent1code = "&$ent1name";
        my $ent2code = "&$ent2name";
        my $ent3code = "&$ent3name";
        s/;?$/;/ for ($ent1code, $ent2code, $ent3code);
        my $part01 = "おうめくどなるど";
        my $part12 = "хед е фарм";
        my $part23 = "hýjá hýjá hoů";
        my $part34 = "ॐ";
        my $encoded = $part01 . $ent1code . $part12 . $ent2code . $part23 . $ent3code . $part34;
        my $decoded = $part01 . $ent1char . $part12 . $ent2char . $part23 . $ent3char . $part34;
        if ((my $v = XML::Entities::decode('all', $encoded)) ne $decoded) {
            diag("Expected '$decoded', got '$v'");
            return 0
        }
    }
    return 1
}

my $random_index = 1000 % @allkeys;
my $random_entname = $allkeys[$random_index];
my $random_entchar = $allvalues[$random_index];
my $random_entcode = "&$random_entname";
$random_entcode =~ s/;?$/;/;
my $encoded = "some text${random_entcode}some more text";
my $decoded = "some text${random_entchar}some more text";
my $old_encoded = $encoded;

(undef) = XML::Entities::decode('all', $encoded);
is($encoded, $old_encoded, "Does non-voind context leave the argument intact?");

XML::Entities::decode('all', $encoded);
is($encoded, $decoded, "Does void context alter the argument?");

$encoded = $old_encoded;
$random_index = 1500 % @allkeys;
$random_entname = $allkeys[$random_index];
$random_entchar = $allvalues[$random_index];
$random_entcode = "&$random_entname";
$random_entcode =~ s/;?$/;/;
my $encoded2 = "random blurb $random_entcode I love you Honeybunny";
my $decoded2 = "random blurb $random_entchar I love you Honeybunny";
my @rv = XML::Entities::decode('all', $encoded, $encoded2);
is_deeply(\@rv, [$decoded, $decoded2], "Does list return work?");

$encoded = "&entity;text text &anotherEntity;text text";
$decoded = "ENTITYtext text はtext text";
my %ent2chr = ( 'entity;' => 'ENTITY', 'anotherEntity' => 'は', 'irrelevant' => 'IRRELEVANT' );
is(XML::Entities::decode(\%ent2chr, $encoded), $decoded, "Do custom entity-to-character maps work?");



# numify

$encoded = 'ahoj &mufe; jak &se; mas &amp; co &delas;?';
$decoded = 'ahoj &#95; jak &se; mas &amp; co &#400;?';
%ent2chr = ( 'mufe' => '_', 'delas;' => chr(400) );
is(XML::Entities::numify(\%ent2chr, $encoded), $decoded, "Numify with custom map");
