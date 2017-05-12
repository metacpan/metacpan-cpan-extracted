#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use VS::RuleEngine::Declare;
use VS::RuleEngine::Constants;

BEGIN { use_ok("VS::RuleEngine::Rule::InputMatchesRegexp"); }

my @keys = ( 
    { v => ["foo"],         t => ["foo"],       r => 1 },
    { v => ["foo"],         t => ["bar"],       r => 0 },
    { v => [qw(foo bar)],   t => [qw(foo bar)], r => 1 },
    { v => [qw(foo bar)],   t => [qw(bar foo)], r => 0 },
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
        
        rule 'check' => instanceof "VS::RuleEngine::Rule::InputMatchesRegexp" => with_args \%args;
        
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
