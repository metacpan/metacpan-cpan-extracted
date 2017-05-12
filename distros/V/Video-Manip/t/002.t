#!/usr/bin/perl
use lib "../lib";
use strict;
use Test::Simple tests => 2;
use Video::Manip;

my $config =  {
          'u' => {
                   'envl' => {},
                   'name' => 'undo',
                   'type' => 'system'
                 },
          'a' => {
                   'name' => 'funny',
                   'envl' => {
                               '1' => '.5',
                               '0' => '1',
                               '-2' => '.2',
                               '0.5' => '.9',
                               '2' => '.2',
                               '-1' => '.5',
                               '-0.5' => '.9'
                             },
                   'type' => 'long'
                 },
          'q' => {
                   'envl' => {},
                   'name' => 'quit',
                   'type' => 'system'
                 },
          'b' => {
                   'name' => 'shortb',
                   'envl' => {
                               '1' => '.5',
                               '0' => '1',
                               '-2' => '0',
                               '2' => '0',
                               '-1' => '.5'
                             },
                   'type' => 'short'
                 },
          '.' => {
                   'envl' => {},
                   'name' => 'tag',
                   'type' => 'system'
                 },
          ',' => {
                   'envl' => {},
                   'name' => 'tagedit',
                   'type' => 'system'
                 },
          'v' => {
                   'envl' => {},
                   'name' => 'undoendpt',
                   'type' => 'system'
                 },
          'd' => {
                   'envl' => {},
                   'name' => 'delete',
                   'type' => 'system'
                 }
        };


my $v = Video::Manip->new();

my %algorithms = ( 
                    'Manual'  => {'config' => $config},
                );  

my $t = $v->use(\%algorithms) or die "some algorithms not working: $!";

ok($t, "use works with FindEvent::Manual");

my $tt = $v->extract('-all') or die "problem compressing: $!";

ok($tt, "extract works");



