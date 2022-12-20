#!/usr/bin/env perl

use strict;
use warnings;

use Util::H2O qw/h2o o2h/;
use Data::Dumper qw//;

my $HoA = {
  one => [qw/1 2 3 4 5/],
  two => [qw/6 7 8 9 0/],
};

#h2o -recurse, $HoA;
#print Data::Dumper::Dumper($HoA);

my $HoAoH = {
  one   => [qw/1 2 3 4 5/],
  two   => [qw/6 7 8 9 0/],
  three => [
     { four => 4, five => 5, six => 6 },
     { seven => 7, eight => 8, nine => 9 },
  ], 
  ten => {
    eleven    => [qw/11 12 13 14 15 16 17 18 19 20/],
    twentyone => [
      { 
        21 => q{twenty-one},
        22 => q{twenty-two},
      }, 
      42,
      undef,
    ],
    thirteen => 13,
  },
};


sub h3o($);
sub h3o($) {
  my $thing = shift;
  return $thing if not $thing;
  my $isa = ref $thing;
  if ($isa eq q{ARRAY}) {
     foreach my $element (@$thing) {
         h3o($element);
     } 
  }
  elsif ($isa eq q{HASH}) {
     foreach my $keys (keys %$thing) {
         h3o($thing->{$keys});
     } 
     h2o $thing;
  }
  return $thing; 
}

sub o3h($);
sub o3h($) {
  my $thing = shift;
  no warnings 'prototype';
  return $thing if not $thing;
  my $isa = ref $thing;
  if ($isa eq q{ARRAY}) {
     foreach my $element (@$thing) {
         $element = o3h($element);
     } 
  }
  elsif ($isa eq q{HASH}) {
     foreach my $key (keys %$thing) {
         $thing->{$key} = o3h($thing->{$key});
     } 
     $thing = o2h $thing;
  }
  return o2h $thing; 
}

h3o $HoAoH;
#print Data::Dumper::Dumper($HoAoH);


require HTTP::Tiny;
require JSON;

my $http = HTTP::Tiny->new;
my $response = h2o $http->get(q{https://jsonplaceholder.typicode.com/users});

# decode JSON from response content
my $json_array_ref = JSON::decode_json($response->content); # $json is an ARRAY reference

h3o $json_array_ref;
o3h $json_array_ref;

print Data::Dumper::Dumper($json_array_ref);
