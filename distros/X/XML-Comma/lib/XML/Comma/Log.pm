##
#
#    Copyright 2001-2007, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Log;

use Fcntl ":flock";
use strict;

$XML::Comma::Log::warn_only = 0;

sub err {
  my ( $class, $error_name, $arg2, $doc_id, $extra_text ) = @_;
  my ( $file, $line, $internal_eval, $caller_eval ) = $class->external_caller();
  if ( ref($arg2) eq 'XML::Comma::Err' ) {
    my $str = $arg2->info_string_full();
    $str .= " - $extra_text"  if  $extra_text;
    my $error = XML::Comma::Err->new 
      ( err_name => "$error_name/".$arg2->{_err_name},
        info_string => $str,
        file   => $arg2->{_file},
        line   => $arg2->{_line},
        doc_id => $doc_id );
    $class->log ( $error->to_string() )  unless  $internal_eval || $caller_eval;
    die $error;
  } else {
    chomp $arg2;
    my $str = $arg2;
    $str .= " - $extra_text"  if  $extra_text;
    my $error = XML::Comma::Err->new ( err_name => $error_name,
                                       info_string => $str,
                                       file    => $file,
                                       line    => $line,
                                       doc_id  => $doc_id );
    $class->log ( $error->to_string() )  unless $internal_eval || $caller_eval;
    die $error;
  }
}


# usage: XML::Comma::Log->warn ( $string );
sub warn {
  my $msg = $_[1];
  chomp $msg;
  #print STDERR "$msg\n";
  $_[0]->log ( "WARNING -- $msg" );
}


sub log {
  my $string = $_[1];
  chomp $string;
  $string =~ s/\n/ /g;
  if ($XML::Comma::Log::warn_only) { CORE::warn $string; return; }
  {
    my $log;
    unless ( open( $log, "+>>", XML::Comma->log_file() ) ) {
      print STDERR "Can't open comma logfile:" . XML::Comma->log_file().
        " ($@ $!), error follows: " . time() . "$$ $string\n";
      return;
    }
    my $flock_warning = "";
    unless(flock($log, LOCK_EX)) {
      $flock_warning = "FLOCK NOT AVAILABLE, LOG MAY BE INCOMPLETE OR CORRUPTED";
    }
    seek($log, 0, 2); #seek to EOF in case someone appended while we waited
    print $log "$flock_warning\n" if($flock_warning);
    print $log scalar localtime() . ": $$ $string\n";
    # note close() makes an implicit funlock()
    close($log) || print STDERR "$$ can't close log file at ".time.", other procs may block forever \""
      . XML::Comma->log_file() . "\": $!";
  }
  #`echo "${\( time() )} $$ $string" >> ${ \( XML::Comma->log_file() ) }`;
}


##
# first, look for the first stackframe caller that is not an
# XML::Comma package. then, look all the way up the stack to see if
# any of the $subroutine entries in the stack from are "(eval)". return
# a list: ( file, line, internal_eval_boolean, external_eval_boolean )
##
sub external_caller {
  my ( $caller_file, $caller_line, $internal_eval, $caller_eval );
  my $i = 0;
  my ( $package, $filename, $line, $subroutine,
       $hasargs, $wantarray, $evaltext, $is_require ) = caller($i++);
  while ( $package ) {
    # print "$package -- $filename -- $line -- $subroutine -- $evaltext\n";
    # print "CONTEXT: $package -- $line\n";
    # first external caller?
    if ( (! $caller_file) and ($package !~ /^XML::Comma/) ) {
      $caller_file = $filename;
      $caller_line = $line;
    }
    # eval in internal part of stacktrace?
    if ( (! $caller_file) and $subroutine eq '(eval)' )  {
      $internal_eval = 1;
    }
    # eval in external part of stacktrace?
    if ( $caller_file and $subroutine eq '(eval)' )  {
      $caller_eval = 1;
      last;
    }
    ( $package, $filename, $line, $subroutine,
      $hasargs, $wantarray, $evaltext, $is_require ) = caller($i++);
  }
  return  ( $caller_file, $caller_line, $internal_eval, $caller_eval );
}


package XML::Comma::Err;
use strict;
use overload q("") => \&to_string;

sub new {
  my ( $class, %arg ) = @_;
  my $self = {}; bless ( $self, $class );
  $self->{_err_name} = $arg{err_name};
  $self->{_info_string} = $arg{info_string};
  $self->{_file} = $arg{file};
  $self->{_line} = $arg{line};
  $self->{_doc_id} = $arg{doc_id};
  return $self;
}

sub error_name {
  return $_[0]->{_err_name};
}

sub info_string_full {
  return $_[0]->{_info_string};
}

# for use in the context of MASON, which adds a bunch of lines to the
# error string, this returns only the first line. if you need the
# whole thing, for some reason, use info_string_full().
sub info_string {
  if ( my $eol = index($_[0]->{_info_string},"\n") ) {
    return substr ( $_[0]->{_info_string}, 0, $eol );
  } else {
    return $_[0]->{_info_string};
  }
}

sub file {
  return $_[0]->{_file};
}

sub line {
  return $_[0]->{_line};
}

sub to_string {
  my $self = shift();
  return $self->{_err_name} .
    ( $self->{_doc_id} ? ' (' . $self->{_doc_id} . ')' : '' ) .
    ' -- ' . $self->{_info_string} .
    ' at ' .  $self->{_file} .  ' line ' .  $self->{_line} . "\n";
}

1;
