package XML::DTD::ContentModel;

use XML::DTD::Automaton;
use XML::DTD::Error;

use 5.008;
use strict;
use warnings;
use Error qw(:try);

our @ISA = qw();

our $VERSION = '0.10';


# Constructor
sub new {
  my $proto = shift; # Class name or object reference
  my $cmstr = shift; # Content model string
  my $entmn = shift; # Reference to EntityManager object

  my $cls = ref($proto) || $proto;
  my $obj = ref($proto) && $proto;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
    my $child;
    $self->{'chldlst'} = [];
    foreach $child ( @{$obj->{'chldlst'}} ) {
      push @{$self->{'chldlst'}}, $child->new;
    }
    bless $self, $cls;
  } else {
    # Called as the main constructor
    throw XML::DTD::Error("Constructor for XML::DTD::ContentModel called ".
			  "with undefined content model string")
      if (!defined $cmstr);
    $self = {
	     'chldlst' => [],    # List of child objects
	     'eltname' => undef, # Element name if leaf node of tree
	     'combnop' => undef, # Combine operator (choice or sequence)
	     'occurop' => undef  # Occurrence operator ('?', '*', or '+')
	    };
    bless $self, $cls;
    # Try to parse content model string
    try {
      $self->_parse($cls, $cmstr, $entmn);
    }
    # Catch any parse error exceptions
    catch XML::DTD::Error with {
      my $eo = shift;
      # If entity manager defined, and content model string contains
      # an entity reference, expand the entity reference and retry
      # parsing, otherwise just rethrow the exception. (This is an
      # ugly way of dealing with entity definitions not properly
      # handled by the parse method.)
      if (defined $entmn and $cmstr =~ /%[\w\.:\-_]+;/) {
	  $cmstr = $entmn->entitysubst($cmstr);
	  $self->_parse($cls, $cmstr, $entmn);
	} else {
	  $eo->throw();
	}
    };
  }
  return $self;
}


# Determine whether object is of this type
sub isa {
  my $cls = shift;
  my $r = shift;

  if (defined($r) && ref($r) eq $cls) {
    return 1;
  } else {
    return 0;
  }
}


# Return the list of child objects (subexpressions)
sub children {
  my $self = shift;

  if (@_) {
    my $chldlst = shift;
    $self->{'chldlst'} = $chldlst;
  }

  return $self->{'chldlst'}
}


# Return the element name if the object is the leaf node of the tree
sub element {
  my $self = shift;

  if (@_) {
    my $element = shift;
    $self->{'eltname'} = $element;
  }

  return $self->{'eltname'}
}


# Return the combination operator (i.e. "," or "|")
sub combineop {
  my $self = shift;

  if (@_) {
    my $combnop = shift;
    $self->{'combnop'} = $combnop;
  }

  return $self->{'combnop'};
}


# Return the occurrence operator (i.e. "?","+", or "*")
sub occurop {
  my $self = shift;

  if (@_) {
    my $occurop = shift;
    $self->{'occurop'} = $occurop;
  }

  return $self->{'occurop'};
}


# The object is atomic (i.e. the model consists of a single element,
# ANY, EMPTY, or #PCDATA)
sub isatomic {
  my $self = shift;

  return ((scalar @{$self->{'chldlst'}}) == 0);
}


# Return a list of contained elements
sub childnames {
  my $self = shift;
  my $names = shift;

  my $en;
  $names = {} if (!defined $names);
  if ($self->isatomic) {
    $en = $self->element;
    $names->{$en} = 1 if ($en ne 'ANY' and $en ne 'EMPTY' and
			  $en ne '#PCDATA');
  } else {
    my $child;
    foreach $child (@{$self->children}) {
      $child->childnames($names);
    }
  }
  return [sort keys %$names];
}


# Build a string representation of the content model
sub string {
  my $self = shift;

  my $type = $self->type;
  if ($self->isatomic and ($type eq 'mixed' or $type eq 'element')) {
    return "(" . $self->_string . ")";
  } else {
    return $self->_string;
  }
}


