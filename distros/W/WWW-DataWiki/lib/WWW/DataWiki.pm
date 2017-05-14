package WWW::DataWiki;

use 5.010;
use utf8;
use MooseX::Declare;
use UNIVERSAL::AUTHORITY;

BEGIN
{
	$WWW::DataWiki::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::VERSION   = '0.001';
}

class WWW::DataWiki
	extends Catalyst
	is mutable
{
	use Catalyst::Runtime 5.80;
	use Catalyst qw/
		ConfigLoader
		Static::Simple
		Cache::HTTP
		ErrorCatcher
		StackTrace
		/;
	use CatalystX::RoleApplicator;

	# For a live server, disable "-Debug" above, and enable Plugin::ErrorCatcher module in config
	
	use constant {
		FMT_N3     => 'Notation3',
		FMT_TTL    => 'Turtle',
		FMT_NT     => 'NTriples',
		FMT_XML    => 'RDFXML',
		FMT_XHTML  => 'XHTML',
		FMT_HTML   => 'HTML',
		FMT_JSON   => 'RDFJSON',
		};

	use constant {
		FMT_RS_XML   => 'xml',
		FMT_RS_JSON  => 'json',
		FMT_RS_TEXT  => 'txt',
		FMT_RS_HTML  => 'html',
		FMT_RS_XHTML => 'xhtml',
		FMT_RS_CSV   => 'csv',
		FMT_RS_TSV   => 'tab',
		};

	__PACKAGE__->config(
		name => __PACKAGE__,
		disable_component_resolution_regex_fallback => 1,
		'Plugin::ErrorCatcher' => {
			enable       => 1,
			emit_module  => join('::', __PACKAGE__, ErrorHandler => 'Standard'),
			},
		stacktrace => {
			enable       => 1,
			},
		resource_class => {
			Container      => join('::', __PACKAGE__, Resource => 'Container'),
			Information    => join('::', __PACKAGE__, Resource => 'Information'),
			Page           => join('::', __PACKAGE__, Resource => 'Page'),
			ResultBindings => join('::', __PACKAGE__, Resource => 'ResultBindings'),
			ResultGraph    => join('::', __PACKAGE__, Resource => 'ResultGraph'),
			Version        => join('::', __PACKAGE__, Resource => 'Version'),
			},
	);

	has 'storage' => (is => 'ro', isa => 'Str');

	method resource_class ($class: Str $klass)
	{
		my $full_class = $class->config->{resource_class}->{$klass}
			or die "Resource class '$klass' unknown: $@";
		eval "use $full_class; 1"
			or die "Resource class '$full_class' could not be loaded: $@";
		return $full_class;
	}

	method set_http_status_code ($code, $message?)
	{
		$self->stash(http_status_code    => $code);
		$self->stash(http_status_message => $message) if defined $message;

		$self->res->status($code);
		$self->res->header('X-Real-HTTP-Header-Before-Plack-Mangled-It' => "$code $message");
	}

	method add_http_vary (@headers)
	{
		$self->stash->{http_vary} = [] unless defined $self->stash->{http_vary};
		push @{$self->stash->{http_vary}}, map {lc} @headers;
	}

	__PACKAGE__->apply_dispatcher_class_roles(qw/CatalystX::TraitFor::Dispatcher::ExactMatch/);
	__PACKAGE__->setup();
	__PACKAGE__->meta->make_immutable(replace_constructor => 1);
}

use WWW::DataWiki::Exception;
use WWW::DataWiki::Utils;

'RESTful read-write RDF repository';

__END__

=head1 NAME

WWW::DataWiki - RESTful read-write RDF repository

=head1 SYNOPSIS

  script/www_datawiki_server.pl

=head1 DESCRIPTION

WWW::DataWiki is a RESTful read-write RDF repository. Powered by Catalyst,
RDF::Trine and RDF::Query, it provides you with a wiki-like site where each
page, rather than being a textual document is an RDF graph (actually,
technically it's an N3 graph, so supports a slight superset of RDF).

Graphs are versioned, and each graph (each version in fact) acts as its own
SPARQL endpoint. HTTP content negotiation serves up graph data as HTML, Turtle,
RDF/XML, JSON; and query results as HTML, XML, JSON, CSV or tab-delimited data.

WWW::DataWiki is fully RESTful, using HTTP B<GET> to retrieve the graph,
HTTP B<PUT> to replace the graph with a new version, HTTP B<DELETE> to replace
the graph with an empty graph (and there may be an option in the future to
delete the graph and its entire history), HTTP B<POST> to append RDF data to the
graph, and HTTP B<PATCH> to alter the graph using the SPARQL Update language.
(SPARQL Query and Update can also be tunnelled over B<POST>; and SPARQL
Query can be tunnelled over B<GET>.)

WWW::DataWiki exposes graph history using the HTTP headers described at
L<http://www.mementoweb.org/>.

WWW::DataWiki offers some rudimentary support for RFC 2324.

In the current release there is very little user interface, and to manage graphs
you probably need to use a command-line tool like C<curl> or C<lwp-request>.

There is currently no support for authentication or access control. You may
be able to use external forms of access control. 

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=WWW-DataWiki>.

=head1 SEE ALSO

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

