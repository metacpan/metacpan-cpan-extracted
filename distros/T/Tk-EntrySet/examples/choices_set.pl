#!/usr/bin/perl

use strict;
use warnings;
use Tk;
require Tk::ChoicesSet;
my ($t1,$t2);
my ($cs1,$cs2);

my $mw = tkinit();

my $top= $mw->Frame(-relief      => 'sunken',
                    -borderwidth => 1,
                )->pack(-padx => 5,
                        -pady => 5);
$top->Label(-textvariable => \$t1)->pack;
$cs1 = $top->ChoicesSet(-choices => [qw/foo bar baz buzz bizz test this/],
                        -changed_command => sub{
                           $t1 = join (' ',map {"[$_]"} @{$cs1->valuelist});
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
                         {value => 3,
                          label => 'test'},
                         {value => 1,
                          label => 'this'},
                     ];

my $bot= $mw->Frame(-relief      => 'sunken',
                    -borderwidth => 1,
                )->pack(-padx => 5,
                        -pady => 5);
my $label = $bot->Label()->pack(-fill   => 'x',
                                -expand => 1);
$t2 = [];
$cs2 = $bot->ChoicesSet(
                        -labels_and_values  => $labels_and_values,
                        -valuelist_variable => \$t2,
                        -changed_command    => sub{
                           my $t = join (' ',map {"[$_]"}  @$t2);
                           $label->configure(-text => $t);
                       },
                    )->pack;

MainLoop;
