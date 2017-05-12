#/usr/bin/env perl

use common::sense;
use warnings FATAL => q(all);
use List::Util qw[shuffle];
use Test::More;
use Data::Dumper;
local $Data::Dumper::Deepcopy = 1;
local $Data::Dumper::Indent   = 0;
local $Data::Dumper::Purity   = 1;
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Terse    = 1;
local $Data::Dumper::Useperl  = 0;
local $Data::Dumper::Useqq    = 1;

use Text::UnAbbrev;

my $unabbrev = Text::UnAbbrev->new();

my ( @test, %test );
my @language = keys %{ $unabbrev->dict() };
foreach my $language (@language) {
    my @domain = keys %{ $unabbrev->dict->{$language} };
    foreach my $domain (@domain) {
        my @subdomain = keys %{ $unabbrev->dict->{$language}{$domain} };
        foreach my $subdomain (@subdomain) {
            my @abbrev
                = keys %{ $unabbrev->dict->{$language}{$domain}{$subdomain} };
            foreach my $abbrev (@abbrev) {
                my @expand
                    = @{ $unabbrev->dict->{$language}{$domain}{$subdomain}
                        {$abbrev} };
                foreach my $expand (@expand) {
                    $test{q()}{$abbrev}{$expand}++;
                    my $key = $language;
                    $test{$key}{$abbrev}{$expand}++;
                    $key .= $; . $domain;
                    $test{$key}{$abbrev}{$expand}++;
                    $key .= $; . $subdomain;
                    $test{$key}{$abbrev}{$expand}++;
                }
            }
        } ## end foreach my $subdomain (@subdomain)
    } ## end foreach my $domain (@domain)
} ## end foreach my $language (@language)

foreach my $params ( keys %test ) {
    my @param_value = split $;, $params;
    my @param_key = (qw[language domain subdomain]);
    my %param
        = map { $_ => @param_value ? shift @param_value : q() } @param_key;

    foreach my $abbrev ( keys %{ $test{$params} } ) {
        my @expand = sort keys %{ $test{$params}{$abbrev} };
        push @test, [ {%param}, [ $abbrev, [@expand] ] ];
    }
}

foreach my $test ( shuffle @test ) {
    my %param    = %{ $test->[0] };
    my $input    = $test->[1][0];
    my $expected = $test->[1][1];
    my $testname = Dumper( { params => {%param}, input => $input } );

    while ( my ( $method, $value ) = each %param ) {
        $unabbrev->$method($value);
    }

    my $output = [ sort $unabbrev->lookup($input) ];
    unless ( is_deeply( $output, $expected, $testname ) ) {
        say Dumper( { output   => $output } );
        say Dumper( { expected => $expected } );
    }
} ## end foreach my $test ( shuffle ...)

done_testing();

# Local Variables:
# mode: perl
# coding: utf-8-unix
# End:
