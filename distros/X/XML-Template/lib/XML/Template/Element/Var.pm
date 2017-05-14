###############################################################################
# XML::Template::Element::Var
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Var;
use base qw(XML::Template::Element XML::Template::Element::Iterator);


use strict;
use Exporter;
use IO::String;
use Data::Dumper;


=pod

=head1 NAME

XML::Template::Element::Var - XML::Template plugin module for the var
namespace.

=head1 SYNOPSIS

This XML::Template plugin module implements the var namespace tagset.
The var namespace includes tags that handle scalar, array, nested, and 
XPath variables.

=head1 CONSTRUCTOR

XML::Template::Element::Var inherits its constructor method, C<new>, from
L<XML::Template::Element>.

=head1 VAR TAGSET METHODS

=head2 set

This method implements the set element which set a variable.  The value of 
the variable is contained in the content.  The following attributes are 
used:

=over 4

=item name

The name of the variable to set in XML::Template variable format.

=item scope

The context in which to create the new variable: C<global> or C<local>.  
The default value is C<local>.

=back

=cut

sub set {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name  = $self->get_attrib ($attribs, 'name') || 'undef';
  my $scope = $self->get_attrib ($attribs, 'scope') || "'local'";

  my $outcode = qq!
do {
  my \$__varname = $name;
  my \$__set = 1;
  my \$__i = 0;

  my \$cgi_header = \$process->{_cgi_header};
  \$process->{_cgi_header} = 0;

  my \$value;
  my \$io = IO::String->new (\$value);
  my \$ofh = select \$io;

  $code

  select \$ofh;

  if (\$__set) {
    \$value =~ s/^\\s*//;
    \$value =~ s/\\s*\$//;
    if ($scope eq 'global') {
      \$vars->set_global (\$__varname => \$value);
    } else {
      \$vars->set (\$__varname => \$value);
    }
  }

  \$process->{_cgi_header} = \$cgi_header;
};
  !;
#print $outcode;

  return $outcode;
}

=pod

=head2 unset

This metho implements the unset element which unsets (deletes) a variable 
from the current variable context.  The following attributes are used:

=over 4

=item name

The name of the variable to unset in XML::Template variable format.

=back

=cut

sub unset {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name  = $self->get_attrib ($attribs, 'name') || 'undef';

  my $outcode = qq{
do {
    \$vars->unset ($name);
};
  };

  return $outcode;
}

=pod

=head2 element

This method implements the element element which must be nested in the set 
element.  It is used to set array values or nested variable values.  It 
uses the following attributes:

=over 4

=item name

If you supply the name attribute, a new nested variable is created under 
the parent variable with this name.  Otherwise, an additional array value 
is appended to the parent array.

For instance,

  <xml xmlns:var="http://syrme.net/xml-template/var/v1">
    <var:set name="array">
      <var:element>ONE</var:element>
      <var:element>TWO</var:element>
      <var:element>THREE</var:element>
    </var:set>

    <var:set name="nested1">
      <var:element name="nested2">
        <var:element name="nested3">
         <var:element>ONE</var:element>
         <var:element>TWO</var:element>
         <var:element>THREE</var:element>
        </var:element>
        <var:element>TWO</element>
      </var:element>
    </var:set>
  </xml>

=cut

sub element {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name = $self->get_attrib ($attribs, 'name') || 'undef';

  my $outcode = qq!
do {
  my \$__varname = \$__varname;
  if (defined $name) {
    \$__varname .= "." . $name;
  } else {
    \$__varname .= "[\$__i]";
    \$__i++;
  }
  \$__set = 0;
  my \$__set = 1;
  my \$__i = 0;

  my \$value;
  my \$io = IO::String->new (\$value);
  my \$ofh = select \$io;

  $code

  select \$ofh;

  if (\$__set) {
    \$value =~ s/^\\s*//;
    \$value =~ s/\\s*\$//;
    \$vars->set (\$__varname => \$value);
  }
};
  !;

  return $outcode;
}

=pod

=head2 get

This method implements the get element which returns the value of a 
variable.  The following attributes are used:

=over 4

=item name

The name of the variable whose value you wish to return in XML::Template 
variable format.

=back

=cut

sub get {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name = $self->get_attrib ($attribs, 'name') || 'undef';

  my $outcode = qq!
print \$vars->get ($name);
  !;

  return $outcode;
}

=pod

=head2 dump

This method implements the dump element which dumps the contents of a 
variable using Data::Dumper.  The following attributes are used:

=over 4

=item name

The name of the variable to dump in XML::Template variable name format.

=back

=cut

