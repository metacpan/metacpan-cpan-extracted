package Text::Microformat::Element::hGrant;
use warnings;
use strict;
use base 'Text::Microformat::Element';

__PACKAGE__->_init({
    criteria => {
        class => 'hgrant',
    },
	schema => {
		title => [],
	    period => [qw/dtstart dtend/],
	    grantee => 'hCard',
	    grantor => 'hCard',
	    description => [],
	    amount => [qw/currency amount/],
	    url => 'URI',
		id => [],
		'geo-focus' => [qw/country region locality postal-code/],
		'program-focus' => {
		    tags => '!rel-tag',
		},
		tags => '!rel-tag',
	},
});

=head1 NAME

Text::Microformat::Element::hGrant - hGrant plugin for Text::Microformat

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