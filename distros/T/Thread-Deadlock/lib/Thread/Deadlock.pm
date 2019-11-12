package Thread::Deadlock;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.07';
use strict;

# Make sure we only load stuff when we actually need it

use load;

# Make sure we have threads
# Make sure we can lock
# Make sure signals will have END executed

use threads;
use threads::shared ();
use sigtrap qw(die normal-signals);

# Make sure we can cluck
# Initialize thread local hi-jacked flag
# Initialize output destination
# Report from each thread

use Carp ();
my $hijacked;
our $output : shared = 'STDERR';
our %report : shared;

# Initialize summary setting
# Initialize callers setting
# Initialize shorten setting
# Initialize format
# Initialize XML encoding

our $summary  : shared = 'auto';
our $callers  : shared = 4;
our $shorten  : shared = 1;
our $format   : shared = 'plain';
our $encoding : shared = 'iso-latin-1';

# Initialize trace setting
# Initialize thread local handle for writing trace

our $trace    : shared;
my $tracehandle;

# Save current coderefs

our $cond_wait      = \&threads::shared::cond_wait;
our $cond_signal    = \&threads::shared::cond_signal;
our $cond_broadcast = \&threads::shared::cond_broadcast;

# Make sure we don't get warnings for the hijacking
# Install hi-jacked coderefs, we can't do lock() yet ;-(

{
 no warnings 'redefine';
 *threads::shared::cond_wait =
  sub (\[$@%]) { _remember( 'cond_wait()' ); goto &$cond_wait };
 *threads::shared::cond_signal =
  sub (\[$@%]) { _remember( 'cond_signal()' ); goto &$cond_signal };
 *threads::shared::cond_broadcast =
  sub (\[$@%]) { _remember( 'cond_broadcast()' ); goto &$cond_broadcast };
}

# Create match string for paths
# Make a regular exprssion of it

our $paths = join( '/|',sort {length($b) - length($a)} @INC ).'/';
$paths = qr#(?<= at )(?:$paths)#;

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# routines for standard perl features

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 output filename (optional)
# or:
#  IN: 1 class
#      2..N method/value hash

sub import {

# Switch on reporting
# Handle simple output specification if so

    on();
    goto &output if @_ == 2;

# Get the parameter hash
# For all of the methods and values
#  Die now if invalid method
#  Call the method with the value

    my ($class,%param) = @_;
    while (my ($method,$value) = each %param) {
	die "Cannot call method $method during initialization\n"
	 unless $method =~
	  m#^(?:callers|encoding|format|output|shorten|summary|trace)$#;
        $class->$method( $value );
    }
} #import

#---------------------------------------------------------------------------

END {

# Attempt to lock the report flag
# Return now if we don't need to report

    lock( $output );
    return unless $output;

# Allow variable specifications
# Tell the world what it is
# Indicate that no-one else needs to report

    no strict 'refs';
    print {_handle( $output )} &{'_'.$format};
    $output = '';
} #END

#---------------------------------------------------------------------------

# load takes over from here

__END__

#---------------------------------------------------------------------------

# class methods

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)

sub on { $hijacked = 1 } #on

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)

sub off { $hijacked = 0 } #off

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new summary setting
# OUT: 1 current summary setting

sub summary {

# If a new setting is specified
#  Die now if invalid parameter
#  Set new parameter
# Return current setting

    if (@_ == 2) {
        die "Invalid parameter $_[1] to summary\n"
	 unless $_[1] =~ m#^(?:auto|0|1)$#;
        $summary = $_[1];
    }
    $summary;
} #summary

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new callers setting
# OUT: 1 current callers setting

sub callers {

# If a new setting is specified
#  Die now if invalid parameter
#  Set new parameter
# Return current setting

    if (@_ == 2) {
        die "Invalid parameter $_[1] to callers\n" unless $_[1] =~ m#^\d+$#;
        $callers = $_[1];
    }
    $callers;
} #callers

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new shorten setting
# OUT: 1 current shorten setting

sub shorten {

# Set if a new setting is specified
# Return current setting

    $shorten = $_[1] if @_ == 2;
    $shorten;
} #shorten

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new format setting
# OUT: 1 current format setting

sub format {

# If a new setting is specified
#  Die now if invalid parameter
#  Set new parameter
# Return current setting

    if (@_ == 2) {
        die "Invalid parameter $_[1] to summary\n"
	 unless $_[1] =~ m#^(?:plain|xml)$#;
        $format = $_[1];
    }
    $format;
} #format

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new encoding setting
# OUT: 1 current encoding setting

