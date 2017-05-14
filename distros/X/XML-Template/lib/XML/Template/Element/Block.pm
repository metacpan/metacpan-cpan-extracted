###############################################################################
# XML::Template::Element::Block
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Block;
use base qw(XML::Template::Element::DB);

use strict;
use XML::Template::Element::DB;


=pod

=head1 NAME

XML::Template::Element::Block - XML::Template plugin module for the block 
namespace tagset.

=head1 SYNOPSIS

This XML::Template plugin module implements the block namespace tagset.  
The block namespace includes tags that handle XHTML blocks stored in a
database.

=head1 CONSTRUCTOR

XML::Template::Element::Block inherits its constructor method, C<new>,
from L<XML::Template::Element>.

=head1 BLOCK TAGSET METHODS

=head2 include

This method implements the include element.  It reads an XHTML block from 
a database table and parses it.  The following attributes are used:

=over 4

=item name

The name of the XHTML block to load.

=back

=cut

sub include {
  my $self = shift;
  my ($code, $attribs) = @_;

  # Create attribute param code;
  my $attribs_named_params = $self->generate_named_params ($attribs);

  my $name = $self->get_attrib ($attribs, 'name') || 'undef';

  my $outcode = qq!
do {
  use XML::Template::Element::Block::Load;

  \$vars->create_context ();
  my \%attribs = ($attribs_named_params);

  my \$cgi_header = \$process->{_cgi_header};
  \$process->{_cgi_header} = 0;
  my \$value;
  my \$io = IO::String->new (\$value);
  my \$ofh = select \$io;
  $code
  select \$ofh;
  \$vars->set ('_content' => \$value);
  \$process->{_cgi_header} = \$cgi_header;

  my \%vars;
  while (my (\$attrib, \$value) = each \%attribs) {
    my (\$attrib_namespace, \$attrib_name);
    if (\$attrib =~ /^{([^}]+)}(.*)\$/) {
      \$attrib_namespace = \$1;
      \$attrib_name = \$2;
    } else {
      \$attrib_namespace = '';
      \$attrib_name = \$attrib;
    }
    \$vars{\$attrib_name} = \$value;
  }

  my \%loaded = \$process->get_load ();
  my \%tloaded;
  while (my (\$module, \$loaded) = each \%loaded) {
    if (\$module =~ /Cache/) {
      \$tloaded{\$module} = \$loaded;
    } else {
      \$tloaded{\$module} = 0;
    }
  }
  \$tloaded{'XML::Template::Element::Block::Load'} = 1;
  \$process->set_load (\%tloaded);
  # XXX not sure why i did this, but now errors aren't detected here...
  if (ref (\$ofh) eq 'IO::String') {
    \$process->process ($name, \\\%vars);
  } else {
    \$process->process ($name, \\\%vars) || die \$process->error;
  }
  \$process->set_load (\%loaded);

  \$vars->delete_context ();
};
  !;

  return $outcode;
}

=pod

=head1 SQL TAGSET METHODS

XML::Template::Element::Block is a subclass of
L<XML::Template::Element::DB>, so derives the SQL tagset.  See
L<XML::Template::Element::DB> for more details.

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
