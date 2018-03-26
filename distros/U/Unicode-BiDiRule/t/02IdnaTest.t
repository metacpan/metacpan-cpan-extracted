#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use warnings;
no utf8;
use Test::More;

use Encode qw(encode_utf8);
use Unicode::BiDiRule qw(check BIDIRULE_LTR BIDIRULE_RTL);

my @TESTS;
my $testfile;

BEGIN {
    my $UnicodeVersion = Unicode::BiDiRule::UnicodeVersion();
    if (open my $fh, '<:utf8', "t/IdnaTest-$UnicodeVersion.txt") {
        $testfile = <$fh>;
        $testfile .= <$fh>;
        while (<$fh>) {
            chomp $_;
            s/#.*//;
            next unless /\S/;

            my ($type, $source, $toUnicode) = split /[ \t]*;[ \t]*/, $_;
            next if $source =~ /\Axn--/;         # Punycode case
            next if $source =~ /\\uD[89A-F]/;    # Surrogate cases
            $source    =~ s/\\u([0-9A-F]{4})/pack 'U', hex "0x$1"/egi;
            $toUnicode =~ s/\\u([0-9A-F]{4})/pack 'U', hex "0x$1"/egi;

            $source =~ s/[\x{FF0E}\x{3002}\x{FF61}]/./g;
            next if $source =~ /[.]/;            # Multiple lables
            #next if $source =~ /\A[\x21-\x7E]+\z/;    # LDH labels
            #next if $source =~ /\A[0-9]/;             # Beginning with digits
            #next if $source =~ /(?:\x{200C}|\x{200D}|\p{Bidi_Class:ON})\z/;

            $toUnicode = $source unless length $toUnicode;

            if ($source eq $toUnicode) {
                push @TESTS, [1, $., $type, $source];
            } elsif ($toUnicode =~ /[[](\w\d )*B\d( \w\d)*[]]/) {
                push @TESTS, [undef, $., "$type $toUnicode", $source];
            }
        }
        close $fh;
    }
}

if (@TESTS) {
    plan tests => scalar(@TESTS);
    diag $testfile;
} else {
    plan skip_all => 'No t/IdnaTest.txt.';
}

foreach my $test (@TESTS) {
    my ($expected, $lineno, $type, $source) = @$test;
    my $result = check($source);
    if ($expected) {
        ok( defined $result, sprintf '%d: result=%s; type=%s; %s',
            $lineno, (defined $result ? $result : 'undef'),
            $type, escape_string($source)
        );
    } else {
        ok( !defined $result,
            sprintf '%d: result=undef; type=%s; %s',
            $lineno, $type, escape_string($source)
        );
    }
}

sub escape_string {
    my $str = shift;
    join '', map { sprintf '\\x{%02X}', ord $_ } split //, $str;
}
