package Text::Microformat::Element::hCard;
use warnings;
use strict;
use base 'Text::Microformat::Element';

__PACKAGE__->_init({
    criteria => {
        class => 'vcard',
    },
	schema => {
	    fn => [],
	    n => [qw/family-name given-name additional-name honorific-prefix honorific-suffix/],
	    nickname => [],
	    'sort-string' => [],
	    url => 'URI',
	    email => [qw/type value/],
	    tel => [qw/type value/],
	    adr => [qw/post-office-box extended-address street-address locality region postal-code country-name type value/],
	    label => [],
	    geo => [qw/latitude longitude/],
	    tz => [],
	    photo => 'URI',
	    logo => 'URI',
	    sound => 'URI',
	    bday => [],
	    title => [],
	    role => [],
	    org => [qw/organization-name organization-unit/],
	    category => [],
	    note => [],
	    class => [],
	    key => [],
	    mailer => [],
	    uid => [],
	    rev => [],
	},
});

package Text::Microformat::Element::hCard::HasValue;
use warnings;
use strict;
use base 'Text::Microformat::Element';

sub ToHash {
	my $self = shift;
	
	if ($self->value and @{$self->value}) {
		return $self->SUPER::ToHash;
	}
	else {
		return $self->Value;
	}
}

package Text::Microformat::Element::hCard::email;
use warnings;
use strict;
our @ISA = 'Text::Microformat::Element::hCard::HasValue';

package Text::Microformat::Element::hCard::tel;
use warnings;
use strict;
our @ISA = 'Text::Microformat::Element::hCard::HasValue';

=head1 NAME

Text::Microformat::Element::hCard - hCard plugin for Text::Microformat

=head1 SEE ALSO

L<Text::Microformat>, L<http://microformats.org/wiki/hcard>

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