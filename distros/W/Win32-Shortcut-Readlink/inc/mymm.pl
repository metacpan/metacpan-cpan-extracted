package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Copy qw( copy );

sub myWriteMakefile
{
  my(%args) = @_;

  my @xs = qw( Readlink.xs resolve.cpp typemap );
  unlink $_ for @xs;
  
  if($^O =~ /^(cygwin|MSWin32|msys)$/)
  {
    $args{INC}    = '-Ixs';
    $args{LIBS}   = [ '-L/usr/lib/w32api -lole32 -luuid' ] if $^O eq 'cygwin';
    $args{OBJECT} = [ 'Readlink$(OBJ_EXT)', 'resolve$(OBJ_EXT)' ];

    foreach my $name (@xs)
    {
      my $from = "xs/$name";
      my $to   = "$name";
      copy($from, $to) || die "unable to copy $from to $to $!";
    }
  }

  WriteMakefile(%args);
}

1;
