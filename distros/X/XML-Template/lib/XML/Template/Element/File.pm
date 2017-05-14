###############################################################################
# XML::Template::Element::File
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::File;
use base qw(XML::Template::Element XML::Template::Element::Iterator);

use strict;
use XML::Template::Element;


=pod

=head1 NAME

XML::Template::Element::File - XML::Template plugin module for the file
namespace.

=head1 SYNOPSIS

This XML::Template plugin module implements the file namespace tagset.
The block namespace includes tags that handle XML files as well as 
arbitrary files.

=head1 CONSTRUCTOR

XML::Template::Element::Block inherits its constructor method, C<new>,
from L<XML::Template::Element>.

=head1 FILE TAGSET METHODS

=head2 include

This method implements the include element.  It reads a file and if 
requested parses it.  The following attributes are used:

=over 4

=item name

The name of the file to include.  It can be an absolute file spec or a 
path relative to the include directory set for 
L<XML::Template::Element::File::Load>.

=item parse

If set to C<true>, the document will be parsed.  If set to C<false>, the
raw text of the document will be read in unparsed.  The default value is
C<true>.

=back

=cut

sub include {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $name  = $self->get_attrib ($attribs, 'name')  || 'undef';
  my $parse = $self->get_attrib ($attribs, 'parse') || "'true'";

  # Create attribute param code;
  my $attribs_named_params = $self->generate_named_params ($attribs);

  my $outcode = qq!
do {
  use XML::Template::Element::File::Load;

  \$vars->create_context ();

  my \%attribs = ($attribs_named_params);

  if ($parse =~ /^false\$/i) {
    open (FILE, $name)
      || die "Could not open " . $name . ": \$\!";
    while (<FILE>) {
      print \$_;
    }
    close (FILE);
    
  } else {
#    my \@old_load = \$process->load (XML::Template::Element::File::Load->new ());

    my \%loaded = \$process->get_load ();
    my \%tloaded;
    while (my (\$module, \$loaded) = each \%loaded) {
      if (\$module =~ /Cache/) {
        \$tloaded{\$module} = \$loaded;
      } else {
        \$tloaded{\$module} = 0;
      }
    }
    \$tloaded{'XML::Template::Element::File::Load'} = 1;
    \$process->set_load (\%tloaded);
    \$process->process ($name, \\\%attribs) || die \$process->error;
    \$process->set_load (\%loaded);

#    \$process->load (\@old_load);
  }

  \$vars->delete_context ();
};
!;

  return $outcode;
}

=pod

=head2 list

This method implements the list element, which displays a file listing.  
The following attributes are used:

=over 4

=item src

The name of the directory in which to display a file listing.

=item cols

The number of columns in the file listing.

=back

=cut

sub list {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $cols = $self->get_attrib ($attribs, 'cols')  || 'undef';
  my $src  = $self->get_attrib ($attribs, 'src') || 'undef';

  # Create attribute param code;
  my $attribs_named_params = $self->generate_named_params ($attribs);

  my $outcode = qq{
do {
  \$vars->create_context ();

  \$process->print (qq{<table border="0" cellspacing="5">\n});
  opendir (DIR, $src)
    || die XML::Template::Exception->new ('File', "Could not open directory '" . $src . "': \$!");
  while (my \$file = readdir (DIR)) {
    \$process->print ("  <tr>\n");
    for (my \$i = 0; \$i < int ($cols); \$i++) {
      \$process->print ("    <td>\$file</td>\n");
      \$file = readdir (DIR) || last;
    }
    \$process->print ("  </tr>\n");
  }
  closedir (DIR);
  \$process->print ("</table>\n");

  \$vars->delete_context ();
};
  };

  return $outcode;
}

=head2 foreach

XML::Template::Element::File is a subclass of
L<XML::Template::Element::Iterator>, so it inherits the C<foreach> method,
which in conjunction with the iterator methods defined in this module,
implements iteration through a list of files.

The following attributes are used:

=over 4

=item src

The name of the directory containing files to iterate through.

=item var

The name of the variable, available in the content of this element, that 
contains the current file name.

=back

For instance,

  <file:foreach xmlns:file="http://syrme.net/xml-template/file/v1"
                src="/home/jowaxman" var="file">
    file ${file}
  </file:foreach>

iterates through the files in the directory C</home/jowaxman> and prints 
each one.

=cut

sub loopinit {
  my $self    = shift;
  my $attribs = shift;

  my $src = $self->get_attrib ($attribs, 'src') || 'undef';
  my $var = $self->get_attrib ($attribs, 'var') || 'undef';

  my $outcode = qq!
  my \$__var = $var;
  if (-d $src) {
    opendir (DIR, $src)
      || die XML::Template::Exception->new ('File', \$\!);
    \@__array = readdir (DIR);
    closedir (DIR);
  } else {
    \@__array = ($src);
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
