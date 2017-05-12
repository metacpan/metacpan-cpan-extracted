package XML::GRDDL::Transformation::XSLT_2;

use 5.008;
use strict;
use base qw[XML::GRDDL::Transformation];

use Scalar::Util qw[blessed];
use XML::LibXML;
use XML::Saxon::XSLT2 '0.003';

our $VERSION = '0.004';

sub transform
{
	my ($self, $input) = @_;
	
	# Use just documentElement because passing a DOCTYPE to Saxon can be fatal!
	if (blessed($input) && $input->isa('XML::LibXML::Document'))
	{
		$input = $input->documentElement->toString;
	}
	
	my $response = $self->response;
	
	my ($output, $type);
	local $@ = undef;
	eval {
		my $xslt = XML::Saxon::XSLT2->new($response->decoded_content, ''.$response->base);
		$type    = $xslt->media_type;
		$output  = $xslt->transform($input);
	};

	$type ||= ($output =~ m!<http://!) ? 'text/turtle' : 'application/rdf+xml';

	return ($output, $type) if wantarray;
	return $output;
}

1;

__END__

=head1 NAME

XML::GRDDL::Transformation::XSLT_2 - represents an XSLT 2.0 transformation

=head1 DESCRIPTION

Implements XSLT transformations. Uses L<XML::Saxon::XSLT2>.

XML::GRDDL::Transformation loads this module in an eval block, so
if you don't have XML::Saxon::XSLT2 then things shouldn't break too
badly - however you'll only be able to use XSLT 1.0.

=head1 SEE ALSO

L<XML::GRDDL>, L<XML::GRDDL::Transformation>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2010-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
