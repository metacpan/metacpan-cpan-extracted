{

=head1 NAME

XML::Filter::XML_Directory_2RSS::Items - SAX2 filter for adding channel items for XML::Filter::XML_Directory_2RSS

=head1 SYNOPSIS

 There is none. 

=head1 DESCRIPTION

SAX2 filter for adding channel items for XML::Filter::XML_Directory_2RSS. 

This is used internally by XML::Filter::XML_Directory_2RSS.

=cut

package XML::Filter::XML_Directory_2RSS::Items;
use strict;

use base qw (XML::Filter::XML_Directory_2RSS::Base);

$XML::Filter::XML_Directory_2RSS::Items::VERSION = 1.0;

sub start_document {}
sub end_document {}

sub start_element {
  my $self = shift;
  my $data = shift;

  $self->on_enter_start_element($data) || return;

  if ($data->{Name} =~ /^(file|directory)$/) {

    $self->{'__dlevel'} ++;

    if ($self->{'__dlevel'} == 1) {
      $self->SUPER::start_element({
				   Name       => "rdf:li",
				   Attributes => $self->rdf_resource($self->make_link($data)),
				   });
      $self->SUPER::end_element({Name=>"rdf:li"});
    }
  }

  return 1;
}

sub end_element {
  my $self = shift;
  my $data = shift;  

  $self->on_enter_end_element($data);

  if (($self->{'__start'}) && (! $self->{'__skip'})) {
    if ($data->{Name} =~ /^(file|directory)$/) {

      $self->prune_cwd($data);

      if ($self->{'__dlevel'}) {
	$self->{'__dlevel'} --;
      }
    }
  }

  $self->on_exit_end_element();
  return 1;
}

sub characters {
  my $self = shift;
  my $data = shift;
  $self->on_characters($data);
}

=head1 VERSION

1.0

=head1 DATE

May 13, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<XML::Filter::XML_Directory_2RSS>

=head1 LICENSE

Copyright (c) 2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
