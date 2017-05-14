use 5.010;
use autodie;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Resource::ResultBindings::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Resource::ResultBindings::VERSION   = '0.001';
}

class WWW::DataWiki::Resource::ResultBindings
	extends WWW::DataWiki::Resource
	with WWW::DataWiki::Trait::QueryResult
	with WWW::DataWiki::Trait::ResultSet
	with WWW::DataWiki::Trait::Title
	with WWW::DataWiki::Trait::Negotiator
{
	has rs => (is => 'ro', isa => 'RDF::Trine::Iterator::Bindings', required => 1);

	method title_string
	{
		return 'Query Results';
	}
}
