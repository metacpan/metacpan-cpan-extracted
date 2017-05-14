###############################################################################
# XML::Template::Element::Exception
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Exception;
use base qw(XML::Template::Element);

use strict;
use XML::Template::Element;


=pod

=head1 NAME

XML::Template::Element::Exception - XML::Template plugin module for the
exception namespace.

=head1 SYNOPSIS

This XML::Template plugin module implements the exception namespace 
tagset.  The exception namespace includes tags that handle exceptions.

=head1 CONSTRUCTOR

XML::Template::Element::Block inherits its constructor method, C<new>,
from L<XML::Template::Element>.

=head1 EXCEPTION TAGSET METHODS

=head2 throw

This method implements the tag C<throw> which throws an exception.  The 
following attributes are used:

=over 4

=item name

The name of the exception to throw.

=item info

A description of what caused the exception.

=back

=cut

sub throw {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name = $self->get_attrib ($attribs, 'name') || 'undef';
  my $info = $self->get_attrib ($attribs, 'info') || 'undef';

  my $outcode = qq!
die XML::Template::Exception->new ($name, $info);
  !;

  return $outcode;
}

=pod

=head2 try

This method implements the beginning of the try structure.  The content of 
this element will be evaluated.  If an exception is thrown it can be 
caught by the child element, C<catch>.

=cut

sub try {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $outcode = qq!
do {
  my \$caught = 0;

  my \$__eval_error;
  my \$first = 1;

  eval {
  $code
  };

  die \$\@ if \$\@ && \! \$caught;
};
  !;
#print $outcode;

  return $outcode;
}

=pod

=head2 catch

This method implements the catch section of a try structure.  If the 
content of the C<exception> element raises an exception and is caught by 
this element, the content will be evaluated.  The following attributes 
are used:

=over 4

=item name

The name of the exception to catch.

=back

=cut 

sub catch {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name = $self->get_attrib ($attribs, 'name') || 'undef';

  my $outcode = qq!
};
if (\$first) {
  \$__eval_error = \$\@ if \$\@;
  \$first = 0;
}

if (defined \$__eval_error && \! \$caught) {
  my \$exception = ref (\$__eval_error)
    ? \$__eval_error
    : XML::Template::Exception->new (undef, \$__eval_error);
  \$vars->set ('Exception.type' => \$exception->type);
  \$vars->set ('Exception.info' => \$exception->info);
  if (defined $name) {
    if (\$exception->isa ($name)) {
      \$caught = 1;
$code
    }
  } else {
    \$caught = 1;
$code
  }
  !;

  return $outcode;
}

=pod

=head2 else

This method implements the else section of a try structure.  If no 
exception is matched by the C<catch> elements, the content of this element 
will be evaluated.

=cut

sub else {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $outcode = qq!
};
if (\! defined \$__eval_error) {
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
