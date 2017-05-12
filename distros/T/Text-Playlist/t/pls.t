#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';

use POSIX qw(tmpnam);
use Test::More tests => 4;

require_ok('Text::Playlist::PLS');

my $pls = new_ok('Text::Playlist::PLS' => []);

my $path = tmpnam();
open my $FH, ">", $path;
print $FH <<EOF;
[playlist]
numberofentries=1
File1 = http://1.2.3.4:8000/listen.aac
Title1=(#1 - 1/1) Radio Broadcast 
Length1=-1
Version=2
EOF
close $FH;

my $out = [{
  file   => 'http://1.2.3.4:8000/listen.aac',
  title  => '(#1 - 1/1) Radio Broadcast',
  length => '-1',
}];
my @items = $pls->load($path);
is_deeply(\@items, $out, "Loading test playlist");

unlink $path;

my $text = <<PLS;
[playlist]
numberofentries=1
File1=http://1.2.3.4:8000/listen.aac
Title1=(#1 - 1/1) Radio Broadcast
Length1=-1
Version=2
PLS

is($pls->dump(@items), $text);

exit 0;
