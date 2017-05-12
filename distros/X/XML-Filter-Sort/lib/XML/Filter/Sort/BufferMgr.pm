# $Id: BufferMgr.pm,v 1.1.1.1 2002/06/14 20:40:05 grantm Exp $

package XML::Filter::Sort::BufferMgr;

use strict;

require XML::Filter::Sort::Buffer;


##############################################################################
#                     G L O B A L   V A R I A B L E S
##############################################################################

use vars qw($VERSION);

$VERSION = '0.91';


##############################################################################
#                             M E T H O D S
##############################################################################

##############################################################################
# Constructor: new()
#
# Allocates in-memory structures for buffering records.
#

sub new {
  my $proto = shift;

  my $class = ref($proto) || $proto;

  my $self = { @_ };
  $self->{records} = {};
  
  return(bless($self, $class));
}


##############################################################################
# Method: compile_matches()
#
# Returns a list of closures for matching each of the sort keys.
#

sub compile_matches {
  my $self = shift;

  return(XML::Filter::Sort::Buffer->compile_matches(@_));
}


##############################################################################
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
  return(XML::Filter::Sort::Buffer->new(%opt));
}


##############################################################################
# Method: close_buffer()
#
# Takes a buffer, calls its close() method to get the sort key values, filters
# the key values and stores the buffer using those values.
#

sub close_buffer {
  my $self   = shift;
  my $record = shift;

  my @sort_keys = $record->close();

  @sort_keys = $self->fix_keys(@sort_keys);

  $self->store($record, @sort_keys);
}


##############################################################################
# Method: fix_keys()
#
# Takes a list of sort key values and applies various fixes/cleanups to them.
#

sub fix_keys {
  my $self   = shift;

  my @sort_keys = @_;

  if($self->{IgnoreCase}) {
    @sort_keys = map { lc($_) } @sort_keys;
  }

  if($self->{NormaliseKeySpace}) {
    foreach (@sort_keys) {
      s/^\s+//s;
      s/\s+$//s;
      s/\s+/ /sg;
    }
  }

  if($self->{KeyFilterSub}) {
    @sort_keys = $self->{KeyFilterSub}->(@sort_keys);
  }
  
  return(@sort_keys);
}


##############################################################################
# Method: store()
#
# Takes a buffer, and a series of key values.  Stores the buffer using those
# values.
#

sub store {
  my $self   = shift;
  my $record = shift;
  my $key    = shift;

  if(@_) {
    unless($self->{records}->{$key}) {
      my @key_defs = @{$self->{Keys}};
      shift @key_defs;
      $self->{records}->{$key} = $self->new(Keys => \@key_defs);
    }
    $self->{records}->{$key}->store($record, @_);
  }
  else {
    unless($self->{records}->{$key}) {
      $self->{records}->{$key} = [];
    }
    push @{$self->{records}->{$key}}, $record;
  }

}


##############################################################################
# Method: to_sax()
#
# Takes a reference to the parent XML::Filter::Sort object.  Cycles through
# each of the buffered records (in appropriate sorted sequence) and streams
# them out to the handler object as SAX events.
#

sub to_sax {
  my $self   = shift;
  my $filter = shift;

  my $keys = $self->sorted_keys();

  foreach my $key (@$keys) {
    if(ref($self->{records}->{$key}) eq 'ARRAY') {
      foreach my $record (@{$self->{records}->{$key}}) {
	$record->to_sax($filter);
      }
    }
    else {
      $self->{records}->{$key}->to_sax($filter);
    }
  }

}


##############################################################################
# Method: sorted_keys()
#
# Returns a reference to an array of all the sort keys in order.
#

