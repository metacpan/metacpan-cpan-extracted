# $Id: DiskBufferMgr.pm,v 1.1.1.1 2002/06/14 20:40:09 grantm Exp $

package XML::Filter::Sort::DiskBufferMgr;

use strict;

require XML::Filter::Sort::BufferMgr;
require XML::Filter::Sort::DiskBuffer;

use IO::File;
use File::Spec;
use File::Path;
use File::Temp qw(tempdir);


##############################################################################
#                     G L O B A L   V A R I A B L E S
##############################################################################

use vars qw($VERSION @ISA);

$VERSION = '0.91';
@ISA     = qw(XML::Filter::Sort::BufferMgr);

use constant DEF_BUCKET_SIZE => 1024 * 1024 * 10;

use constant STREAM_FILENAME => 0;
use constant STREAM_FILENUM  => 1;
use constant STREAM_FILEDESC => 2;
use constant STREAM_BUFFER   => 3;
use constant STREAM_KEYS     => 4;


##############################################################################
#                             M E T H O D S
##############################################################################

##############################################################################
# Constructor: new()
#
# Extends base class constructor by adding tests for required options.
#

sub new {
  my $proto = shift;

  my $class = ref($proto) || $proto;
  my $self  = $class->SUPER::new(@_);


  # Check/clean up supplied options
  
  if(!ref($proto)  and  !$self->{TempDir}) {
    die "You must set the 'TempDir' option for disk buffering";
  }

  $self->{MaxMem} = DEF_BUCKET_SIZE unless($self->{MaxMem});


  # Initialise structures
  
  if($self->{TempDir}) {
    $self->{_temp_dir} = tempdir( DIR => $self->{TempDir});
    $self->{buffered_bytes} = 0;
  }

  return(bless($self,$class));
}


##############################################################################
# Destructor: DESTROY()
#
# Cleans up the temporary directory.
#

sub DESTROY {
  my $self = shift;

  return unless($self->{_temp_dir});

  rmtree($self->{_temp_dir});
}


############################################################################
# Method: new_buffer()
#
# Creates and returns an object for buffering a single record.
#

sub new_buffer {
  my $self = shift;

  my %opt = ( Keys => $self->{Keys} );
  if($self->{_match_subs}) {
    $opt{_match_subs} = [ @{$self->{_match_subs}} ];
  }
  return(XML::Filter::Sort::DiskBuffer->new(%opt));
}


##############################################################################
# Method: close_buffer()
#
# Takes a buffer, calls its close() method to get the frozen representation of
# the buffer and the list of sort key values.  Filters the key values and
# stores the frozen buffer using those values.  If the accumulated frozen
# buffers exceed the configured threshold, they will all be serialised out to
# a disk file.
#

sub close_buffer {
  my $self   = shift;
  my $record = shift;

  my @sort_keys = $record->close();
  @sort_keys = $self->fix_keys(@sort_keys);

  my $data = $record->freeze(undef, @sort_keys);

  $self->store($data, @sort_keys);

  $self->{buffered_bytes} += length($data);
  if($self->{buffered_bytes} >= $self->{MaxMem}) {
    $self->save_to_disk();
  }
}


##############################################################################
# Method: save_to_disk()
#
# Checks for buffered records.  If there are some, creates a disk file and 
# writes out the frozen buffers to it in sorted order.
#

sub save_to_disk {
  my $self = shift;
  my $fd   = shift;



  # Create the file if required
  
  unless($fd) {
    return unless($self->{buffered_bytes});

    $self->{files} = [ ] unless($self->{files});
    my $count = @{$self->{files}};
    my $filename = File::Spec->catfile($self->{_temp_dir}, $count);
    $fd = IO::File->new(">$filename") || 
      die "Error creating temporary file ($filename): $!";
    binmode($fd);
    $self->{files}->[$count] = $filename;
  }


  # Write out the records in sorted order

  my $keys = $self->sorted_keys();

  foreach my $key (@$keys) {
    if(ref($self->{records}->{$key}) eq 'ARRAY') {
      foreach my $record (@{$self->{records}->{$key}}) {
	$fd->print(pack('L', length($record)));
	$fd->print($record);
      }
    }
    else {   # it must be a XML::Filter::Sort::DiskBufferMgr
      $self->{records}->{$key}->save_to_disk($fd);
    }
  }

  $fd->close() if($self->{files});

  $self->{records} = {};
  $self->{buffered_bytes} = 0;

}


##############################################################################
# Method: to_sax()
#
# Streams buffered data back out as SAX events.
#

sub to_sax {
  my $self   = shift;
  my $filter = shift;

  $self->save_to_disk();   # OPTIMISATION: sax_from_mem if no $self->{files}

  while(@{$self->{files}}) {
    $self->prepare_merge();
    if(@{$self->{files}}) {
      $self->merge_to_disk();
    }
    else {
      $self->merge_to_sax($filter);
    }
  }

}


##############################################################################
# Method: merge_to_sax()
#
# Takes the record from the head of the list and writes it out as SAX events;
# takes the next record from that stream and repositions the stream in the 
# list; repeats until all streams empty.
#

sub merge_to_sax {
  my $self   = shift;
  my $filter = shift;

  while(my $stream = pop @{$self->{streams}}) {
    $stream->[STREAM_BUFFER]->to_sax($filter);
    $stream->[STREAM_BUFFER] = 
      XML::Filter::Sort::DiskBuffer->thaw($stream->[STREAM_FILEDESC]);
    if($stream->[STREAM_BUFFER]) {
      $stream->[STREAM_KEYS] = $stream->[STREAM_BUFFER]->key_values();
      $self->push_stream($stream);
    }
    else {
      $stream->[STREAM_FILEDESC]->close();
      unlink($stream->[STREAM_FILENAME]);
    }
  }

}


