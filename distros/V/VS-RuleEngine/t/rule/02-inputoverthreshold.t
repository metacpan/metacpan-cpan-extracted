#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Constants;

BEGIN { use_ok("VS::RuleEngine::Rule::InputOverThreshold"); }

my @keys = ( 
    { v => [1, 2, 3],       t => [1, 2, 3],     r => 1 },
    { v => [1, 2, 3],       t => [2, 4, 6],     r => 0 },
    { v => [2, 4, 6],       t => [1, 2, 3],     r => 1 },
    { v => [1, 2, 3],       t => [1, 3, 2],     r => 0 },
    { v => [-1, -2, -3],    t => [-1, -2, -3],  r => 1 },
    { v => [-1, -2, -3],    t => [-2, -4, -6],  r => 0 },
    { v => [-2, -4, -6],    t => [-1, -2, -3],  r => 1 },
);

for my $key (@keys) {
    my $i = 1;
    my %args = map { "i" . $i++ => $_ } @{$key->{t}};

    my $facit = join(", ", @{$key->{v}}) . " => " . join(", ", @{$key->{t}}) . " => " . $key->{r};
    
    my $engine = engine {
        $i = 1;
        for my $v (@{$key->{v}}) {
            input "i$i" => does {
                return $v;
            };
            $i++;
        }
        
        rule 'check' => instanceof "VS::RuleEngine::Rule::InputOverThreshold" => with_args \%args;
        
        rule 'abort' => does {
            return KV_MATCH;
        };
    
        action 'ok' => does {
            ok($key->{r} == 1, $facit);
        },
    
        action 'nok' => does {
            ok($key->{r} == 0, $facit);
        };
    
        run 'ok' => when qw(check);
        run 'nok' => when qw(abort);
    
        posthook 'abort' => does { return KV_ABORT; };
    };

    $engine->run;
}
