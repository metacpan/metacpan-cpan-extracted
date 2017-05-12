# $Id: Image.pm 193 2009-01-16 13:42:25Z fish $
package WWW::MeGa::Item::Image;
use strict;
use warnings;

=head1 NAME

WWW::MeGa::Item::Image - Representing a image in L<WWW::MeGa>

=head1 DESCRIPTION

See L<WWW::MeGa::Item>

=head1 CHANGED METHODS

=cut

use base 'WWW::MeGa::Item';

our $VERSION = '0.11';


=head2 thumbnail_source

return the path to the image as a source for the thumbnail.
the image representation of a image is a image ;)

=cut

sub thumbnail_source
{
	my $self = shift;
	return $self->{path};
}

1;
