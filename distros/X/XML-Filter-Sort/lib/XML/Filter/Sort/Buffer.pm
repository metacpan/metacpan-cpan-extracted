# $Id: Buffer.pm,v 1.2 2005/04/20 20:04:34 grantm Exp $

package XML::Filter::Sort::Buffer;

use strict;

##############################################################################
#                     G L O B A L   V A R I A B L E S
##############################################################################

use vars qw($VERSION @ISA);

$VERSION = '0.91';

use constant NODE_TYPE    => 0;
use constant NODE_DATA    => 1;
use constant NODE_CONTENT => 2;


##############################################################################
#                             M E T H O D S
##############################################################################

##############################################################################
# Contructor: new()
#
# Prepare to build a tree and match nodes against patterns to extract sort
# key values.
#

sub new {
  my $class = shift;

  my $self = { @_, };
  bless($self, $class);


  # Prepare to match sort key nodes

  $self->{Keys}        ||= [ [ '.' ] ];
  $self->{_match_subs} ||= [ $self->compile_matches($self->{Keys}) ];

  $self->{_key_values}   = [ ('') x @{$self->{Keys}} ];

  $self->{_path_name}    = [];
  $self->{_path_ns}      = [];
  $self->{_depth}        = -1;


  # Initialise tree building structures
  
  $self->{tree}          = [];
  $self->{_lists}        = [];
  $self->{_curr_list}    = $self->{tree};

  return($self);

}


##############################################################################
# Class Method: compile_matches()
#
# Generates a closure to match each of the supplied sort keys.  Returns a
# list of closures.
#

