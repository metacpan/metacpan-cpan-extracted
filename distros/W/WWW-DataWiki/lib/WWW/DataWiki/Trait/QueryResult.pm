use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Trait::QueryResult::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Trait::QueryResult::VERSION   = '0.001';
}

role WWW::DataWiki::Trait::QueryResult
	# for WWW::DataWiki::Resource
{
	has rs      => (is => 'ro', isa => 'RDF::Trine::Iterator', required => 1);
	has query   => (is => 'ro', isa => 'RDF::Query', required => 0);
	has source  => (is => 'ro', isa => 'WWW::DataWiki::Resource', required => 0);
}

