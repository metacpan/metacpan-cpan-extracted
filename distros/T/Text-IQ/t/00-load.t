#!/usr/bin/env perl

use Test::More;
use Data::Dump qw( dump );

eval "use Text::Aspell";
plan skip_all => "Text::Aspell unavailable" if $@;
use_ok('Text::IQ');

diag("Testing Text::IQ $Text::IQ::VERSION, Perl $], $^X");

{
    my $checker = Search::Tools::SpellCheck->new( lang => 'en_US', );
    diag "Text::Aspell config:";
    diag( dump( $checker->aspell->fetch_option_keys ) );
}

done_testing();
