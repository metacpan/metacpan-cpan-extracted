###############################################################################
# XML::Template::Element::Iterator
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Iterator;


use strict;
use XML::Template::Element;


=pod

=head1 NAME

XML::Template::Element::Iterator - XML::Template module that implements 
abstract iteration.

=head1 SYNOPSIS

This module provides the foreach element and the underlying methods 
necessary for iteration.  Iteration is an abstract process and is defined 
by the modules that are derived from this one.  They simply need to 
provide several methods for iterating through the data type specific to 
the subclass.

=head1 CONSTRUCTOR

XML::Template::Element::Block inherits its constructor method, C<new>,
from L<XML::Template::Element>.

=head1 PRIVATE METHODS

=head2 _foreach

This method implements iteration using the following algorithm:

  Initialize loop
  $__value = first element
  While $__value is defined
    Set look variable
    $__value = next element
  Finish loop

Each step is implemented by code returned by the following iteration 
methods, which are defined in the subclass.

=cut

sub _foreach {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $module = ref ($self);

  my $loopinit_code    = $self->loopinit ($attribs);
  my $get_first_code   = $self->get_first ($attribs);
  my $set_loopvar_code = $self->set_loopvar ($attribs);
  my $get_next_code    = $self->get_next ($attribs);
  my $loopfinish_code  = $self->loopfinish ($attribs);

  my $outcode = qq!
  my (\@__array, \$__value);
  my \$__index = 0;

  $loopinit_code

  $get_first_code

  while (defined \$__value) {
    $set_loopvar_code
    $code
    $get_next_code
  }
  $loopfinish_code
  !;
#print $outcode;

  return $outcode;
}

=pod

=head1 ITERATOR METHODS

=head2 loopinit

This method returns Perl code that initializes the loop.

=cut

sub loopinit {
  my $self = shift;
  my ($vars, $attribs) = @_;

  return '';
}

=pod

=head2 get_first

This method returns Perl code that gets the first element in the loop.

=cut

sub get_first {
  my $self    = shift;
  my $attribs = shift;

  my $outcode = qq!
  \$__value = \$__array[0];
  !;

  return $outcode;
}

=pod

=head2 set_loopvar

This method returns Perl code that sets the loop variable that contains 
the value of the current element in the loop.

=cut

sub set_loopvar {
  my $self    = shift;

  return '';
}

=pod

=head2 get_next

This method returns Perl code that gets the next element in the loop.

=cut

sub get_next {
  my $self    = shift;
  my $attribs = shift;

  my $outcode = qq!
  \$__value = \$__array[++\$__index];
  !;

  return $outcode;
}

=pod

=head2 loopfinish

This method returns Perl code that ends the loop and performs any relevant 
cleaning up.

=cut

sub loopfinish {
  my $self = shift;

  return '';
}

=pod

=head1 ITERATOR TAGSET METHODS

=head2 foreach

This method implements the foreach element that is inherited by a 
subclass which defines the internals.

=cut

sub foreach {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $foreach_code = $self->_foreach ($code, $attribs);

  my $outcode = qq!
do {
  \$vars->create_context ();

  $foreach_code

  \$vars->delete_context ();
};
  !;
#print $outcode;

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
