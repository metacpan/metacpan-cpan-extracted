use 5.010;
use autodie;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Resource::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Resource::VERSION   = '0.001';
}

class WWW::DataWiki::Resource
{
	has context => (is => 'ro', isa => 'Catalyst', required=>0);
	
	method http_headers ($ctx)
	{
		my @headers;

		if ($self->DOES('WWW::DataWiki::Trait::LastModified'))
		{
			push @headers, [Last_Modified => $self->last_modified_http];
		}

		if ($self->DOES('WWW::DataWiki::Trait::Title'))
		{
			push @headers, [Title => $self->title_string];
		}

		if ($self->DOES('WWW::DataWiki::Trait::RdfModel')
		and $self->accepts_updates)
		{
			push @headers, ['MS-Author-Via' => 'SPARQL'];
		}
		
		push @headers, ['Access-Control-Allow-Origin' => '*'];

		return @headers;
	}
}

1;