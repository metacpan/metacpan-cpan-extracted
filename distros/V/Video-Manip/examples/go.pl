#!/usr/bin/perl -w

use strict;
use Video::Manip;

my $config = "config.xml";

#eval to catch die 
my $v = Video::Manip->new(rawvideo => '/data/video/',
                          writefile => 'events',
                          progid => 1,
                          algoid => 1,
                          vfps => 29.97,
                          destdir => './out/',
                          sourcedir => './in',
                          genshell => 1,
                         );

my %algorithms = ( 
                    'Manual'  => {'config' => $config},
                );  

$v->use(\%algorithms) or die "some algorithms not working: $!";
#$v->redefineenvl('newconfig.xml');
$v->findevents() 
    or die "problem findingevents: $!";
$v->extract('-all') or die "problem compressing: $!";