sub dump {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name = $self->get_attrib ($attribs, 'name') || 'undef';

  my $outcode = qq!
print Dumper (\$vars->get ($name));
  !;

  return $outcode;
}

=pod

=head2 foreach

XML::Template::Element::Var is a subclass of
L<XML::Template::Element::Iterator>, so it inherits the C<foreach> method,
which in conjunction with the iterator methods defined in this module,
implements iteration through arrays values.  Note that XPath variables may
return an array of matched element through with you may iterate.  The
following attributes are used:

=over 4

=item src

The name of the variable whose value you wish to iterate through.

=item var

The name of the variable, available in the content, that contains the 
current array element value.

=back

For instance,

  <xml xmlns:var="syrme.net/xml-template/var/v1">
    <var:foreach src="nested.array" var="el">
      ${el}
    </var:foreach>

    <var:foreach src="xml[2]/employee[@type="fulltime"]/lastname/text()"
                 var="lastname">
      ${lastname}
    </var:foreach>
  </xml>

=cut

sub loopinit {
  my $self    = shift;
  my $attribs = shift;

  my $array = $self->get_attrib ($attribs, 'array') || 'undef';
# xxx do replace in get_attrib ?
#  $array =~ s/\@/\\\@/g;
  my $var   = $self->get_attrib ($attribs, 'var')   || 'undef';

  my $outcode = qq!
my \$__var = $var;
my \$array = $array;
if (ref (\$array) eq 'ARRAY') {
  \@__array = \@\$array;
} elsif (ref (\$array) eq 'HASH') {
  \@__array = keys \%\$array;
} elsif (ref (\$array)) {
  push (\@__array, \$array);
} else {
  my \@array = split (/(?<\!\\\\),/, \$array);
  foreach my \$str (\@array) {
    if (\$str =~ /^([^\.]+)\\.\\.(.+)\$/) {
      push (\@__array, \$1..\$2);
    } else {
      push (\@__array, \$str);
    }
  }
}
!;

  return $outcode;
}

sub set_loopvar {
  my $self    = shift;
  my $attribs = shift;

  my $outcode = qq!
  \$vars->set (\$__var => \$__value);
  !;

  return $outcode;
}

=pod

=head1 XML::Template SUBROUTINES

Several method exist in XML::Template::Element::Var that implement 
XML::Template subroutines that operate on variables.  This module should 
be associated with them in the XML::Template configuration file.  See 
L<XML::Template::Subroutine> for more details.

=head2 push

This subroutine pushes a value onto the end of the array referenced by the
value.  The additional parameter is the new value to add.

=cut

sub push {
  my $class   = shift;
  my $process = shift;
  my ($var, $value, $el) = @_;

  $el = $class->strip ($el);

  CORE::push (@$value, $el);

  return '';
}

=pod

=head2 pop

This method pops a value off the end of the array referenced by the value.

=cut

sub pop {
  my $class   = shift;
  my $process = shift;
  my ($var, $value) = @_;

  CORE::pop (@$value);

  return '';
}

=pod

=head2

This method unshifts a new value onto the beginning of the array
referenced by the value.  The additional parameter is the new value to
add.

=cut

sub unshift {
  my $class   = shift;
  my $process = shift;
  my ($var, $value, $el) = @_;

  $el = $class->strip ($el);

  CORE::unshift (@$value, $el);

  return '';
}

=pod

=head2 shift

This method shifts a value off the beginning of the array referenced by
the value.

=cut

sub shift {
  my $class   = shift;
  my $process = shift;
  my ($var, $value) = @_;

  CORE::shift (@$value);

  return '';
}

=pod

=head2 join

This method joins the strings in the array referenced by the value.  The
additional parameter specified the separator to use between the strings.

=cut

sub join {
  my $class   = shift;
  my $process = shift;
  my ($var, $value, $sep) = @_;

  $sep = $class->strip ($sep);

  return CORE::join ($sep, @$value);
}

=pod

=head2 split

This method splits a string into substrings and returns a reference to an
array containing them.  The additional parameter specified the separator
to split the string on.

=cut

sub split {
  my $class   = shift;
  my $process = shift;
  my ($var, $value, $sep) = @_;

  $sep = $class->strip ($sep);

  my @array = CORE::split ($sep, $value);
  return \@array;
}

=pod

=head2 length

This method returns the number of elements in the array referenced by 
value.

=cut

sub length {
  my $class   = shift;
  my $process = shift;
  my ($var, $value) = @_;

  if (defined $value) {
    if (ref ($value) eq 'ARRAY') {
      return scalar (@$value);
    } else {
      return 1;
    }
  } else {
    return 0;
  }
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
