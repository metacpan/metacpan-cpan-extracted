use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Trait::Textual::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Trait::Textual::VERSION   = '0.001';
}

role WWW::DataWiki::Trait::Textual
	# for WWW::DataWiki::Resource
{
	use HTML::HTML5::Writer;
	
	requires 'dom';
	
	method available_formats
	{
		return (
			[WWW::DataWiki::FMT_XHTML, 1.0, 'application/xhtml+xml', undef, 'utf-8'],
			[WWW::DataWiki::FMT_HTML,  0.9, 'text/html',   undef, 'utf-8'],
			);
	}
	
	method extension_map
	{
		return {
			'.xhtml'=> 'application/xhtml+xml',
			'.html' => 'text/html',
			};
	}
	
	method _serialise_dom (%options)
	{
		return HTML::HTML5::Writer->new(%options)->document($self->dom);
	}
	
	method html
	{
		return $self->_serialise_dom(markup => 'html');
	}
	
	method xhtml
	{
		return $self->_serialise_dom(markup => 'xhtml', polyglot => 1);
	}
}

1;
