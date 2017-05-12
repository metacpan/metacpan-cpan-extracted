package Text::Microformat::Element::hCal;
use warnings;
use strict;
use base 'Text::Microformat::Element';

__PACKAGE__->_init({
    criteria => {
        class => 'vevent',
    },
	schema => {
	    category => [],
	    class => [],
        description => [],
        dtend => [],
        dtstart => [],
        duration => [],
        location => [],
	    note => [],
        summary => [],
        status => [],
	    uid => [],
	    url => 'URI',
	},
});

=head1 NAME

Text::Microformat::Element::hCal - hCal plugin for Text::Microformat

=head1 SEE ALSO

L<Text::Microformat>, L<http://microformats.org/wiki/hcal>

=head1 AUTHOR

Franck Cuny, C<< <franck dot cuny at gmail.com> >>

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
