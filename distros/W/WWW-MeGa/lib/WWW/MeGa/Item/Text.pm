# $Id: Text.pm 193 2009-01-16 13:42:25Z fish $
package WWW::MeGa::Item::Text;
use strict;
use warnings;

=head1 NAME

WWW::MeGa::Item::Text - Representing a text file in L<WWW::MeGa>

=head1 DESCRIPTION

See L<WWW::MeGa::Item>

=head1 CHANGED METHODS

=cut

use base 'WWW::MeGa::Item';

our $VERSION = '0.11';


=head1 data

gets the common data from C<SUPER::data>, puts the text file
content in C<$data->{CONTENT}> and return the data.

=cut

sub data
{
	my $self = shift;
	my $data = $self->SUPER::data;

	open my $fh, '<', $self->{path} or die $!;
	$data->{CONTENT} = <$fh>;
	close $fh;
	return $data;
}

1;
