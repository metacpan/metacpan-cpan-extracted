#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Tie::ListKeyedHash;

my %example = (
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

my $obj = Tie::ListKeyedHash->new(\%example);

my $b_key = ['a','b0'];

my $d_key = [@$b_key,'d'];
my $d     = $obj->get($d_key);
print "d = $d\n";

my $e_key = [@$b_key, 'e']; 
my $e     = $obj->get($e_key);
print 'e = ' . Dumper ($e);

my $f_key = [@$b_key, 'e','f']; 
my $f     = $obj->get($f_key);
print "f = $f\n";

my $h_key = ['h'];
my $h     = $obj->get($h_key);
print "h = $h\n";

