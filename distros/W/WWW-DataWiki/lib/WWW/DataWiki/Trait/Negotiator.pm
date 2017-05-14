use 5.010;
use utf8;
use MooseX::Declare;

BEGIN
{
	$WWW::DataWiki::Trait::Negotiator::AUTHORITY = 'cpan:TOBYINK';
	$WWW::DataWiki::Trait::Negotiator::VERSION   = '0.001';
}

role WWW::DataWiki::Trait::Negotiator
	# for WWW::DataWiki::Resource
{
	use HTTP::Headers qw[];
	use HTTP::Negotiate qw[];
	
	requires 'available_formats';
	requires 'extension_map';
	
	method media_type ($fmt)
	{
		foreach ($self->available_formats)
		{
			if (lc $_->[0] eq lc $fmt)
			{
				return wantarray ? ($_->[2], $_->[4]) : $_->[2];
			}
		}
		return wantarray ? ('application/octet-stream', 'utf-8') : 'application/octet-stream';
	}
	
	method extension_for ($media_type)
	{
		my %types = %{ $self->extension_map // {} };
		while (my ($ext, $mt) = each %types)
		{
			return $ext if lc $media_type eq lc $mt;
		}
	}
	
	method negotiate ($ctx)
	{
		my $request = $ctx->req;
		my $headers = $request->headers->clone;

		# Double-hack
		eval {
			# Hack
			if ($ctx->action->class eq 'WWW::DataWiki::Controller::Page')
			{
				my $extension = $ctx->request->captures->[1];
				my $type = defined $extension ? $self->extension_map->{$extension} : undef;
				if (defined $type)
					{ $headers->header(Accept => $type) }
			}
		};

		if (exists $request->query_params->{'accept'})
			{ $headers->header(Accept => $request->query_params->{'accept'}) }
		if (exists $request->query_params->{'accept-encoding'})
			{ $headers->header(Accept_Encoding => $request->query_params->{'accept-encoding'}) }
				
		my $gzip = (($headers->header('Accept-Encoding')//'') =~ /\bgzip\b/i);
		my $pref = HTTP::Negotiate::choose([$self->available_formats], $headers);
		my ($media, $charset) = $self->media_type($pref);

		$ctx->add_http_vary(qw/Negotiate Accept Accept-Encoding/);
		
		return ($pref, $media, $charset, $gzip);
	}
}