# Build a string representing the hierarchical structure of the model
sub treestring {
  my $self = shift;
  my $indent = shift;   # Indentation level
  my $showrefs = shift; # Flag selecting display of object references

  $indent = 0 if (!defined $indent);
  my $pre = '  ' x $indent;
  $pre .= "$self\t" if ($showrefs);
  my $cop = (defined $self->combineop)?$self->combineop:'';
  my $oop = (defined $self->occurop)?$self->occurop:'';
  my $cms = $self->string;
  my $str = sprintf("%-30s\t%s\t%s\n", $pre.$cms, $cop, $oop);
  my $child;
  foreach $child ( @{$self->{'chldlst'}} ) {
      $str .= $child->treestring($indent + 1, $showrefs);
  }
  return $str;
}


# Write component-specific part of the XML representation
sub writexmlelts {
  my $self = shift;
  my $xmlw = shift; # XML output object

  my $occur = (defined $self->{'occurop'} and $self->{'occurop'} ne '')?
    $self->{'occurop'}:undef;
  my $subop = (defined $self->{'combnop'} and $self->{'combnop'} ne '')?
    $self->{'combnop'}:undef;
  my $peref = (defined $self->{'peref'})?$self->{'peref'}:undef;
  if ($self->isatomic) {
    my $name = $self->element;
    my $label;
    if ($name eq '#PCDATA' or $name eq 'EMPTY' or $name eq 'ANY') {
      $label = 'type';
    } else {
      $label = 'name';
    }
    $xmlw->empty('child', {$label => $name, 'occur' => $occur,
			   'peref' => $peref});
  } else {
    $xmlw->open('children', {'occur' => $occur, 'subop' => $subop,
			     'peref' => $peref});
    my $c;
    foreach $c ( @{$self->{'chldlst'}} ) {
      $c->writexmlelts($xmlw);
    }
    $xmlw->close;
  }
}


# Determine the content specification type (empty, any, mixed, or element)
sub type {
  my $self = shift;

  if ($self->isatomic) {
    if ($self->element eq 'EMPTY') {
      return 'empty';
    } elsif ($self->element eq 'ANY') {
      return 'any';
    } elsif ($self->element eq '#PCDATA') {
      return 'mixed';
    } else {
      return 'element';
    }
  } else {
    my $oop = (defined $self->occurop)?$self->occurop:'';
    my $cop = (defined $self->combineop)?$self->combineop:'';
    if ($cop eq '|' and ($oop eq '' or $oop eq '*')) {
      my $chld = $self->children;
      my $c;
      foreach $c (@$chld) {
	return 'element' if (!$c->isatomic);
      }
      return 'element' if ($chld->[0]->element ne '#PCDATA');
      return 'mixed';
    } else {
      return 'element';
    }
  }
}


# Construct a DFA to validate the content model
sub dfa {
  my $self = shift;

  # The approach is to use Thompson's construction of an NDFA from a
  # regular expression, and then convert to Glushkov form via epsilon
  # state elimination. Since SGML/XML content models are constrained
  # to be unambiguous (or deterministic), the resulting automaton
  # should be deterministic. For background details see references
  # in documentation (below) for this method.

  # Construct an initial FSA object
  my $fsa = XML::DTD::Automaton->new;
  # Initial left index points to initial state
  my $ltn = 0;
  # Construct final state and set initial right index to its index
  my $rtn = $fsa->mkstate('Final', 1);
  # Call recursive FSA construction function
  $self->_buildfsa($fsa, $ltn, $rtn);
  # Eliminate epsilon transitions
  $fsa->epselim;
  # Remove unreachable states
  $fsa->rmunreach;
  # Ensure FSA is a DFA
  throw XML::DTD::Error("FSA for content model " . $self->string .
			" is not deterministic") if (!$fsa->isdeterministic);
  return $fsa;
}


