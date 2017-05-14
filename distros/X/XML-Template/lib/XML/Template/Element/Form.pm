###############################################################################
# XML::Template::Element::Form
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Form;
use base qw(XML::Template::Element);

use strict;
use CGI;
use File::Spec;
use XML::Template::Element;


=pod

=head1 NAME

XML::Template::Element::Form - XML::Template plugin module for the
form namespace.

=head1 SYNOPSIS

This XML::Template plugin module implements the form namespace tagset.
The block namespace includes tags that simplify the creation of HTML 
forms.

=head1 CONSTRUCTOR

XML::Template::Element::Form inherits its constructor method, C<new>,
from L<XML::Template::Element>.

=head1 FORM TAGSET METHODS

=head2 select

This method implements the beginning of an HTML select form element.  The 
following attributes are used:

=over 4

=item name

The name of the select element.

=item default

The value of the option child to select by default.

=back

=cut

sub select {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name    = $self->get_attrib ($attribs, 'name')    || 'undef';
  my $default = $self->get_attrib ($attribs, 'default') || 'undef';

  my $outcode = qq!
  do {
    \$vars->create_context ();

    print "<select name=\\"" . $name . "\\">\n";

    my \$__default = $default;
    $code

    print "</select>\n";

    \$vars->delete_context ();
  };
  !;

  return $outcode;
}

=pod

=head2 option

This method implements the option section of an HTML select form element.  
The label of the option is contained in the content of this element The
following attributes are used:

=over 4

=item value

The value of the option.

=back

=cut

sub option {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $value = $self->get_attrib ($attribs, 'value') || 'undef';

  return '' if $value eq 'undef';

  my $outcode = qq!
  do {
    \$vars->create_context ();

    print "<option value=\\"" . $value . "\\"";
    print " selected" if $value eq \$__default;
    print ">";
    $code
    print "</option>\n";

    \$vars->delete_context ();
  };
  !;

  return $outcode;
}

=pod

=head2 upload

This method implements the upload tag, which is used to handle files 
uploaded via CGI.  The following attributes are used:

=over 4

=item name

The name of the upload form element used to upload the file.

=item dest

The file spec to which the uploaded file will be saved.

=back

=cut

sub upload {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name = $self->get_attrib ($attribs, 'name') || 'undef';
  my $dest = $self->get_attrib ($attribs, 'dest') || 'undef';

  my $outcode = qq!
do {
  \$vars->create_context ();

  my \$cgi = CGI->new ();
  my \$fh = \$cgi->param ($name);
  open (OUTFILE, ">" . $dest)
    || die XML::Template::Exception->new ('Upload', \$\!);
  my \$buffer = '';
  while (my \$bytesread = read (\$fh, \$buffer, 1024)) {
    print OUTFILE \$buffer;
  }
  close OUTFILE;

  \$vars->delete_context ();
};
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
