###############################################################################
# XML::Template::Element::File::Load
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::File::Load;
use base qw(XML::Template::Base);

use strict;
use XML::Template::Document;


=pod

=head1 NAME

XML::Template::Element::File::Load - XML::Template loader module that
loads documents from files.

=head1 SYNOPSIS

This module implements an XML::Template document loader that loads
documents from files.

=head1 CONSTRUCTOR

A constructor method C<new> is provided by L<XML::Template::Base>.  A list
of named configuration parameters may be passed to the constructor.  The
constructor returns a reference to a new block loader object or under if
an error occurred.  If undef is returned, you can use the method C<error>
to retrieve the error.  For instance:

  my $parser = XML::Template::Element::File::Load->new (%config)
    || die XML::Template::Element::File::Load->error;

The following named configuration parameters may be passed to the
constructor:

=over 4

=item IncludePath

This is a reference to an array containing paths where XML::Template
documents will be searched for when loading.

=back

=head1 PRIVATE METHODS

=head2 _init

This method is the internal initialization function called from
L<XML::Template::Base> when a new file loader object is created.

=cut

sub _init {
  my $self   = shift;
  my %params = @_;

  print ref ($self) . "->_init\n" if $self->{_debug};

  $self->{_include_path} = $params{IncludePath}
    || XML::Template::Config->include_path
    || [''];

  $self->{_enabled} = 1;

  return 1;
}

=pod

=head2 load

This method loads an XML document from a file located in one of the 
directories listed in the IncludePath constructor parameter.  It returns a 
new L<XML::Template::Document> object.

=cut

sub load {
  my $self     = shift;
  my $filename = shift;

  print ref ($self) . "->load\n" if $self->{_debug};

  undef $self->{_error};

  my $xml;

  my $include_path = $self->{_include_path};
  # If file name is absolute, no need to search path.
  $include_path = [''] if $filename =~ /^\//;

  my $filespec;
  foreach my $path (@$include_path) {
    # If path is empty, do not prepend anything.
    $filespec = $path eq '' ? $filename : "$path/$filename";

    if (open (FILE, $filespec)) {
      $xml = '';
      while (my $line = <FILE>) {
        $line =~ s/\$(?!{)/\\\$/g;
        $line =~ s/&(?!amp)/&amp\;/g;
        $xml .= $line;
      }
      close (FILE);
      last;
    }
  }

  if (defined $xml) {
    return XML::Template::Document->new (XML       => $xml,
                                         Source    => "file:$filespec");
  } else {
    return undef;
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
