package XML::GRDDL::Namespace;

use 5.008;
use strict;
use base qw[XML::GRDDL::External];

use RDF::Trine qw[iri];
use Scalar::Util qw[blessed];

our $VERSION = '0.004';

# hard-code certain namespaces to skip...
our @ignore = (
	'http://www.w3.org/1999/xhtml',
	'http://www.w3.org/2003/g/data-view',
	'http://www.w3.org/2003/g/data-view#',
	'http://www.w3.org/2005/Atom',
	);

sub ignore
{
	my ($class) = @_;
	return @ignore;
}

sub transformations
{
	my ($self) = @_;
	my $response = $self->{grddl}->_fetch(
		$self->{uri},
		Referer  => $self->{referer},
		Accept   => 'application/xhtml+xml, text/html, application/rdf+xml, text/turtle, application/xml;q=0.1, text/xml;q=0.1, */*;q=0.01',
		);
		
	my ($model, @transformations);
	$model = $self->{grddl}->_rdf_model($response->decoded_content, $response->base, $response->content_type);

	return
		unless blessed($model)
		&& $model->can('count_statements')
		&& $model->count_statements;

	my $iter = $model->get_statements(
		iri($self->{uri}),
		iri(XML::GRDDL::GRDDL_NS.'namespaceTransformation'),
		undef);
	while (my $st = $iter->next)
	{
		next unless $st->object->is_resource;
		push @transformations, $st->object->uri;
	}
	
	return @transformations;
}

1;

__END__

=head1 NAME

XML::GRDDL::Namespace - represents a namespace URI

=head1 DESCRIPTION

This module is used internally by XML::GRDDL and you probably don't want to mess with it.

C<< @XML::GRDDL::Namespace::ignore >> is an array of strings and regular expressions
for matching namespace URIs that should be ignored. You can fiddle with it, but it voids
your warranty.

The ignore list currently consists of the XHTML namespace, Atom namespace and the GRDDL
namespace itself.

Namespace documents many be written in any format supported by
RDF::RDFa::Parser or RDF::Trine::Parser, including RDF/XML, Turtle
and XHTML+RDFa.

=head1 SEE ALSO

L<XML::GRDDL>.

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
