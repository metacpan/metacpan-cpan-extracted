package XML::GRDDL::Transformation::Hardcoded;

use 5.008;
use strict;
use base qw[XML::GRDDL::Transformation];

use HTTP::Headers;
use HTTP::Response;

our $VERSION = '0.004';
our %known;

sub content { return ''; }

sub response
{
	my ($self) = @_;
	
	return HTTP::Response->new(
		200,
		'OK',
		HTTP::Headers
			->new
			->header('Content-Base' => $self->{uri})
			->header('Content-Type' => 'application/xslt+xml'),
		$self->content,
		);
};

1;
__END__

=head1 NAME

XML::GRDDL::Transformation::Hardcoded - mechanism for hard-coding XSLT files

=head1 SEE ALSO

L<XML::GRDDL::Transformation>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
