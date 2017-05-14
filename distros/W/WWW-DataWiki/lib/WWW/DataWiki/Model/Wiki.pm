use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Model::Wiki::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Model::Wiki::VERSION   = '0.001';
}

class WWW::DataWiki::Model::Wiki
	extends Catalyst::Model
	is mutable
{	
	use HTML::HTML5::Builder qw[:standard link];
	
	has 'context' => (is => 'rw', isa => 'Catalyst');
	
	method ACCEPT_CONTEXT ($ctx)
	{
		$self->context($ctx);
		return $self;
	}
	
	method container ($wikiname)
	{
		return WWW::DataWiki->resource_class('Container')->new(
			wikiname => $wikiname,
			context  => $self->context,
			);
	}
	
	method page ($wikiname)
	{
		return WWW::DataWiki->resource_class('Page')->new(
			wikiname => $wikiname,
			context  => $self->context,
			);
	}
	
	method version ($wikiname, $version_string?)
	{
		my $page = $self->page($wikiname);
		return $page->latest_version unless defined $version_string;
		return $page->latest_version_as_of($version_string);
	}

	method standard_footer ($class:)
	{
		div(-class=>'footer', hr(),address(sprintf('Powered by WWW::DataWiki/%s (%s)', WWW::DataWiki->VERSION, WWW::DataWiki->AUTHORITY)));
	}
}

1;
