use 5.010;
use autodie;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Resource::ResultGraph::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Resource::ResultGraph::VERSION   = '0.001';
}

class WWW::DataWiki::Resource::ResultGraph
	extends WWW::DataWiki::Resource
	with WWW::DataWiki::Trait::QueryResult
	with WWW::DataWiki::Trait::RdfModel
	with WWW::DataWiki::Trait::Title
	with WWW::DataWiki::Trait::Negotiator
{
	has rs    => (is => 'ro', isa => 'RDF::Trine::Iterator::Graph', required => 1);
	has model => (is => 'rw', isa => 'RDF::Trine::Model', required => 0);
	
	method title_string
	{
		return 'Query Results';
	}

	method rdf_model
	{
		unless (defined $self->model)
		{
			$self->model(RDF::Trine::Model->new);
			while (my $st = $self->rs->next)
			{
				$self->model->add_statement($st);
			}
		}
		return $self->model;
	}
	
	method accepts_updates
	{
		0;
	}
}
