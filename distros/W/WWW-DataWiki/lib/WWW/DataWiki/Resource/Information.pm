use 5.010;
use strict;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Resource::Information::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Resource::Information::VERSION   = '0.001';
}

class WWW::DataWiki::Resource::Information
	extends WWW::DataWiki::Resource
	with WWW::DataWiki::Trait::Textual
	with WWW::DataWiki::Trait::Title
	with WWW::DataWiki::Trait::Negotiator
{
	use HTML::HTML5::Builder qw[:standard];
	
	has dom => (is => 'ro', isa => 'XML::LibXML::Document');
	
	method new_from_string ($class: $title, $message?)
	{
		my $dom = html(
			head(
				title($title),
				style(-type=>'text/css', -media=>'screen,projection', sprintf('@import url(%s)', '/static/styles/page.css')),
				),
			body(
				h1($title),
				p($title // $message),
				WWW::DataWiki::Model::Wiki->standard_footer,
				),
			);
		
		return $class->new(dom => $dom);
	}
	
	method title_string
	{
		my @elements = $self->dom->getElementsByTagName('title');
		return $elements[0]->textContent;
	}
}

1;
