use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::View::General::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::View::General::VERSION   = '0.001';
}

class WWW::DataWiki::View::General
	extends Catalyst::View
{
	use CatalystX::Syntax::Action;
	use Digest::MD5 qw[md5_hex];
	
	action process
	{
		my $iri;
		my $resource = $ctx->stash->{resource};
		my ($pref, $media, $charset, $gzip) = $resource->negotiate($ctx);  # really should check is resource DOES Negotiator!
		my $ext = $resource->extension_for($media);
		$ext =~ s/^\.//;
		$ctx->stash(file_extension => $ext);
		
		my $body = do
			{
				if ($resource->DOES('WWW::DataWiki::Trait::RdfModel'))
				{
					$ctx->res->content_encoding('gzip') if $gzip;
					$resource->rdf_string_as($pref, $gzip);
				}
				elsif ($resource->DOES('WWW::DataWiki::Trait::ResultSet'))
				{
					$resource->rs_string_as($pref);
				}
				elsif ($resource->DOES('WWW::DataWiki::Trait::Textual'))
				{
					$media eq 'text/html' ? $resource->html : $resource->xhtml;
				}
				else
				{
					$ctx->set_http_status_code(204 => 'No Content');
					'';
				}
			};
		
		$ctx->res->headers->push_header(@$_) foreach $resource->http_headers($ctx);
		$ctx->res->headers->header(Vary => join q(, ), @{$ctx->stash->{http_vary} // []}); 
		
		# Only bother generating an ETag if GET/HEAD
		if ($ctx->req->method eq 'GET' or $ctx->req->method eq 'HEAD')
		{
			my $md5 = md5_hex($body);
			$ctx->res->headers->init_header(ETag => sprintf('"%s"', $md5));
			$ctx->res->headers->header(Content_MD5 => $md5);
		}
		$ctx->res->content_type("$media; charset=$charset");
		$ctx->res->body($body);
	}

}

1;
