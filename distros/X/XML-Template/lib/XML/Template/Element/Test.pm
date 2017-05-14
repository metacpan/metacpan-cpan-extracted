###############################################################################
# XML::Template::Element::Test
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Test;

# The base class for any element module is typically XML::Template::Element.
# If the element is a database element, the base class will typically be 
# XML::Template::Element::DB.
# If the element needs to use iteration, add to the list of base classes 
# XML::Template::Element::Iterator.
use base qw(XML::Template::Element);

use strict;
use XML::Template::Element;


=pod

=head1 NAME

XML::Template::Element::Test - A sample XML::Template plugin module for 
the test namespace.

=head1 SYNOPSIS

This XML::Template plugin module implements the test namespace tagset.  
It is provided as a sample plugin module to base real ones on.

=head1 CONSTRUCTORE

XML::Template::Element::Test inherits its constructor method, C<new>, from 
L<XML::Template::Element>.

=head1 TEST TAGSET METHODS

=head2 test

This method implements the test tag.  The following attributes are used:

=over 4

=item attrib1

Test attribute 1.

=item attrib2, attribs2

Test attribute 2.

=back

=cut

sub test {
  my $self = shift;

  # If C<content> for this element is set in the configuration to 
  # C<xml>, the first argument will contain this element's  content 
  # translated into Perl code.  If C<content> is set to C<text>, the 
  # first argument will contain the unparsed content of this element.
  my $code    = shift;
#  my $text    = shift;

  # The second argument is a reference to a hash containing attribute 
  # name/value pairs.  If C<parse> for an attribbute is set to C<true>, 
  # the attribute value will have been parsed with the standard string 
  # parrser or by the parser given by C<parser> for the attribute.  If 
  # C<parse> is set to C<false>, the values will be a string containing 
  # the unparsed attribute value.
  my $attribs = shift;

  # Get the attribute values using the C<get_attrib> method.  The first 
  # parameter is the reference to the attributes hash.  The second 
  # parameter is the name(s) of the attribute to get.  This parameter can 
  # be a scalar or an anaonymous list containing the various allowable 
  # names of the attribute.  C<get_attrib> will first look for the 
  # attributes associated with this element's namespace, then for 
  # attributes not associated with any attribute.  Note that C<get_attrib> 
  # will remove the attribute from the attribute hash if it finds it.  To 
  # prevent this, pass C<0> as the last argument.  If the attribute does 
  # not exist, undef is returned.  You should always test for this and 
  # proivide a default value.
  my $attrib1 = $self->get_attrib ($attribs, 'attrib1') || 'undef';
  my $attrib2 = $self->get_attrib ($attribs, ['attrib2', 'attribs2'])
                || "'default'";

  # The method C<generate_named_params> will generate a comma-separated 
  # list of named params for the attribute names and values.
  my $attribs_named_params = $self->generate_named_params ($attribs);

  # Get the element's namespace
  my $namespace = $self->namespace ();

  # Create the code for this element.
  my $outcode = qq{
# The code for the element should generally be enclosed in a do block to 
# give a context for local variables.
do {
  # Create a new variable context for any XML::Template variables that 
  # get created in this element's code.
  \$vars->create_context ();

  # Create a hash containing attribute name/value pairs.
  # This is necessary for checking attribute value types and may be 
  # necessary for other purposes in the element code.
  my \%attribs = ($attribs_named_params);

  # Check the attribute value types against the types given in the 
  # configuration.
#  \$process->{_parser}->check_attrib_types ('$namespace', 'test', \\\%attribs);

  # If code was generated for the element's content, insert it.
  $code

  # Delete the variable context.
  \$vars->delete_context ();
};
  };

  # Return the element's code.
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
