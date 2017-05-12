package XML::GRDDL::Transformation::XSLT_1;

use 5.008;
use strict;
use base qw[XML::GRDDL::Transformation];

use Scalar::Util qw[blessed];
use XML::LibXML;
use XML::LibXSLT;

our $VERSION = '0.004';

sub transform
{
	my ($self, $input) = @_;
	
	my $response = $self->response;
	
	my $parser    = XML::LibXML->new();
	$parser->base_uri($response->base);
	my $style_doc = $parser->parse_string($response->content);
	my $xslt      = XML::LibXSLT->new();
	my $stylesheet;
	local $@ = undef;
	eval { $stylesheet = $xslt->parse_stylesheet($style_doc); };
	warn $@ if $@;

	if ($stylesheet && !$@)
	{
		unless (blessed($input) && $input->isa('XML::LibXML::Document'))
		{
			$parser->base_uri($self->{referer});
			$input = $parser->parse_string($input);
		}
		
		my $results = $stylesheet->transform($input);	
		
		return ($stylesheet->output_as_chars($results), $stylesheet->media_type) if wantarray;
		return $stylesheet->output_as_chars($results);
	}
	
	return;
}

1;

__END__

=head1 NAME

XML::GRDDL::Transformation::XSLT_1 - represents an XSLT transformation

=head1 DESCRIPTION

Implements XSLT transformations. Uses L<XML::LibXSLT>, so
supports whatever XSLT is supported by libxslt should work.

=head1 SEE ALSO

L<XML::GRDDL>, L<XML::GRDDL::Transformation>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
