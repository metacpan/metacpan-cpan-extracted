#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Tie::ListKeyedHash;

my %example;
tie (%example, 'Tie::ListKeyedHash');

%example = (
    'a' => {
      'b0' => {
        'c' => 'value of c',
        'd' => 'value of d',
        'e' => {
          'f' => 'value of f',
        },
      },
      'b1' => {
        'g' => 'value of g',
      },
    },
    'h' => 'r',
);

my $b_key = ['a','b0'];

my $d_key = [@$b_key,'d'];
my $d     = $example{$d_key};
print "d = $d\n";

my $e_key = [@$b_key, 'e']; 
my $e     = $example{$e_key};
print 'e = ' . Dumper ($e);

my $f_key = [@$b_key, 'e','f']; 
my $f     = $example{$f_key};
print "f = $f\n";

my $h_key = ['h'];
my $h     = $example{$h_key};
print "h = $h\n";

