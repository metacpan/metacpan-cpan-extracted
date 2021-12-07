#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Config;
use Devel::CheckOS qw(os_is);
use File::Temp;

local $/ = undef;

my $eol = os_is('MicrosoftWindows') ? "\r\n" : "\n";

test_fragment(
    q{ print qq{foo\n}; print qq{bar\n}; },
    "foo${eol}bar${eol}",
    "default 'print' works OK"
);

test_fragment(
    q{ printf qq{%s %d\n}, qq{foo}, 20; },
    "foo 20${eol}",
    "default 'printf' works OK"
);

test_fragment(
    q{ syswrite STDOUT, qq{gibberish}, 5; },
    "gibbe",
    "default 'syswrite' works with no offset"
);

test_fragment(
    q{ syswrite STDOUT, qq{gibberish}, 5, 2; },
    "bberi",
    "default 'syswrite' works with an offset"
);

test_fragment(
    q{ binmode STDOUT, ':raw'; print chr(0xED); },
    chr(0xED),
    "binmode works (raw)"
);

test_fragment(
    q{ binmode STDOUT, ':utf8'; print chr(0xED); },
    chr(0xC3).chr(0xAD),
    "binmode works (utf8)"
);

done_testing();

sub test_fragment {
    my($fragment, $expected, $message) = @_;

    my $tempfile = File::Temp::tempnam('.', 'tie-stdout-test-');
    my $preamble = join(' ',
        $Config{perlpath},
        ($ENV{HARNESS_PERL_SWITCHES} && $ENV{HARNESS_PERL_SWITCHES} eq '-MDevel::Cover' ? '-MDevel::Cover' : ''),
        qw(-Ilib -MTie::STDOUT -e ")
    );
    my $postamble = "\" >$tempfile";

    system($preamble.$fragment.$postamble);
    open(my $fh, '<:raw', $tempfile);
    is(<$fh>, $expected, $message);
    unlink($tempfile);
}