# Parse content model string
#   Warning: This method is a mess, and should be completely rewritten
sub _parse {
  my $self = shift;
  my $class = shift; # Class identity for calling new method
  my $cmstr = shift; # Content model string
  my $entmn = shift; # Entity manager

  $cmstr =~ s/\s+//g; # Remove spaces
  ##print STDERR "PARSE: $cmstr\n";

  # Substitute entity values for references if entity is entire content model
  if (defined $entmn and
      ($cmstr =~ /^%([\w\.:\-_]+);$/ or
       $cmstr =~ /^\(%([\w\.:\-_]+);(\?|\*|\+)?\)$/ or
       $cmstr =~ /^\(%([\w\.:\-_]+);\)(\?|\*|\+)?$/ or
       $cmstr =~ /^\(\(%([\w\.:\-_]+);\)(\?|\*|\+)?\)$/)) {
    #my $paren = defined $2;
    #my $ocop = (defined $3)?$3:'';
    #$self->{'peref'} = $paren ? $2 : $1;
    $self->{'peref'} = $1;
    my $ocop = (defined $2)?$2:'';
    #my $paren = $cmstr =~ /\(/;
    my $paren = 1;
    my $entv = $entmn->pevalue($self->{'peref'});
    my $cmpnd = ($entv =~ /^[^\(]+\||\,[^\)]+$/);
    $cmstr = ($paren or $cmpnd)?"($entv$ocop)":"$entv$ocop" if (defined $entv);
    $cmstr =~ s/\s+//g; # Remove spaces
    ##print STDERR "SUBST: |$cmstr|$paren|$cmpnd|$entv|\n";
  }

  # Substitute entity values for references if content model consists
  # of a single entity with various configurations of parentheses and
  # occurence operators
  if (defined $entmn) {
    if ($cmstr =~ /^%([\w\.:\-_]+);$/) {
      $self->{'peref'} = $1;
      my $entv = $entmn->pevalue($self->{'peref'});
      $cmstr = "($entv)" if (defined $entv);
    } elsif ($cmstr =~ /^\(%([\w\.:\-_]+);(\?|\*|\+)?\)$/) {
      $self->{'peref'} = $1;
      my $ocop = (defined $2)?$2:'';
      my $entv = $entmn->pevalue($self->{'peref'});
      $cmstr = "($entv$ocop)" if (defined $entv);
    } elsif ($cmstr =~ /^\(%([\w\.:\-_]+);\)(\?|\*|\+)?$/) {
      $self->{'peref'} = $1;
      my $ocop = (defined $2)?$2:'';
      my $entv = $entmn->pevalue($self->{'peref'});
      $cmstr = "($entv)$ocop" if (defined $entv);
    } elsif ($cmstr =~ /^\(\(%([\w\.:\-_]+);\)(\?|\*|\+)?\)$/) {
      $self->{'peref'} = $1;
      my $ocop = (defined $2)?$2:'';
      my $entv = $entmn->pevalue($self->{'peref'});
      $cmstr = "(($entv)$ocop)" if (defined $entv);
    }

    $cmstr =~ s/\s+//g; # Remove spaces
  }

  # Temporary
  $self->{'cmstr'} = $cmstr;

  # Check whether model is a single element
  if ($cmstr =~ /^([A-Za-z_:][A-Za-z0-9-_:\.]*|#PCDATA)(\?|\+|\*)?$/ or
      $cmstr =~ /^\(([A-Za-z_:][A-Za-z0-9-_:\.]*|#PCDATA)(\?|\+|\*)?\)$/ or
      $cmstr =~ /^\(([A-Za-z_:][A-Za-z0-9-_:\.]*|#PCDATA)\)(\?|\+|\*)?$/) {
    # Just need to set element name and (optional) occurrence operator
    $self->{'eltname'} = $1;
    $self->{'occurop'} = $2;
    ##print STDERR "ATOMIC: |$cmstr|$1|".((defined $2)?$2:'')."\n";
    # Check whether model is a choice or sequence
  } elsif ($cmstr =~ /^\((.+)\)(\?|\+|\*)?$/) {
    # Should rewrite using _parenmatch in place of regex above
    # Set working string to content of parentheses and note occurrence operator
    $cmstr = $1;
    $self->{'occurop'} = $2;
    ##print STDERR "EXPR0: |$cmstr|\n";
    # Deal with first sequence/choice child expression
    my $expr;
    # Check whether string has no parentheses preceding the first
    # sequence or choice character
    if ($cmstr =~ /^([^\(\)\,\|]*)(\,|\|)/) { # Combine operator first
      $expr = $1;
      $self->{'combnop'} = $2;
      ##print STDERR "0CMBNOP: >>$2<< >>$cmstr<< >>$expr<<\n";
      $cmstr = $';
      throw XML::DTD::Error("Invalid content model: $cmstr", $self)
	  if ($expr eq '');
      push @{$self->{'chldlst'}}, $class->new($expr, $entmn);
    } else { # Parenthesis first
      my ($mat, $pst) = _parenmatch($cmstr);
      # Check whether parenthesis post-match consists of an optional
      # occurrence operator optionally followed by a combine operator
      ##print STDERR "PAREN: |$cmstr|$mat|$pst|\n";
      if ($pst =~ /^(\?|\+|\*)?(\,|\|)?/) {
	$expr = $mat.(defined($1)?$1:'');
	$self->{'combnop'} = $2;
	##print STDERR "1CMBNOP: >>$2<< >>$cmstr<< >>$expr<<\n";
	$cmstr = $';
	throw XML::DTD::Error("Invalid content model: $cmstr", $self)
	  if ($expr eq '');
	push @{$self->{'chldlst'}}, $class->new($expr, $entmn);
      } else {
	throw XML::DTD::Error("Invalid content model: $cmstr", $self);
	return;
      }
    }

    # Work through remaining sequence/choice child expressions
    while ($cmstr ne '') {
      ##print STDERR "EXPRn: |$cmstr|\n";
      # Check whether string has no parentheses preceding the first
      # sequence or choice character
      if ($cmstr =~ /^([^\(\)\,\|]*)(\,|\||$)/) { # Combine operator first
	$expr = $1;
	# Should check that combine op $2 is correct
	$cmstr = $';
	##print STDERR "2CMBNOP: >>$2<< >>$cmstr<< >>$expr<<\n";
	push @{$self->{'chldlst'}}, $class->new($expr, $entmn);
      } else { # Parenthesis first
	my ($mat, $pst) = _parenmatch($cmstr);
	# Check whether parenthesis post-match consists of an optional
	# occurrence operator followed by a combine operator
	if ($pst =~ /^(\?|\+|\*)?(\,|\||$)/) {
	  $expr = $mat.(defined($1)?$1:'');
	  # Should check that combine op $2 is correct
	  $cmstr = $';
	  ##print STDERR "3CMBNOP: >>$2<< >>$cmstr<< >>$expr<<\n";
	  push @{$self->{'chldlst'}}, $class->new($expr, $entmn);
	} else {
	  throw XML::DTD::Error("Invalid content model: $cmstr", $self);
	  return;
	}
      }
    }
  } else {
    throw XML::DTD::Error("Invalid content model: $cmstr", $self);
    return;
  }
}


# Find closing parenthesis matching first opening parenthesis in a
# string, and return a list consisting of the substrings including and
# after that closing parenthesis.
sub _parenmatch {
  my $str = shift;

  ##print STDERR "PARENMATCH: $str\n";
  my $level = 0;
  my $pos = 0;
  my $len = length $str;
  my $posl = index $str, '('; $posl = $len if ($posl < 0);
  my $posr = index $str, ')'; $posr = $len if ($posr < 0);
  if ($posl >= $len && $posr >= $len) {
    # String contains no parentheses
    return ('',$str);
  }
  do {
    if ($posl < $posr) {
      # A '(' is next
      $level++;
      $pos = $posl+1;
      $posl = index $str, '(', $pos;
      $posl = $len if ($posl < 0);
    } else { # $posl >= $posr
      # A ')' is next
      $level--;
      if ($level < 0) {
	throw XML::DTD::Error("Parenthesis matching error in string $str");
	return undef;
      }
      $pos = $posr+1;
      $posr = index $str, ')', $pos;
      $posr = $len if ($posr < 0);
    }
    # Drop out when the level returns to 0 or the string is exhausted
  } while ($level > 0 && $pos < $len);
  if ($level > 0) {
    throw XML::DTD::Error("Parenthesis matching error in string $str");
    return undef;
  }
  my $pre = substr $str, 0, $pos;
  my $pst = substr $str, $pos;
  return ($pre, $pst);
}


# Recursive part of function to build a string representation of the
# content model
sub _string {
  my $self = shift;

  my $str = '';
  if ($self->isatomic) {
    $str = $self->element;
  } else {
    my $strlst = [];
    my $child;
    foreach $child ( @{$self->{'chldlst'}} ) {
      push @$strlst, $child->_string;
    }
    my $cop = (defined $self->combineop)?$self->combineop:'';
    $str .= '(' . join($cop,@$strlst) . ')';
  }
  $str .= $self->occurop if (defined $self->occurop);
  return $str;
}


# Recursive part of function to build an FSA
sub _buildfsa {
  my $self = shift;
  my $fsa = shift; # FSA object
  my $ltn = shift; # Left (inbound) state index
  my $rtn = shift; # Right (outbound) state index

  # Content model expression is processed by building an FSA with
  # entry via state index $ltn and exit via state index $rtn. For each
  # subexpression, epsilon transitions are made to new entry and exit
  # states which are processed via a recursive call.

  if (defined $self->occurop and
      $self->occurop ne '') { # Need to deal with occurrence operator
    # Construct copy of this content model expression
    my $subexp = $self->new;
    # Remove occurrence operator from copy
    $subexp->{'occurop'} = undef;
    # Construct new left and right states labelled by the copied
    # content model expression
    my $ltn0 = $fsa->mkstate($subexp->string . '_lt');
    my $rtn0 = $fsa->mkstate($subexp->string . '_rt');
    if ($self->occurop eq '?') { # Occurrence operator is '?'
      # Construct relevant epsilon transitions
      $fsa->mktrans($ltn, $ltn0, '');
      $fsa->mktrans($rtn0, $rtn, '');
      $fsa->mktrans($ltn, $rtn, '');
    } elsif ($self->occurop eq '*') {  # Occurrence operator is '*'
      # Construct relevant epsilon transitions
      $fsa->mktrans($ltn, $ltn0, '');
      $fsa->mktrans($rtn0, $rtn, '');
      $fsa->mktrans($ltn, $rtn, '');
      $fsa->mktrans($rtn, $ltn0, '');
    } else {  # Occurrence operator is '+'
      # Construct relevant epsilon transitions
      $fsa->mktrans($ltn, $ltn0, '');
      $fsa->mktrans($rtn0, $rtn, '');
      $fsa->mktrans($rtn, $ltn0, '');
    }
    # Recursive call to deal with occurrence operator-free subexpression
    $subexp->_buildfsa($fsa, $ltn0, $rtn0);
  } else { # No occurrence operator
    if (defined $self->combineop and
	$self->combineop ne '') { # Need to deal with combine operator
      my ($chld, $ltn0, $rtn0);
      # Loop over each subexpression
      foreach $chld ( @{$self->{'chldlst'}} ) {
	# Construct new left and right states labelled by the current
	# content model subexpression
	$ltn0 = $fsa->mkstate($chld->string . '_lt');
	$rtn0 = $fsa->mkstate($chld->string . '_rt');
	if ($self->combineop eq ',') { # Combine operator is ','
	  # Construct epsilon transition from current left state to
	  # left state for current subexpression
	  $fsa->mktrans($ltn, $ltn0, '');
	  # Set current left state to right state for current subexpression
	  $ltn = $rtn0;
	} else { # Combine operator is '|'
	  # Construct epsilon transition from current left state to
	  # left state for current subexpression
	  $fsa->mktrans($ltn, $ltn0, '');
	  # Construct epsilon transition from current right state to
	  # right state for current subexpression
	  $fsa->mktrans($rtn0, $rtn, '');
	}
	# Recursive call to deal with current subexpression
	$chld->_buildfsa($fsa, $ltn0, $rtn0);
      }
      # If combine operator is ',', construct epsilon transition from
      # current right state to right state for current subexpression
      $fsa->mktrans($rtn0, $rtn, '') if ($self->combineop eq ',');
    } else { # No combine operator
      if ($self->isatomic) {
	# Expression is atomic, without occurrence operator
	$fsa->mktrans($ltn, $rtn, $self->element);
      } else {
	# Expression is not atomic
	if (scalar @{$self->children} == 1) {
	  # Expression is of the form ((a,b)); need to strip outer
	  # parentheses and recurse down a level
	  my $chld = $self->children->[0];
	  $chld->_buildfsa($fsa, $ltn, $rtn);
	} else {
	  # Should never reach here
	  throw XML::DTD::Error("Error converting content model ".
				$self->string." to an FSA", $self);
	}
      }
    }
  }
}


1;

__END__

=encoding utf8

=head1 NAME

XML::DTD::ContentModel - Perl module representing an element content
model in an XML DTD

=head1 SYNOPSIS

  use XML::DTD::ContentModel;

  my $cm = XML::DTD::ContentModel->new('(a,b*,(c|d)+)');
  print $cm->treestring;

=head1 DESCRIPTION

XML::DTD::ContentModel is a Perl module representing an element content
model in an XML DTD. The following methods are provided.

=over 4

=item B<new>

 my $cm = XML::DTD::ContentModel->new('(a,b*,(c|d)+)');

Construct a new XML::DTD::ContentModel object.

=item B<isa>

 if (XML::DTD::ContentModel->isa($obj) {
 ...
 }

Test object type.

=item B<children>

 my $objlst = $cm->children;

Return an array of child objects (subexpressions) which are also of
type XML::DTD::ContentModel.

 my $objlst = $cm->children($children);

Set the array of child objects (subexpressions). Returns the new value.

=item B<element>

 my $name = $cm->element;

Return the element name if the object has no subexpressions.

 my $name = $cm->element($eltname);

Set the element name. The element name should only be set if the
object has no subexpressions. Returns the new value.

=item B<combineop>

 my $op = $cm->combineop;

Return the combination operator (",", "|" or C<undef>).

 my $op = $cm->combineop($combineop);

Set the combination operator (",", "|", or C<undef>). Returns the new
value.

=item B<occurop>

 my $op = $cm->occurop;

Return the occurrence operator ("?", "+", "*", or C<undef>).

 my $op = $cm->occurop($occurop);

Set the occurrence operator ("?", "+", "*", or C<undef>).  Returns the
new value.

=item B<isatomic>

 if ($cm->isatomic) {
 ...
 }

Determine whether the object is atomic (i.e. the model consists of a
single element, ANY, EMPTY, or #PCDATA).

=item B<childnames>

 my $nmlst = $cm->childnames;

Return an array of contained element names as an array reference.

=item B<string>

 print $cm->string;

Return a string representation of the content model.

=item B<treestring>

 print $cm->treestring;

Return a string representing the hierarchical structure of the model.

=item B<writexmlelts>

 open(FH,'>file.xml');
 my $xo = new XML::Output({'fh' => *FH});
 $cm->writexmlelts($xo);

Write a component-specific part of the XML representation.

=item B<type>

 my $typstr = $cm->type;

Determine the content specification type ('empty', 'any', 'mixed', or
'element').

=item B<dfa>

 my $dfa = $cm->dfa;

Construct a Deterministic Finite Automaton to validate the content
model (returns an XML::DTD::Automaton object). The approach is to use
Thompson's construction of an NDFA from a regular expression, and then
convert to Glushkov form via epsilon state elimination. Since SGML/XML
content models are constrained to be unambiguous (or deterministic),
the resulting automaton should be deterministic. For background
details see:

* Anne Brüggemann-Klein and Derick Wood, The Validation of SGML Content Models, Mathematical and Computer Modelling, 25, 73-84, 1997. L<ftp://ftp.informatik.uni-freiburg.de/documents/papers/brueggem/podpJournal.ps>
* Dora Giammarresi, Jean-Luc Ponty, and Derick Wood, Glushkov and Thompson Constructions: A Synthesis. Tech. Report 98-17. Università Ca' Foscari di Venezia. L<http://www.mat.uniroma2.it/~giammarr/Research/Papers/gluth.ps.Z>

=back

=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::Element>, L<XML::DTD::Automaton>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=head1 ACKNOWLEDGMENTS

Peter Lamb E<lt>Peter.Lamb@csiro.auE<gt> fixed a bug in the _parse
function, provided an improved implementation of _parenmatch, and
modified accessor methods to allow setting of relevant values.

=cut