sub encoding {

# Set if a new setting is specified
# Return current setting

    $encoding = $_[1] if @_ == 2;
    $encoding;
} #encoding

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
# OUT: 1 generated report

sub report {

# Allow for non variable references
# Create a report and return it

    no strict 'refs';
    join( '',&{'_'.$format} );
} #report

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 name of file to write to (no change)
# OUT: 1 current setting

sub output { $output = $_[1] if @_ >1; $output } #output

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)

sub disable { $output = '' } #disable

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 name of file to write to (no change)
# OUT: 1 current setting

sub trace { $trace = $_[1] if @_ >1; $trace } #trace

#---------------------------------------------------------------------------

# internal routines

#---------------------------------------------------------------------------
#  IN: 1 what we're remembering

sub _remember {

# Return now if there is nothing to do

    return unless $hijacked;

# Obtain the thread we're in
# Obtain the stacktrace
# Remove this call
# Add what we're remembering

    my $tid = threads->tid;
    my @cluck = split( m#(?<=$/)#,Carp::longmess() );
    shift( @cluck );
    $cluck[0] =~ s#.*?called#shift#e;

# If we're tracing
#  Obtain handle if there is no handle yet
#  Create local copy of trace line
#  Shorten it if so specified
#  Write the trace to the file
# Elseif we have a trace handle (but we stopped tracing)
#  Close the handle and mark as unused again

    if ($trace) {
        $tracehandle ||= _handle( $trace,'>>' );
	my $line = $cluck[0];
	$line =~ s#$paths## if $shorten;
	print {$tracehandle} "$tid: $line";
    } elsif ($tracehandle) {
        undef( $tracehandle );
    }

# Create a hash with valid tid's (include main thread, which is not in list)
# For all of the keys in the report hash
#  Remove this thread's report if the thread is dead
# Save the report of this thread

    my %tid = (0,1),map {$_->tid,1} threads->list;
    while (my $tid = each( %report )) {
        delete( $report{$tid} ) unless exists $tid{$tid};
    }
    $report{$tid} = join( "\0",@cluck );
} #_remember

#---------------------------------------------------------------------------
# OUT: 1 generated report in plain text
#      2..N stack dump

sub _plain {

# Tell the world what it is
# Obtain frequency and dump list references

    my $text = '*** '.__PACKAGE__." report ***\n";
    my ($at,$dump,$tid) = _dump();

# If we have any information
#  If we're to do the summary
#   Show all different locations
#   And add a divider
# Else (no information)
#  Add some explanation

    if (@$tid) {
        if ($summary eq 'auto' ? (keys %$at < keys %report) : $summary) {
            $text .= "$at->{$_} x $_" foreach sort keys %$at;
            $text .= "\n";
        }
    } else {
        $text .= "(no information found)\n";
    }

# Return the final report plus the dump

    $text,map {"#$_: ".join('',@{$dump->{$_}})."\n"} @$tid;
} #_plain

#---------------------------------------------------------------------------
# OUT: 1 generated report in XML

sub _xml {

# Tell the world what it is
# Obtain frequency and dump list references

    my $xml = <<EOD;
<?xml version="1.0" encoding="$encoding"?>
<report version="1.0">
EOD
    my ($at,$dump,$tid) = _dump();

# If we're to do the summary
#  Show all different locations

    if ($summary eq 'auto' ? (keys %$at < keys %report) : $summary) {
        $xml .= <<EOD;
 <summary>
EOD
        $xml .= <<EOD foreach sort keys %$at;
  <location frequency="$at->{$_}">$_</location>"
EOD
        $xml .= <<EOD;
 </summary>
EOD
    }

# For all of the thread id's
#  Add the XML for this thread

    foreach (@$tid) {
        $xml .= <<EOD;
 <thread id="$_">
EOD
        chomp( my @line = @{$dump->{$_}} );
	s#^\s+## foreach @line;
        $xml .= <<EOD foreach @line;
  <at>$_</at>
EOD
        $xml .= <<EOD;
 </thread>
EOD
    }

# Return the final report plus the dump

    "$xml</report>";
} #_xml

#---------------------------------------------------------------------------
# OUT: 1 reference to hash with frequencies
#      2 reference to hash with list references of dump
#      3 reference to list with keys (thread id's) in dump hash

sub _dump {

# Initialize the thread id list
# Initialize the at hash
# Initialize the dump hash

    my @tid;
    my %at;
    my %dump;

# For all of the threads still running
#  Make a list again
#  If we should shorten stuff
#   Shorten the package name
#   Remove (autosplit...) reference (don't need that usually)

    foreach (@tid = sort {$a <=> $b} keys %report) {
        my @cluck = split( "\0",$report{$_} );
        if ($shorten) {
            foreach (@cluck) {
                s#$paths##;
                s# \(autosplit(?:[^)]+)\)##;
            }
        }

#  Count the first list
#  Indicate start of thread if appropriate

        $at{$cluck[0]}++;
        $cluck[-1] =~ s#eval \{\.\.\.\} called#thread started#;

#  Shorten list of callers if so specified
#  Remove the thread information (if any)
#  Add these lines to the dump

        splice( @cluck,$callers ) if $callers;
        s/, thread #(\d+)$// foreach @cluck;
        $dump{$_} = \@cluck;
    }

# Return references to stuff we made here

    return \%at,\%dump,\@tid;
} #_dump

#---------------------------------------------------------------------------
#  IN: 1 output specification
#      2 open mode (default: '>')
# OUT: 1 opened handle

sub _handle {

# Obtain the output specification
# Obtain open mode
# Initialize handle to write to

    my $filename = shift;
    my $mode = shift || '>';
    my $handle;

# If we have the default value
#  Set to write to standard error
# Elseif we just want to print
#  Set to write to standard output

    if ($filename eq 'STDERR') {
        $handle = *STDERR;
    } elsif ($filename eq 'STDOUT') {
        $handle = *STDOUT;

# Elseif successful in opening it as a file (no action)
# Else (not successful in opening file)
#  Set to use standard error
#  And let the world know why

    } elsif (open( $handle,$mode,$filename )) {
    } else {
        $handle = *STDERR;
	print $handle <<EOD;
Could not report to $filename ($!)
Writing to STDERR instead
EOD
    }

# Return the resulting handle

    $handle;
} #_handle

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Deadlock - report deadlocks with stacktrace

=head1 SYNOPSIS

  perl -MThread::Deadlock program          # report to STDERR
  perl -MThread::Deadlock=filename program # report to file

  use Thread::Deadlock;                    # report to STDERR
  use Thread::Deadlock 'filename';         # report to file
  use Thread::Deadlock ();                 # set up, need on() later

  use Thread::Deadlock (                   # call class methods easily
   summary  => 'auto',
   callers  => 4,
   shorten  => 1,
   format   => 'plain',
   encoding => 'iso-latin-1',
   output   => 'STDERR',
   trace    => undef,
  );

  Thread::Deadlock->summary( 'auto' );       # default, automatic
  Thread::Deadlock->summary( 0 );            # don't do summary
  Thread::Deadlock->summary( 1 );            # do summary always

  Thread::Deadlock->callers( 4 );            # default, show 4 lines in dump
  Thread::Deadlock->callers( 0 );            # show all lines in dump

  Thread::Deadlock->shorten( 1 );            # default: shorten package names
  Thread::Deadlock->shorten( 0 );            # do not shorten package names

  Thread::Deadlock->format( 'plain' );       # default, plain text format
  Thread::Deadlock->format( 'xml' );         # set XML format
  Thread::Deadlock->encoding('iso-latin-1'); # only needed for XML format

  Thread::Deadlock->off;                     # disable in this thread
  Thread::Deadlock->on;                      # enable again in this thread

  $report = Thread::Deadlock->report;        # return intermediate report

  Thread::Deadlock->output( 'filename' );    # report to file
  Thread::Deadlock->disable;                 # disable report

  Thread::Deadlock->trace( 'filename' );     # start tracing to file
  Thread::Deadlock->untrace;                 # stop tracing (default)

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.  It
 is of no use with any version of Perl before 5.8.0 or without
 threads enabled.

                  *************************

The Thread::Deadlock module allows you to find out B<where> your threaded
application may be deadlocked.  It does B<not> prevent any deadlocks, nor is
it capable of resolving any deadlocks.

If you use the Thread::Deadlock module, all occurences of cond_wait(),
cond_signal() and cond_broadcast() in the source are checkpointed to
remember where it was exactly in your source and where it was in the execution
stack.  When your program finishes (either as intended or after you killed the
program, e.g. by pressing Control-C), then a report will be generated for each
thread, indicating where each thread had its last checkpoint.  By default, this
report is written to STDERR, but can be redirected to a file of your choice.

On top of this, it is also possible to have a trace generated of each time
a cond_wait(), cond_signal() or cond_broadcast() was called.  This may give
additional information as to how a problem such as a deadlock, can occur.

=head1 CLASS METHODS

There are only class methods.  The class methods L<summary>, L<callers>,
L<shorten>, L<format>, L<encoding>, L<output> and L<trace> methods can also
be called as fields in a parameter hash with C<use>.

=head2 on

 Thread::Deadlock->on;

The "on" class method switches reporting B<on> for the current thread and any
threads that are created from this thread.

=head2 off

 Thread::Deadlock->off;

The "off" class method switches reporting B<off> for the current thread and
any threads that are created from this thread.

=head2 summary

 Thread::Deadlock->summary( 'auto' );  # default, automatic

 Thread::Deadlock->summary( 0 );       # don't do summary

 Thread::Deadlock->summary( 1 );       # always do summary

 $summary = Thread::Deadlock->summary;

The "summary" class method sets and returns whether a thread summary will be
added to the report.  By default, a summary will be added if there are at least
two threads at the same location in the source.

=head2 callers

 Thread::Deadlock->callers( 4 );       # default, return 4 callers
 
 Thread::Deadlock->callers( 0 );       # return all callers

 $callers = Thread::Deadlock->callers;

The "callers" class method sets and returns the number of callers that should
be shown in the report.  By default, only 4 callers will be shown.

=head2 shorten

 Thread::Deadlock->shorten( 1 );       # default, shorten
 
 Thread::Deadlock->shorten( 0 );       # do not shorten package names

 $shorten = Thread::Deadlock->shorten;

The "shorten" class method sets and returns whether package names should be
shortened in the dump.  By default, package names will be shortened, to create
a more readable report.

=head2 format

 Thread::Deadlock->format( 'plain' );  # default, make plain text report

 Thread::Deadlock->format( 'xml' );    # make xml report

 $format = Thread::Deadlock->format;

The "format" class method sets and returns the format in which the report
will be generated.  By default, the report will be created in plain text.
If you select 'xml', you may want to change the L<encoding> setting of the
XML that will be generated.

=head2 encoding

 Thread::Deadlock->encoding( 'iso-latin-1' );  # default

 $encoding = Thread::Deadlock->encoding;

The "encoding" class method sets and returns the encoding in which the report
will be generated if B<xml> was selected as the L<format>.  By default, the
report will be created in 'ISO-Latin-1' encoding.
 
=head2 report

 $report = Thread::Deadlock->report;

The "report" class method returns the report that is otherwise automatically
created when the program finishes.  It can be used for creation of
intermediate reports.  It can be called by _any_ thread.

=head2 output

 Thread::Deadlock->output( 'filename' );  # write to specific file

 $output = Thread::Deadlock->output;      # obtain current setting

The "output" class method returns the current setting for the thread
checkpoint report.  It can also be used to set the name of the file to which
the report will be written.  Call L<disable> to disable reporting.

The strings "STDOUT" and "STDERR" can be used to indicate standard output and
standard error respectively.

=head2 disable

 Thread::Deadlock->disable;

The "disable" class method disables reporting altogether.  This can be handy
if your program has completed successfully and you're not interested in a
report.

=head2 trace

 Thread::Deadlock->trace( 'filename');    # start tracing to specific file

 $trace = Thread::Deadlock->trace;

The "trace" class method sets and returns the filename to which a trace will
be appended.  By default, no tracing occurs in which case C<undef> will be
returned.  Call L<untrace> to disable tracing for B<all> threads.

The strings "STDOUT" and "STDERR" can be used to indicate standard output and
standard error respectively.

=head2 disable

 Thread::Deadlock->untrace;

The "untrace" class method disables tracing for B<all> threads.  This can be
handy if there are sections in your program that you do not want to have
traced.

=head1 REQUIRED MODULES

 load (any)

=head1 OPTIMIZATIONS

This module uses L<load> to reduce memory and CPU usage. This causes
subroutines only to be compiled in a thread when they are actually needed at
the expense of more CPU when they need to be compiled.  Simple benchmarks
however revealed that the overhead of the compiling single routines is not
much more (and sometimes a lot less) than the overhead of cloning a Perl
interpreter with a lot of subroutines pre-loaded.

=head1 CAVEATS

This module was originally conceived as hi-jacking the core lock() function.
However, this proved to be impossible, at least with Perl 5.8.0.  It was
therefore re-written to hi-jack the cond_wait(), cond_signal() and
cond_broadcast() routines from threads::shared.pm.  This is not exactly the
same, but since most deadlocking problems are caused by mixups of cond_wait()
and cond_signal()/cond_broadcast(), this seems to be as good a solution.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>, L<threads::shared>, L<load>.

=cut
