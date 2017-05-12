#!perl

use strict;
use warnings;

use Fatal qw( waitpid close );
use English qw( -no_match_vars );

my %manifest;

## no critic (InputOutput::RequireBriefOpen)

open my $manifest, '<', '../MANIFEST'
    or Carp::croak("open of MANIFEST failed: $ERRNO");

FILE: while ( my $line = <$manifest> ) {
    chomp $line;
    $line =~ s/ \s* [#] .* \z//xms;
    $manifest{$line} = 1;
}

close $manifest;

my $pid = open my $rdr, q{-|}, 'svn', 'list', '-R', q{..}
    or Carp::croak("open of svn list pipe failed: $ERRNO");
waitpid $pid, 0;

FILE: while ( my $line = <$rdr> ) {
    chomp $line;
    next FILE if $line =~ m{ [/] \z }xms;
    next FILE if -d $line;
    next FILE if $manifest{$line};
    print "$line\n" or Carp::croak("Cannot print: $ERRNO");
}
