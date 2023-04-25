#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;
use Benchmark ':all';
use Test::More;
use Text::Levenshtein::Flexible;
use Text::Levenshtein::XS;
use Text::LevenshteinXS;
use Text::Fuzzy;

my $o = Text::Levenshtein::Flexible->new(1000000, 1, 2, 3);
my $s = "ⓕⓞaⓤⓡ"x10;
my $t = "aⓕⓞⓡ"x10;
is($o->distance_lc($s,$t), Text::Levenshtein::Flexible::levenshtein_lc($s, $t, 1000000, 1, 2, 3),
    "Same result OO vs. procedural"
);
cmpthese(100000, {
        OO      => sub { $o->distance_lc($s, $t); },
        Proc    => sub { Text::Levenshtein::Flexible::levenshtein_lc($s, $t, 1000000, 1, 2, 3); },
    }
);

test_variant("xa"x100, "ybc"x60, "ASCII text", 1);
test_variant("ⓕⓞⓤⓡ"x100,"ⓞⓕⓞⓡ"x100, "strings of 3-byte UTF-8 characters", 0);
test_variant("ⓕⓞaⓤⓡ"x100, "aⓕⓞⓡ"x100, "a mixture of ASCII and 3-byte UTF-8 characters", 0);
done_testing;

sub test_variant {
    my ($s, $t, $message, $testTLXS) = @_;
    print "Testing with $message\n";
    my $tf = Text::Fuzzy->new($s);
    my $tlf = Text::Levenshtein::Flexible->new(65535);
    is(Text::Levenshtein::Flexible::levenshtein($s,$t), Text::Levenshtein::XS::distance($s,$t),
        "Same result Text::Levenshtein::Flexible vs. Text::Levenshtein::XS"
    );
    is(Text::Levenshtein::Flexible::levenshtein($s,$t), $tf->distance($t),
        "Same result Text::Levenshtein::Flexible vs. Text::Fuzzy"
    );
    $testTLXS and is(Text::Levenshtein::Flexible::levenshtein($s,$t), Text::LevenshteinXS::distance($s,$t),
        "Same result Text::Levenshtein::Flexible vs. Text::LevenshteinXS"
    );

    my @inputs = ($t) x 1000;
    cmpthese(10, {
            'Text::Levenshtein::Flexible/a' => sub { $tlf->distance_l_all($s, @inputs); },
            'Text::Levenshtein::Flexible'   => sub { $tlf->distance_l($s, $_) for @inputs; },
            'Text::Levenshtein::XS'         => sub { Text::Levenshtein::XS::distance($s, $_) for @inputs },
            'Text::Fuzzy/newobj'            => sub { Text::Fuzzy->new($s)->distance($_) for @inputs },
            'Text::Fuzzy/reuse'             => sub { $tf->distance($_) for @inputs },
            $testTLXS ? ('Text::LevenshteinXS' => sub { Text::LevenshteinXS::distance($s, $t) for @inputs }) : (),
        }
    );

}
