###############################################################################
# XML::Template::Element::Condition
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Condition;
use base qw(XML::Template::Element);

use strict;
use XML::Template::Element;


=pod

=head1 NAME

XML::Template::Element::Condition - XML::Template plugin module for the
condition namespace tagset.

=head1 SYNOPSIS

This XML::Template plugin module implements the condition namespace
tagset. The condition namespace includes tags for creating flow control
structures.

=head1 CONSTRUCTOR

XML::Template::Element::Block inherits its constructor method, C<new>,
from L<XML::Template::Element>.

=head1 CONDITION TAGSET METHODS

=head2 if

This method implements the beginning of an if flow control structure.  The 
following attributes are used:

=over 4

=item cond

The test to perform that, if evaluates to true, passes control to the 
content of the if element.

=back

=cut

sub if {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $cond = $self->get_attrib ($attribs, 'cond') || 'undef';

  my $outcode = qq!
if ($cond) {
  $code
}
  !;

  return $outcode;
}

=pod

=head2 elseif

This method implements the elseif section of an if flow control structure.  
The following attributes are used:

=over 4

=item cond

The test to perform that, if evaluates to true, passes control to the 
content of the elseif element.

=back

=cut

sub elseif {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $cond = $self->get_attrib ($attribs, 'cond') || 'undef';

  my $outcode = qq!
} elsif ($cond) {
  $code
  !;

  return $outcode;
}

=pod

=head2 else

This method implements the else section of an if flow control structure.

=cut

sub else {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $outcode = qq!
} else {
  $code
  !;

  return $outcode;
}

=pod

=head2 switch

This method implements the beginning of a switch flow control structure.  
The following attributes are used:

=over 4

=item expr

The expression to compare to the value attribute of each nested case
element.  When a match is found, the content of that case element is 
evaluated.

=back

=cut

sub switch {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $expr = $self->get_attrib ($attribs, 'expr') || 'undef';

  my $outcode = qq!
do {
  \$vars->create_context ();

  my \$__expr = $expr;
  SWITCH: {
$code
  }

  \$vars->delete_context ();
};
  !;

  return $outcode;
}

=pod

=head2 case

This method implements the case section of a switch flow control 
structure.  The following attributes are used:

=over 4

=item value

If this value match the switch expression, the content of this case 
element will be evaluated.

=over

sub case {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $value = $self->get_attrib ($attribs, 'value');

#  my $cond;
#  if ($value =~ /^\/.*\/$/) {
#    $cond = "\$expr =~ $value";
#  } else {
  my $cond = "\$__expr eq '$value'";
#  }

  my $outcode = qq!
    $cond && do {
      $code
      last SWITCH;
    };
  !;

  return $outcode;
}

=pod

=head2 default

This method implements the default section of a switch control structure.  
The content is evaluates when no case values match the switch expression.

=cut

sub default {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $outcode = qq!
    $code
  !;

  return $outcode;
}

=pod

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
