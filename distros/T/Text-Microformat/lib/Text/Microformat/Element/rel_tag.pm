package Text::Microformat::Element::rel_tag;
use warnings;
use strict;
use base 'Text::Microformat::Element';

__PACKAGE__->_init({
    criteria => {
        rel => 'tag',
    },
});

sub MachineValue {
	my $self = shift;
	my $tag = defined $self->_element->local_name ? $self->_element->local_name : "";
	if ($tag eq 'a') {
		return $self->_element->attr('href');
	}
	else {
	    return undef;
	}
}

=head1 NAME

Text::Microformat::Element::rel_tag - a rel-tag element

=head1 SYNOPSIS

    To add rel-tag to a Text::Microformat schema:

    package Text::Microformat::Element::hMyFormat
    __PACKAGE__->init(
        'my-format',
        schema => {
            tags => 'rel-tag',
        }
    );
    
    To then retrieve tags from a Text::Microformat::Element::hMyFormat instance:
    
    foreach my $tag (@{$format->tags}) {
        print $tag->MachineValue, "\n"; # print the href
        print $tag->HumanValue, "\n"; # print the tag word
    }

=head1 SEE ALSO

L<Text::Microformat>, L<http://microformats.org/wiki/rel-tag>

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