sub sorted_keys {
  my $self   = shift;

  my @keys = keys(%{$self->{records}});
  my $cmp = $self->{Keys}->[0]->[1];
  my $dir = $self->{Keys}->[0]->[2];

  # coderef sort comparator
  
  if(ref($cmp)) {
    if($dir eq 'desc') {
      @keys = sort { $cmp->($b, $a) } @keys;
    }
    else {
      @keys = sort { $cmp->($a, $b) } @keys;
    }
  }

  # numeric comparator
  
  elsif($cmp eq 'num') {
    if($dir eq 'desc') {
      @keys = sort { $b <=> $a } @keys;
    }
    else {
      @keys = sort { $a <=> $b } @keys;
    }
  }

  # alpha comparator (default)

  else {
    if($dir eq 'desc') {
      @keys = sort { $b cmp $a } @keys;
    }
    else {
      @keys = sort { $a cmp $b } @keys;
    }
  }

  return(\@keys);

}


1;

__END__


=head1 NAME

XML::Filter::Sort::BufferMgr - Implementation class used by XML::Filter::Sort


=head1 DESCRIPTION

The documentation is targetted at developers wishing to extend or replace
this class.  For user documentation, see L<XML::Filter::Sort>.

Two classes are used to implement buffering records and spooling them back out
in sorted order as SAX events.  One instance of the
B<XML::Filter::Sort::Buffer> class is used to buffer each record and one or
more instances of the B<XML::Filter::Sort::BufferMgr> class are used to manage
the buffers.

=head1 API METHODS

The API of this module as used by B<XML::Filter::Sort::Buffer> consists of
the following sequence of method calls:

=over 4

=item 1

When the first 'record' in a sequence is encountered, B<XML::Filter::Sort>
creates a B<XML::Filter::Sort::BufferMgr> object using the C<new()> method.

=item 2

B<XML::Filter::Sort> calls the buffer manager's C<new_buffer()> method to get a
B<XML::Filter::Sort::Buffer> object and all SAX events are directed to this
object until the end of the record is encountered.  The following events are
supported by the current buffer implementation:

  start_element()
  characters()
  comment()
  processing_instruction()
  end_element()

=item 3

When the end of the record is detected, B<XML::Filter::Sort> calls the buffer
manager's C<close_buffer()> method, which in turn calls the buffer's C<close()>
method.  The C<close()> method returns a list of values for the sort keys and
the buffer manager uses these to store the buffer for later recall.  Subsequent
records are handled as per step 2.

=item 4

When the last record has been buffered, B<XML::Filter::Sort> 
calls the buffer manager's C<to_sax()> method.  The buffer manager retrieves
each of the buffers in sorted order and calls the buffer's C<to_sax()> method.

=back

Each buffer attempts to match the sort key paths as SAX events are received.
Once a value has been found for a given key, that same path match is not
attempted against subsequent events.  For efficiency, the code to match each
key is compiled into a closure.  For even more efficiency, this compilation is
done once when the B<XML::Filter::Sort> object is created.  The
C<compile_matches()> method in the buffer manager class calls the
C<compile_matches()> method in the buffer class to achieve this.

=head1 DATA STRUCTURES

In the current implementation, the B<XML::Filter::Sort::BufferMgr> class simply
uses a hash to store the buffer objects.  If only one sort key was defined,
only a single hash is required.  The values in the hash are arrayrefs
containing the list of buffers for records with identical keys.

If two or more sort keys are defined, the hash values will be
B<XML::Filter::Sort::BufferMgr> objects which in turn will contain the buffers.
The following illustration may clarify the relationship (BM=buffer manager,
B=buffer):

                                 BM
                 +----------------+---------------+
                 |                                |
                BM                               BM
	   +-----+--------+                 +-----+----------+
	   |              |                 |                |
          BM             BM                BM               BM
     +-----+----+    +----+------+     +----+----+    +------+------+
     |     |    |    |    |      |     |    |    |    |      |      |
  [B,B,B] [B] [B,B] [B] [B,B] [B,B,B] [B] [B,B] [B] [B,B] [B,B,B] [B,B]

This layered storage structure is transparent to the B<XML::Filter::Sort>
object which instantiates and interacts with only one buffer manager (the one
at the top of the tree).

=head1 COPYRIGHT 

Copyright 2002 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut


