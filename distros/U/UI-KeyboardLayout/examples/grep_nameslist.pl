#!/usr/bin/perl -wC31
use UI::KeyboardLayout; 
use strict;

die "Usage: $0 REGULAR_EXPRESSION [<] Unicode/NamesList.txt" unless @ARGV;
my $rx = shift;
$rx = qr/$rx/;

#open my $f, '<', 
my $home = $ENV{HOME} || '';
$home = "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" if $ENV{HOMEDRIVE} and $ENV{HOMEPATH};
my $d = "$home/Downloads";
my $f = "$home/Downloads/NamesList.txt";		# or die;
-e "$d/NamesList.txt" or $d = '/cygdrive/c/Users/ilya/Downloads';
my $k = UI::KeyboardLayout::->new()->load_unidata("$d/NamesList.txt", "$d/DerivedAge.txt");

my @leaders;
while (<>) {
  $leaders[length $1] = $_, next if /^(\@+\s)/;
  next unless my ($n) = /^([0-9a-f]{4,})\s/i and /$rx/;
  s/$/;\t\t$k->{Age}{chr hex $n}/ if $k->{Age}{chr hex $n};
  while (@leaders) {
    my $l = pop @leaders or next;
    print $l;
  }
  print;
  print while $_ = <> and not /^([0-9a-f]{4,}|\@+)\s/i;
  last if eof;
  redo;
}
