package Devel::TraceFuncs;

require 5.002;

use vars qw(@EXPORT_OK @EXPORT_OK @ISA);

@ISA    = qw( Exporter );
@EXPORT_OK = qw( trace debug max_trace_depth trace_file sub);

use FileHandle;

use strict;

my $depth           = 0;
my $max_trace_depth = -1;
my $trace_file      = \*STDERR;
my $space           = "|  ";
my @last_depth      = ();

sub new {
  my $this  = shift @_;
  my $class = ref($this) || $this;
  my $self  = {};

  package DB;  
  # ignore warning
  use vars qw(@args);
  my(@callVars) = caller(2);
  package Devel::TraceFuncs;

  # grab info from leftover parameters
  my $info_string = @_ ? ": '@_'": "";
  
  if (defined @callVars) {
    $self->{'call'} = "$callVars[3](" . join(", ", @DB::args) .
      ") (in $callVars[1]:$callVars[2])$info_string\n";
  } else {
    $self->{'call'} = "global$info_string\n";
  }
  
  $self->{'depth'} = ++$depth;
  
  if (($max_trace_depth == -1) || ($depth <= $max_trace_depth)) {
    unshift @last_depth, $depth;
    print $trace_file $space x ($depth - 1), "+-> ", $self->{'call'};
  }
  
  bless $self, $class;
}

sub DESTROY {
  my $self = shift;

  if (($max_trace_depth == -1) || ($self->{'depth'} <= $max_trace_depth)) {
    print $trace_file $space x ($self->{'depth'} - 1), "+-< ", $self->{'call'};
    shift @last_depth;
  }
  $depth--;
}

sub trace {
  $_[0] = new Devel::TraceFuncs(@_[1 .. $#_]);
  1;
}

sub debug {
  my @args = @_;
  my $force = ($args[$#args] =~ s/!$//);
    
  if ($force || ($max_trace_depth < 0) || ($depth <= $max_trace_depth)) {
    my ($filename,$line) = (caller(0))[1,2] or return;
    if (@last_depth) {
      my $sep = $space x $last_depth[0];
      print $trace_file $sep;
      grep(s/\n/\n$sep/g, @args);
    }

    print $trace_file "@args (in $filename:$line)\n";
  }
}

sub trace_file {
  if (@_) {
    if (ref $_[0]) {
      $trace_file = $_[0];
    } else {
      $trace_file = new FileHandle("> $_[0]")
    }
  }
  
  $trace_file;
}

sub max_trace_depth {
  $max_trace_depth = shift if @_;
  $max_trace_depth;
}

1;

__END__

=head1 NAME

Devel::TraceFuncs - trace function calls as they happen.

=head1 SYNOPSIS

Usage:
  
  require Devel::TraceFuncs;

  max_trace_depth 5;
  trace_file "foo.out";
  trace_file $file_handle;

  sub foo {
    IN(my $f, "a message");

    DEBUG "hellooo!";
  }

=head1 DESCRIPTION

Devel::TraceFuncs provides utilities to trace the execution of a
program.  It can print traces that look something like:

   +-> global: '0'
   |  +-> main::fo(4, 5) (in ./t.pm:32): 'now then'
   |  |  +-> main::fp(4, 5) (in ./t.pm:19)
   |  |  |  +-> main::fq() (in ./t.pm:13)
   |  |  |  |  que pee doll (in ./t.pm:8)
   |  |  |  +-< main::fq() (in ./t.pm:13)
   |  |  |  cee dee (in ./t.pm:14)
   |  |  +-< main::fp(4, 5) (in ./t.pm:19)
   |  |  ha
   |  |  hs (in ./t.pm:20)
   |  +-< main::fo(4, 5) (in ./t.pm:32): 'now then'
   |  done (in ./t.pm:34)
   +-< global: '0'

=head2 IN

A trace begins when a function calls I<IN>.  A my'd variable is passed
in, such that when that function exits, the destructor for the
variable is called.  If this trace is to be printed, the opening line
of the trace in printed at this time.  Any other parameters are
concatenated together, and printed on both the opening and closing
lines of the trace.

I wish the syntax could be a little nicer here, but I couldn't find
anything in perl that resembles Tcl's I<uplevel> or I<upvar> commands.
If I was one of the perl gods, I could have figured out a way to do
something like perl5db.pl:

   sub sub {
     # create a new subroutine, with a my'd TraceFunc object
   }

=head2 DEBUG

Print some text to the trace file, at the correct depth in the trace.
If the last parameter ends in "!", the arguments are printed,
regardless of current depth.

=head2 trace_file

I<trace_file> takes one argument, which is either a file name or an
open file handle.  All trace output will go to this file.

=head2 max_trace_depth

To avoid lots of nesting, particularly from recursive function calls,
you can set the maximum depth to be traced.  If this is -1 (the
default), all levels of functions are traced.  If it is 0, no trace
output occurs, except for I<DEBUG> statements that end in "!".

=head1 EXAMPLE

   #!/usr/local/bin/perl -w
   
   use Devel::TraceFuncs;
   use strict;
   
   sub fq {
     IN(my $f);
     DEBUG "que", "pee", "doll!";
   }
   
   sub fp {
     IN(my $f);
     fq();
     DEBUG "cee", "dee";
   }
   
   sub fo {
     IN(my $f, "now", "then");
     &fp;
     DEBUG "ha\nhs";
   }
   
   if (@ARGV) {
     max_trace_depth shift;
   }
   
   if (@ARGV) {
     trace_file shift;
   }
   
   IN(my $f, 0);
   fo(4,5);
   
   DEBUG "done";
   
=head1 BUGS

For some reason, the closing lines are reversed in this example:

   use Devel::TraceFuncs;

   max_trace_depth -1;

   sub g {
     IN(my $f);
   }
 
   sub f {
     IN(my $f);
     g();
   }

   f();

What it boils down to is not letting I<IN> be the last line of a
function.  In the debugger, the objects are destructed in the correct
order, so this must be caused by some sort of performance optimization
in the perl runtime.

=head1 AUTHOR

Joe Hildebrand

  Copyright (c) 1996 Joe Hildebrand. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=head1 MODIFICATION HISTORY

Version 0.1, 1 Jun 1996

=cut
