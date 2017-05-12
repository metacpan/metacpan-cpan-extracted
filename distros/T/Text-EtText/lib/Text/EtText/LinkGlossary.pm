
=head1 NAME

Text::EtText::LinkGlossary - interface for EtText link glossaries to implement.

=head1 SYNOPSIS

  use Text::EtText::LinkGlossary;

  @ISA = qw(Text::EtText::LinkGlossary);

  sub open { ... }
  sub close { ... }
  ...

=head1 DESCRIPTION

The C<Text::EtText::LinkGlossary> is an interface which allows EtText to support
''link glossaries'', persistent collections of link text and its corresponding
HREF.

The interface which needs to be implemented is as follows:

=head1 METHODS

=over 4

=cut

package Text::EtText::LinkGlossary;

use Carp;
use strict;

use vars qw{
	@ISA
};

@ISA = qw();

###########################################################################

=item $g->open()

Open the link glossary $g for reading and writing.

=cut

sub open {
  my ($self) = @_; croak "Unimplemented interface";
}

=item $g->close()

Close the link glossary; no more links can be written or read.

=cut

sub close {
  my ($self) = @_; croak "Unimplemented interface";
}

=item $url = $g->get_link ($name)

Get a named link from the glossary.

=cut

sub get_link {
  my ($self, $name) = @_; croak "Unimplemented interface";
}

=item $g->put_link ($name, $url)

Put a named link to the glossary.

=cut

sub put_link {
  my ($self, $name, $url) = @_; croak "Unimplemented interface";
}

=item $url = $g->get_auto_link ($name)

Get a named automatic link from the glossary.

=cut

sub get_auto_link {
  my ($self, $name) = @_; croak "Unimplemented interface";
}

=item $g->put_auto_link ($name, $url)

Put a named automatic link to the glossary.

=cut

sub put_auto_link {
  my ($self, $name, $url) = @_; croak "Unimplemented interface";
}

=item @keys = $g->get_auto_link_keys ()

Get a list of the names of automatic links stored in the glossary.

=cut

sub get_auto_link_keys {
  my ($self) = @_; croak "Unimplemented interface";
}

=item $g->add_auto_link_keys (@keys)

Add to the list of names of automatic links stored in the glossary.

=cut

sub add_auto_link_keys {
  my ($self, @keys) = @_; croak "Unimplemented interface";
}

1;
