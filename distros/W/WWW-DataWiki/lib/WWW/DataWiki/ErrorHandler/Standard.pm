use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::ErrorHandler::Standard::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::ErrorHandler::Standard::VERSION   = '0.001';
}

class WWW::DataWiki::ErrorHandler::Standard
	with WWW::DataWiki::Trait::Negotiator
{
	use HTML::HTML5::Builder qw[:standard link];
	use HTML::HTML5::Writer;
		
	method available_formats
	{
		return (
			['html',  1.0, 'text/html',   undef, 'utf-8'],
			['xhtml', 1.0, 'application/xhtml+xml', undef, 'utf-8'],
			['text',  0.5, 'text/plain', undef, 'utf-8'],
			);
	}
	
	method extension_map
	{
		return;
	}
	
	method emit ($ctx, $output)
	{
		my ($pref, $media, $charset, $gzip) = $self->negotiate($ctx);
		
		my ($error) = @{ $ctx->error // [] };
		my ($body, $writer);
		if ($pref eq 'text')
		{
			$body = $output;
		}
		else
		{
			$writer = HTML::HTML5::Writer->new(markup=>$pref, polyglot=>1);
		}
		
		$body //= $writer->document(
			html(
				head(
					title(-lang=>'en', $error->code, ': ', $error->message),
					style(-type=>'text/css', -media=>'screen,projection', sprintf('@import url(%s)', '/static/styles/error.css')),
					),
				body(
					h1(-lang=>'en', $error->message),
					p($error->explanation),
					($error->code >= 500 ? pre($output) : ''),
					),
				),
			);
		
		$ctx->set_http_status_code($error->code, $error->message);
		$ctx->res->content_type("$media; charset=$charset");
		my %hdrs = %{ $error->response_headers // {} };
		while (my ($h,$v) = each %hdrs)
		{
			$ctx->res->header($h, $v);
		}
		$ctx->res->body($body);
		$ctx->detach;
	}
}

1;
