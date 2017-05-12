#!perl

use strict;
use warnings;

my $key = '';

if (! $key) {
    die 'An API key is required.';
}

use WWW::Search;
use WWW::Search::UrbanDictionary;

my $search = WWW::Search->new('UrbanDictionary', 'key' => $key);

$search->native_query('emo');
my $result = $search->next_result;

{ # A bad example
    $search->native_query('urbandictionary test ' . time );
    my $result = $search->next_result;
}
