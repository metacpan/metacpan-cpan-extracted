#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use File::Find ();

# What installing puts on disk: the modules, the word tables and the number words.
my $bytes = 0;
File::Find::find(sub { $bytes += -s $_ if -f $_ && $File::Find::name =~ m{Time/Keeper/Natural} && !/\.exists\z/ }, 'blib/lib');
mark_most('installed size', sprintf('%.2f', $bytes / 1e6), 1, 'MB');
done();
