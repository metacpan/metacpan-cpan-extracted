#!/usr/bin/perl

use strict;
use warnings;
use Tk;
require Tk::MatchingBE;

my ($t1,$t2);
my ($mbe1,$mbe2);

my $mw = tkinit();
$mw->Label(-textvariable => \$t1)->pack;
$mbe1 = $mw->MatchingBE(-choices => [qw/foo bar baz buzz bizz/],
                       -selectcmd => sub{
                           $t1 = $mbe1->get_selected_value
                       },
                   )->pack;

my $labels_and_values = [{value => 42,
                          label => 'foo'},
                         {value => 33,
                          label => 'baz'},
                         {value => 5,
                          label => 'buzz'},
                         {value => 43,
                          label => 'bizz'},
                         {value => 10,
                          label => 'fizz'},
                     ];

my $label = $mw->Label()->pack;

$mbe2 = $mw->MatchingBE(-labels_and_values => $labels_and_values,
                        -value_variable => \$t2,
                        -selectcmd => sub{
                           $label->configure(-text => "[ $t2 ]");
                       },
                   )->pack;

MainLoop;
