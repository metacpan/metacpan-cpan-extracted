###############################################################################
# XML::Template::Element::Block::Load
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Block::Load;
use base qw(XML::Template::Base);

use strict;


=pod

=head1 NAME

XML::Template::Element::Block::Load - XML::Template loader module that 
loads documents from a database table.

=head1 SYNOPSIS

This module implements an XML::Template document loader that loads 
documents from a database table.

=head1 CONSTRUCTOR

A constructor method C<new> is provided by L<XML::Template::Base>.  A list
of named configuration parameters may be passed to the constructor.  The
constructor returns a reference to a new block loader object or under if
an error occurred.  If undef is returned, you can use the method C<error>
to retrieve the error.  For instance:

  my $parser = XML::Template::Element::Block::Load->new (%config)
    || die XML::Template::Element::Block::Load->error;

The following named configuration parameters may be passed to the
constructor:

=over 4

=item StripPattern

A regular expression that matches a substring to remove from the document 
name.

=back

=head1 PRIVATE METHODS

=head2 _init

This method is the internal initialization function called from
L<XML::Template::Base> when a new block loader object is created.

=cut

sub _init {
  my $self   = shift;
  my %params = @_;

  print ref ($self) . "->_init\n" if $self->{_debug};

  $self->{_strip_pattern} = $params{StripPattern} if defined $params{StripPattern};

  $self->{_enabled} = 1;

  return 1;
}

=pod

=head2 load

  my $document = $loader->load ($blockname);

This method loads an XML document from a database table and returns a new 
L<XML::Template::Document> object.

=cut

sub load {
  my $self      = shift;
  my $blockname = shift;

  print ref ($self) . "->load\n" if $self->{_debug};

  if (defined $self->{_strip_pattern}) {
    if ($blockname =~ /$self->{_strip_pattern}/) {
      $blockname = $1;
    }
  }

# XXX support multiple keys.

  my $namespace = 'http://syrme.net/xml-template/block/v1';
  my $source_mapping_info = $self->get_source_mapping_info (namespace => $namespace);
  my $db = $self->get_source ($source_mapping_info->{source});
  if (defined $db) {
    my ($xml) = $db->select (Field	=> 'body',
                             Table	=> $source_mapping_info->{table},
                             Where	=> "$source_mapping_info->{keys}='$blockname'");

    return XML::Template::Document->new (XML       => $xml,
                                         Source    => "source:$source_mapping_info->{source}:$source_mapping_info->{table}");
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