##############################################################################
# Method: prepare_merge()
#
# The merge process treats each temporary file as a 'stream' of records.  A
# linked list data structure (actually just an array - go Perl!) is used to
# keep track of the next available record from each stream.  This routine
# builds the linked list by opening each temp file, reading the first record 
# and 'pushing' the stream down into the list.  The record at the head of the
# list will be first against the wall when the revolution comes.
#

sub prepare_merge {
  my $self = shift;

  my $buffered_bytes = 0;

  while(@{$self->{files}}) {
    my $filename = shift @{$self->{files}};
    my($filenum) = ($filename =~ /(\d+)$/);
    my $fd = IO::File->new("<$filename") || 
      die "Error opening temporary file ($filename): $!";
    binmode($fd);
    my($buffer, $size) = XML::Filter::Sort::DiskBuffer->thaw($fd);
      die "Temporary file ($filename) unexpectedly empty" unless($buffer);
    my $keys = $buffer->key_values();

    $self->push_stream( [ $filename, $filenum, $fd, $buffer, $keys ] );

    $buffered_bytes += $size;
    if($buffered_bytes >= $self->{MaxMem}  and  @{$self->{streams}} > 1) {
      $self->merge_to_disk();
      $buffered_bytes = 0;
    }
  }

}


##############################################################################
# Method: merge_to_disk()
#
# This routine is called from prepare_merge() if there are too many temporary
# files to merge in one operation.  Merges records from all the currently open
# streams into a new temporary file and pushes the new filename onto the start
# of the list of files.
#

sub merge_to_disk {
  my $self   = shift;

  my $filename = File::Spec->catfile($self->{_temp_dir}, '0');
  my $fd = IO::File->new(">$filename.tmp") || 
    die "Error creating temporary file ($filename): $!";
  binmode($fd);

  while(my $stream = pop @{$self->{streams}}) {
    $stream->[STREAM_BUFFER]->freeze($fd);
    $stream->[STREAM_BUFFER] = 
      XML::Filter::Sort::DiskBuffer->thaw($stream->[STREAM_FILEDESC]);
    if($stream->[STREAM_BUFFER]) {
      $stream->[STREAM_KEYS] = $stream->[STREAM_BUFFER]->key_values();
      $self->push_stream($stream);
    }
    else {
      $stream->[STREAM_FILEDESC]->close();
      unlink($stream->[STREAM_FILENAME]);
    }
  }
  $fd->close();

  rename("$filename.tmp", $filename);

  unshift @{$self->{files}}, $filename;
}


##############################################################################
# Method: push_stream()
#
# Inserts a 'stream' at its proper position in the 'linked list'.
#

sub push_stream {
  my $self   = shift;
  my $stream = shift;


  # Create the list if it does not already exist;

  my $list = $self->{streams};
  unless($list) {
    $self->{streams} = [ $stream ];    # Create the 'linked list'
    return;
  }


  # Push this record in above an existing one ...

  for(my $i = @$list - 1; $i >= 0; $i--) {
    if($self->stream_cmp($stream, $list->[$i]) == -1) {
      splice @$list, $i, 1, $list->[$i], $stream;
      return;
    }
  }

  # ... or push it right down to the bottom
  
  unshift @$list, $stream;

}


##############################################################################
# Method: stream_cmp()
#
# Used by the merge process to determine the sort order of the buffers at the
# head of two streams.
# Returns -1 or 1 depending on which one sorts first.  (Never returns 0 since
# as a last resort, file numbers are compared to give a stable sort).
#

sub stream_cmp {
  my($self, $streama, $streamb) = @_;
  
  my $result;
  for(my $k = 0; $k < @{$streama->[STREAM_KEYS]}; $k++) {
    my $cmp = $self->{Keys}->[$k]->[1];
    my $dir = $self->{Keys}->[$k]->[2];

    my $a   = $streama->[STREAM_KEYS]->[$k];
    my $b   = $streamb->[STREAM_KEYS]->[$k];

    # coderef sort comparator

    if(ref($cmp)) {
      if($dir eq 'desc') {
	$result = $cmp->($b, $a) and return($result);
      }
      else {
	$result = $cmp->($a, $b) and return($result);
      }
    }
    
    # numeric comparator

    elsif($cmp eq 'num') {
      if($dir eq 'desc') {
	$result = ($b <=> $a) and return($result);
      }
      else {
	$result = ($a <=> $b) and return($result);
      }
    }

    # alpha comparator (default)

    else {
      if($dir eq 'desc') {
	$result = ($b cmp $a) and return($result);
      }
      else {
	$result = ($a cmp $b) and return($result);
      }
    }

  }

  # Fall through to file number to ensure a stable sort
  
  return($streama->[STREAM_FILENUM] <=> $streamb->[STREAM_FILENUM]);
}


1;

__END__

=head1 NAME

XML::Filter::Sort::DiskBufferMgr - Implementation class used by XML::Filter::Sort


=head1 DESCRIPTION

The documentation is targetted at developers wishing to extend or replace
this class.  For user documentation, see L<XML::Filter::Sort>.

For an overview of the classes and methods used for buffering, see
L<XML::Filter::Sort::BufferMgr>.

=head1 METHODS

This class inherits from B<XML::Filter::Sort::Buffer> and adds the following
methods:

...


=head1 COPYRIGHT 

Copyright 2002 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

