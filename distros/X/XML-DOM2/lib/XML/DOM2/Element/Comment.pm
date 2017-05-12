package XML::DOM2::Element::Comment;

=head1 NAME

  XML::DOM2::Element::Comment

=head1 DISCRIPTION

  Comment element object class.

=head1 METHODS

=cut

use base "XML::DOM2::Element";

use strict;
use warnings;

=head2 $element->new( $name, %options )

  Create a new comment element object.

=cut
sub new
{
	my ($proto, $text, %args) = @_;
	$args{'text'} = $text;
	my $self = $proto->SUPER::new('comment', %args);
	return $self;
}

=head2 $element->xmlify()

  Returns the comment as xml.

=cut
sub xmlify
{
	my ($self, %p) = @_;
	my $sep = $p{'seperator'} || "\n";
	my $indent = ($p{'indent'} || '  ') x ( $p{'level'} || 0 );
	my $text = $self->{'text'};
	$text =~ s/$sep/$sep$indent/g;
	return $sep.$indent.'<!--'.$text.'-->';
}

=head2 $element->text()

  Return plain text (UTF-8)

=cut
sub text
{
	my ($self) = @_;
	return $self->{'text'} || '';
}

=head2 $element->setComment( $text )

  Replace comment with $text

=cut
sub setComment
{
	my ($self, $text) = @_;
	$self->{'text'} = $text;
}

=head2 $element->appendComment( $text )

  Append to the end of existing comment text $text

=cut
sub appendComment
{
	my ($self, $text) = @_;
	$self->{'text'} .= $text;
}

=head2 $element->_can_contain_elements()

  The element can not contain sub elements.

=cut
sub _can_contain_elements { 0 }

=head2 $element->_can_contain_attributes()

  The element can not contain attributes

=cut
sub _can_contain_attributes { 0 }

=head1 COPYRIGHT

Martin Owens, doctormo@cpan.org

=head1 SEE ALSO

L<XML::DOM2>,L<XML::DOM2::DOM::Element>

=cut
1;
