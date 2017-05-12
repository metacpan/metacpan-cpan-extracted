package Text::Microformat::Element::URI;
use warnings;
use strict;
use base 'Text::Microformat::Element';

sub MachineValue {
	my $self = shift;
	my $tag = defined $self->_element->local_name ? $self->_element->local_name : "";
	if ($tag eq 'a') {
		return $self->_element->attr('href');
	}
	elsif ($tag eq 'img') {
		return $self->_element->attr('src');
	}
	elsif ($tag eq 'object') {
		return $self->_element->attr('data');
	}
	else {
		return $self->SUPER::MachineValue;
	}
}

=head1 NAME

Text::Microformat::Element::URI - a Microformat URI element

=head1 SEE ALSO

L<Text::Microformat>, L<http://microformats.org>

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 BUGS

Log bugs and feature requests here: L<http://code.google.com/p/ufperl/issues/list>

=head1 SUPPORT

Project homepage: L<http://code.google.com/p/ufperl/>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;