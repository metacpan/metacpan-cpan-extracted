#!/usr/bin/perl
use UI::Dialog;

my $d = new UI::Dialog
  ( order => ["whiptail"],
    height => 20, listheight => 5, debug => 1,
  );
my @items =
 ( 1, 'Running `uname -o`',
   2, 'Running $(uname -o)'
 );
$d->menu
  ( text=>"The following menu items allow for commands in strings.",
    list=>\@items,
    'trust-input' => 1
  );
$d->menu
  ( text=>"The following menu items DO NOT allow for commands in strings. (Default behaviour.)",
    list=>\@items,
  );