sub compile_matches {
  my $class   = shift;
  my $keys    = shift;

  my @match_subs = ();

  foreach my $i (0..$#{$keys}) {
    my $key_num = $i;                    # local copy for closure

    my($pattern, $comparison, $direction) = @{$keys->[$key_num]};
    my($path, $attr) = split(/\@/, $pattern);
    my $abs = ($path =~ m{^\.});

    $path =~ s{^\.?/*}{};
    $path =~ s{/*$}{};
    my @name_list = ();
    my @ns_list   = ();
    foreach (split(/\//, $path)) {
      my($ns, $name) = m/^(?:\{(.*?)\})?(.*)$/;
      push @name_list, $name;
      push @ns_list, $ns;
    };

    my $required_depth = @name_list;

    my($attr_name, $attr_nsname);
    if($attr  and  $attr =~ m/^(\{.*?\})?(.*)$/ ) {
      $attr_name = $2;
      if($1) {
	$attr_nsname = $attr;
      }
    }

    # Closure which matches the path

    push @match_subs, sub {
      my $self = shift;

      if($abs) {
	return if($self->{_depth} != $required_depth);
      }
      else {
	return if($self->{_depth} < $required_depth);
      }

      foreach my $i (1..$required_depth) {
	return unless($self->{_path_name}->[-$i] eq $name_list[-$i]);
	if(defined($ns_list[-$i])) {
	  return unless($self->{_path_ns}->[-$i] eq $ns_list[-$i]);
	}
      }

      return $self->save_key_value($key_num, $attr_name, $attr_nsname);
    };

  }

  return(@match_subs);
}


##############################################################################
# Method: save_key_value()
#
# Once a match has been found, the matching closure will call this method to 
# extract the key value and save it.  Returns true to indicate the reference 
# to the closure can be deleted since there is no need to try and match the
# same pattern again.
#

sub save_key_value {
  my($self, $key_num, $attr_name, $attr_nsname) = @_;


  # Locate the element whose end event we're processing (ie: the element
  # which owns the content list we're about to close)
  
  my $node = $self->{_lists}->[-1]->[-1];


  # Extract the appropriate value

  if($attr_name) {
    my $value = undef;
    if(defined($attr_nsname)) {
      if(exists($node->[NODE_DATA]->{Attributes}->{$attr_nsname})) {
        $value = $node->[NODE_DATA]->{Attributes}->{$attr_nsname}->{Value};
      }
    }
    else {
      foreach my $attr (values %{$node->[NODE_DATA]->{Attributes}}) {
        if($attr->{LocalName} eq $attr_name) {
	  $value = $attr->{Value};
	  last;
	}
      }
    }
    return unless(defined($value)); # keep looking for elem with rqd attr
    $self->{_key_values}->[$key_num] = $value;
  }
  else {
    $self->{_key_values}->[$key_num] =
      $self->text_content(@{$node->[NODE_CONTENT]});
  }

  return(1);

}


##############################################################################
# Method: text_content()
#
# Takes a list of nodes and recursively builds up a string containing the
# text content.
#

sub text_content {
  my $self = shift;

  my $text = '';

  while(@_) {
    my $node = shift;
    if(ref($node)) {
      if($node->[NODE_TYPE] eq 'e') {
	if(@{$node->[NODE_CONTENT]}) {
	  $text .= $self->text_content(@{$node->[NODE_CONTENT]})
	}
      }
    }
    else {
      $text .= $node;
    }
  }

  return($text);
  
}


##############################################################################
# Method: close()
#
# Called by the buffer manager to signify that the record is complete.
#

sub close {
  my $self = shift;

  my @key_values = @{$self->{_key_values}};
  foreach my $key (grep(/^_/, keys(%$self))) {
    delete($self->{$key});
  }

  return(@key_values);
}


##############################################################################
# Method: to_sax()
#
# Takes a reference to the parent XML::Filter::Sort object and a list of node
# structures.  Passes each node to the handler as SAX events, recursing into
# nodes as required.  On initial call, node list will default to top of stored
# tree.
#

sub to_sax {
  my $self   = shift;
  my $filter = shift;

  @_ = @{$self->{tree}} unless(@_);

  while(@_) {
    my $node = shift;
    if(ref($node)) {
      if($node->[NODE_TYPE] eq 'e') {
	$filter->start_element($node->[NODE_DATA]);
	if(@{$node->[NODE_CONTENT]}) {
	  $self->to_sax($filter, @{$node->[NODE_CONTENT]})
	}
	$filter->end_element($node->[NODE_DATA]);
      }
      elsif($node->[NODE_TYPE] eq 'p') {
	$filter->processing_instruction($node->[NODE_DATA]);
      }
      elsif($node->[NODE_TYPE] eq 'c') {
	$filter->comment($node->[NODE_DATA]);
      }
      else {
	die "Unhandled node type: '" . $node->[NODE_TYPE] . "'";
      }
    }
    else {
      $filter->characters( { Data => $node } );
    }
  }

}


##############################################################################
# SAX handlers to build buffered event tree
##############################################################################

sub start_element {
  my($self, $elem) = @_;
  
  $self->{_depth}++;
  if($self->{_depth} > 0) {
    push @{$self->{_path_name}}, $elem->{LocalName};
    push @{$self->{_path_ns}},   
      (defined($elem->{NamespaceURI}) ? $elem->{NamespaceURI} : '');
  }

  my $new_list = [];
  my $new_node = [ 'e', { %$elem }, $new_list ];

  push @{$self->{_curr_list}}, $new_node;
  push @{$self->{_lists}}, $self->{_curr_list};
  $self->{_curr_list} = $new_list;
}

sub characters {
  my($self, $char) = @_;
  push @{$self->{_curr_list}}, $char->{Data};
}

sub comment {
  my($self, $comment) = @_;
  push @{$self->{_curr_list}}, [ 'c', { %{$comment} } ];
}

sub processing_instruction {
  my($self, $pi) = @_;
  push @{$self->{_curr_list}}, [ 'p', { %{$pi} } ];
}

sub end_element {
  my $self = shift;

  # Check for matches against sort key patterns

  my $i = 0;
  while(exists($self->{_match_subs}->[$i])) {
    if($self->{_match_subs}->[$i]->($self)) {
      splice(@{$self->{_match_subs}}, $i, 1);  # Delete the match sub
    }
    else {
      $i++;
    }
  }

  $self->{_depth}--;
  pop @{$self->{_path_name}};
  pop @{$self->{_path_ns}};

  $self->{_curr_list} = pop @{$self->{_lists}};

}


1;

__END__

=head1 NAME

XML::Filter::Sort::Buffer - Implementation class used by XML::Filter::Sort


=head1 DESCRIPTION

The documentation is targetted at developers wishing to extend or replace
this class.  For user documentation, see L<XML::Filter::Sort>.

For an overview of the classes and methods used for buffering, see
L<XML::Filter::Sort::BufferMgr>.

=head1 BUFFER LIFE CYCLE

A B<XML::Filter::Sort::Buffer> object is created by a
B<XML::Filter::Sort::BufferMgr> object using the C<new()> method.

The B<XML::Filter::Sort> object will then propagate any SAX events it receives,
to the buffer object until the end of the record is reached.  As each element
is added to the buffer, its contents are compared to the sort key paths and the
sort key values are extracted.

When the end of the record is reached, the C<close()> method is called.  The
return value from this method is the list of sort keys.

The buffer manager will store the buffer until the end of the record sequence
is reached.  Then it will retrieve each buffer in order of the sort key values
and call the buffer's C<to_sax()> method to send all buffered events to the
downstream handler.

Following the call to C<to_sax()>, the buffer is discarded.  No destructor
method is used - everything is handled by Perl's garbage collector.

=head1 DATA STRUCTURES

The buffer contains a 'tree' of SAX events.  The tree is simply an array
of 'nodes'.  Text nodes are represented as scalars.  Other nodes are
represented as arrayrefs.  The first element of a node array is a single
character identifying the node type:

  e - element
  c - comment
  p - processing instruction

The second element is the node data (the hash from the original SAX event).
The child nodes of an element node are represented by the third element as
an arrayref.

For example, this XML:

  <person age="27">
    <lastname>smith</lastname>
  </person>

Would be buffered as this data structure:

  [
    [
      'e',
      {
	'Name' => 'person'
	'Prefix' => '',
	'LocalName' => 'person',
	'NamespaceURI' => '',
	'Attributes' => {
	  '{}age' => {
	    'LocalName' => 'age',
	    'NamespaceURI' => '',
	    'Value' => '27',
	    'Prefix' => '',
	    'Name' => 'age'
	  }
	},
      },
      [
	"\n  ",
	[
	  'e',
	  {
	    'Name' => 'lastname'
	    'Prefix' => '',
	    'LocalName' => 'lastname',
	    'NamespaceURI' => '',
	    'Attributes' => {},
	  },
	  [
	    'smith'
	  ]
	],
	"\n  ",
      ]
    ]
  ]

=head1 COPYRIGHT 

Copyright 2002 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut



##############################################################################
# Method: to_sax()
#
# The following version of to_sax() uses an iterative design rather than the
# conceptually simpler recursive implementation.  Strangely (and unfortunately)
# it's about 20% slower than the recursive version - anyone know why?
#

sub to_sax {
  my $self   = shift;
  my $filter = shift;


  my @lists = $self->{tree};
  my($node);

  while(@lists) {
    if(@{$lists[-1]}) {
      $node = $lists[-1]->[0];
      if(ref($node)) {
	if($node->[NODE_TYPE] eq 'e') {
	  $filter->start_element($node->[NODE_DATA]);
	  push @lists, pop(@$node);
	}
	elsif($node->[NODE_TYPE] eq 'c') {
	  $filter->comment($node->[NODE_DATA]);
	  shift(@{$lists[-1]});
	}
	elsif($node->[NODE_TYPE] eq 'p') {
	  $filter->processing_instruction($node->[NODE_DATA]);
	  shift(@{$lists[-1]});
	}
	else {
	  die "Unexpected node type: '$node->[NODE_TYPE]'";
	}
      }
      else {
	$filter->characters({ Data => $node });
	shift(@{$lists[-1]});
      }
    }
    else {
      pop @lists;  # discard empty content list
      if(@lists) {
	$node = shift(@{$lists[-1]});
	$filter->end_element($node->[NODE_DATA]);
      }
    }

  }

  return;

}

