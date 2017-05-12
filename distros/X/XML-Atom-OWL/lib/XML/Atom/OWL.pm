package XML::Atom::OWL;

use 5.010;
use common::sense;

use Carp 1.00;
use DateTime 0;
use Encode 0 qw(encode_utf8);
use HTTP::Link::Parser 0.100;
use LWP::UserAgent 0;
use MIME::Base64 0 qw(decode_base64);
use RDF::Trine 0.135;
use Scalar::Util 0 qw(blessed);
use URI 1.30;
use XML::LibXML 1.70 qw(:all);

use constant AAIR_NS  => 'http://xmlns.notu.be/aair#';
use constant ATOM_NS  => 'http://www.w3.org/2005/Atom';
use constant AWOL_NS  => 'http://bblfish.net/work/atom-owl/2006-06-06/#';
use constant AS_NS    => 'http://activitystrea.ms/spec/1.0/';
use constant AX_NS    => 'http://buzzword.org.uk/rdf/atomix#';
use constant FH_NS    => 'http://purl.org/syndication/history/1.0';
use constant FOAF_NS  => 'http://xmlns.com/foaf/0.1/';
use constant IANA_NS  => 'http://www.iana.org/assignments/relation/';
use constant RDF_NS   => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
use constant RDF_TYPE => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
use constant THR_NS   => 'http://purl.org/syndication/thread/1.0';
use constant XSD_NS   => 'http://www.w3.org/2001/XMLSchema#';

our $VERSION = '0.104';

sub new
{
	my $class   = shift;
	my $content = shift;
	my $baseuri = shift;
	my $options = shift || undef;
	my $store   = shift || undef;
	my $domtree;
	
	unless (defined $content)
	{
		my $ua = LWP::UserAgent->new;
		$ua->agent(sprintf('%s/%s ', __PACKAGE__, $VERSION));
		$ua->default_header("Accept" => "application/atom+xml, application/xml;q=0.1, text/xml;q=0.1");
		my $response = $ua->get($baseuri);
		croak "HTTP response not successful\n"
			unless $response->is_success;
		croak "Non-Atom HTTP response\n"
			unless $response->content_type =~ m`^(text/xml)|(application/(atom\+xml|xml))$`;
		$content = $response->decoded_content;
	}

	if (blessed($content) and $content->isa('XML::LibXML::Document'))
	{
		($domtree, $content) = ($content, $content->toString);
	}
	else
	{
		my $xml_parser = XML::LibXML->new;
		$domtree = $xml_parser->parse_string($content);
	}

	$store = RDF::Trine::Store::DBI->temporary_store
		unless defined $store;

	my $self = bless {
		'content'   => $content,
		'baseuri'   => $baseuri,
		'options'   => $options,
		'DOM'       => $domtree,
		'sub'       => {},
		'RESULTS'   => RDF::Trine::Model->new($store),
		}, $class;

	return $self;
}

sub uri
{
	my $this  = shift;
	my $param = shift || '';
	my $opts  = shift || {};
	
	if ((ref $opts) =~ /^XML::LibXML/)
	{
		my $x = {'element' => $opts};
		$opts = $x;
	}
	
	if ($param =~ /^([a-z][a-z0-9\+\.\-]*)\:/i)
	{
		# seems to be an absolute URI, so can safely return "as is".
		return $param;
	}
	elsif ($opts->{'require-absolute'})
	{
		return undef;
	}
	
	my $base = $this->{baseuri};
	if ($opts->{'element'})
	{
		$base = $this->get_node_base($opts->{'element'});
	}
	
	my $url = URI->new($param);
	my $rv  = $url->abs($base)->as_string;

	while ($rv =~ m!^(http://.*)(\.\./|\.)+(\.\.|\.)?$!i)
	{
		$rv = $1;
	}
	
	return $rv;
}

sub dom
{
	my $this = shift;
	return $this->{DOM};
}


sub graph
{
	my $this = shift;
	$this->consume;
	return $this->{RESULTS};
}

sub graphs
{
	my $this = shift;
	$this->consume;
	return { $this->{'baseuri'} => $this->{RESULTS} };
}

sub root_identifier
{
	my $self = shift;
	$self->consume;
	if ($self->{'root_identifier'} =~ /^_:(.*)/)
	{
		return RDF::Trine::Node::Blank->new($1);
	}
	else
	{
		return RDF::Trine::Node::Resource->new($self->{'root_identifier'});
	}
}

sub set_callbacks
# Set callback functions for handling RDF triples.
{
	my $this = shift;

	if ('HASH' eq ref $_[0])
	{
		$this->{'sub'} = $_[0];
	}
	elsif (defined $_[0])
	{
		die("What kind of callback hashref was that??\n");
	}
	else
	{
		$this->{'sub'} = undef;
	}
	
	return $this;
}

sub consume
{
	my $self = shift;

	return $self if $self->{'comsumed'};

	my $root = $self->dom->documentElement;
	
	if ($root->namespaceURI eq ATOM_NS and $root->localname eq 'feed')
	{
		$self->{'root_identifier'} = $self->consume_feed($root);
	}
	elsif ($root->namespaceURI eq ATOM_NS and $root->localname eq 'entry')
	{
		$self->{'root_identifier'} = $self->consume_entry($root);
	}
	
	$self->{'comsumed'}++;
	
	return $self;
}

sub consume_feed
{
	my $self = shift;
	my $feed = shift;
	my $skip_entries = shift || 0;
	
	# Feed
	my $feed_identifier = $self->bnode($feed);
	$self->rdf_triple($feed, $feed_identifier, RDF_TYPE, AWOL_NS.'Feed');

	# Common stuff
	$self->consume_feed_or_entry($feed, $feed_identifier);

	# fh:archive and fh:complete
	if ($feed->getChildrenByTagNameNS(FH_NS, 'archive'))
	{
		$self->rdf_triple($feed, $feed_identifier, RDF_TYPE, AX_NS.'ArchiveFeed');
	}
	my $complete = 0;
	if ($feed->getChildrenByTagNameNS(FH_NS, 'complete'))
	{
		$complete = 1;
		$self->rdf_triple($feed, $feed_identifier, RDF_TYPE, AX_NS.'CompleteFeed');
	}
	
	my $last_listid;

	# entry
	unless ($skip_entries)
	{
		my @elems = $feed->getChildrenByTagNameNS(ATOM_NS, 'entry');
		foreach my $e (@elems)
		{
			my $entry_identifier = $self->consume_entry($e);
			$self->rdf_triple($e, $feed_identifier, AWOL_NS.'entry', $entry_identifier);

			# If this feed is known to be complete, include an rdf:List
			# to assist in open-world reasoning.
			if ($complete)
			{
				my $listid = $self->bnode;
				if (defined $last_listid)
				{
					$self->rdf_triple($e, $last_listid, RDF_NS.'rest', $listid);
				}
				else
				{
					$self->rdf_triple($e, $feed_identifier, AX_NS.'entry-list', $listid);
				}
				$self->rdf_triple($e, $listid, RDF_TYPE, RDF_NS.'List');
				$self->rdf_triple($e, $listid, RDF_NS.'first', $entry_identifier);
				$last_listid = $listid;
			}
		}
	}
	if ($complete)
	{
		if (defined $last_listid)
		{
			$self->rdf_triple($feed, $last_listid, RDF_NS.'rest', RDF_NS.'nil');
		}
		else
		{
			$self->rdf_triple($feed, $feed_identifier, AX_NS.'entry-list', RDF_NS.'nil');
		}
	}
	
	# icon and logo
	foreach my $role (qw(icon logo))
	{
		my @elems = $feed->getChildrenByTagNameNS(ATOM_NS, $role);
		foreach my $e (@elems)
		{
			my $img = $self->uri($e->textContent, $e);
			$self->rdf_triple($e, $feed_identifier, AWOL_NS.$role, $img);
			$self->rdf_triple($e, $img, RDF_TYPE, FOAF_NS.'Image');
		}
	}

	# generator
	{
		my @elems = $feed->getChildrenByTagNameNS(ATOM_NS, 'generator');
		foreach my $e (@elems)
		{
			my $gen_identifier = $self->consume_generator($e);
			$self->rdf_triple($e, $feed_identifier, AWOL_NS.'generator', $gen_identifier);
		}
	}
	
	# subtitle
	{
		my @elems = $feed->getChildrenByTagNameNS(ATOM_NS, 'subtitle');
		foreach my $e (@elems)
		{
			my $content_identifier = $self->consume_textconstruct($e);
			$self->rdf_triple($e, $feed_identifier, AWOL_NS.'subtitle', $content_identifier);
		}
	}

	return $feed_identifier;
}

sub consume_entry
{
	my $self  = shift;
	my $entry = shift;
	
	# Entry
	my $entry_identifier = $self->bnode($entry);
	$self->rdf_triple($entry, $entry_identifier, RDF_TYPE, AWOL_NS.'Entry');

	# Common stuff
	$self->consume_feed_or_entry($entry, $entry_identifier);
	
	# published
	{
		my @elems = $entry->getChildrenByTagNameNS(ATOM_NS, 'published');
		foreach my $e (@elems)
		{
			$self->rdf_triple_literal($e, $entry_identifier, AWOL_NS.'published', $e->textContent, XSD_NS.'dateTime');
		}
	}

	# summary
	{
		my @elems = $entry->getChildrenByTagNameNS(ATOM_NS, 'content');
		foreach my $e (@elems)
		{
			my $content_identifier = $self->consume_content($e);
			$self->rdf_triple($e, $entry_identifier, AWOL_NS.'content', $content_identifier);
		}
	}
	
	# source
	{
		my @elems = $entry->getChildrenByTagNameNS(ATOM_NS, 'source');
		foreach my $e (@elems)
		{
			my $feed_identifier = $self->consume_feed($e, 1);
			$self->rdf_triple($e, $entry_identifier, AWOL_NS.'source', $feed_identifier);
		}
	}

	# summary
	{
		my @elems = $entry->getChildrenByTagNameNS(ATOM_NS, 'summary');
		foreach my $e (@elems)
		{
			my $content_identifier = $self->consume_textconstruct($e);
			$self->rdf_triple($e, $entry_identifier, AWOL_NS.'summary', $content_identifier);
		}
	}

	# thr:in-reply-to
	{
		my @elems = $entry->getChildrenByTagNameNS(THR_NS, 'in-reply-to');
		foreach my $e (@elems)
		{
			my $irt_id = $self->consume_inreplyto($e);
			$self->rdf_triple($e, $entry_identifier, AX_NS.'in-reply-to', $irt_id);
		}
	}

	# thr:total
	{
		my @elems = $entry->getChildrenByTagNameNS(THR_NS, 'total');
		foreach my $e (@elems)
		{
			my $total = $e->textContent;
			$self->rdf_triple_literal($e, $entry_identifier, AX_NS.'total', $total, XSD_NS.'integer');
		}
	}
	
	return $entry_identifier;
}

sub consume_feed_or_entry
{
	my $self = shift;
	my $fore = shift;
	my $id   = shift;
	
	my @elems = $fore->getChildrenByTagNameNS(ATOM_NS, 'id');
	foreach my $e (@elems)
	{
		my $_id = $self->uri($e->textContent, $e);
		$self->rdf_triple_literal($e, $id, AWOL_NS.'id', $_id, XSD_NS.'anyURI');
	}
	
	my $is_as = 0;
	
	# activitystreams:object, activitystreams:target
	foreach my $role (qw(object target))
	{
		my @elems = $fore->getChildrenByTagNameNS(AS_NS, $role);
		foreach my $e (@elems)
		{
			$is_as++;
			my $obj_id = $self->consume_entry($e, $id);
			$self->rdf_triple($e, $id, AAIR_NS.'activity'.ucfirst($role), $obj_id);
		}
	}

	# activitystreams:verb
	{
		my @elems = $fore->getChildrenByTagNameNS(AS_NS, 'verb');
		foreach my $e (@elems)
		{
			$is_as++;
			my $url = $e->textContent;
			$url =~ s/(^\s*)|(\s*$)//g;
			$self->rdf_triple($e, $id, AAIR_NS.'activityVerb', URI->new($url)->abs('http://activitystrea.ms/schema/1.0/')->as_string);
		}
		if ($is_as && !@elems)
		{
			$self->rdf_triple($fore, $id, AAIR_NS.'activityVerb', "http://activitystrea.ms/schema/1.0/post");
		}
	}

	# activitystreams:object-type
	{
		my @elems = $fore->getChildrenByTagNameNS(AS_NS, 'object-type');
		foreach my $e (@elems)
		{
			my $url = $e->textContent;
			$url =~ s/(^\s*)|(\s*$)//g;
			$self->rdf_triple($e, $id, RDF_NS.'type', URI->new($url)->abs('http://activitystrea.ms/schema/1.0/')->as_string);
		}
	}

	# authors and contributors
	foreach my $role (qw(author contributor))
	{
		my @elems = $fore->getChildrenByTagNameNS(ATOM_NS, $role);
		foreach my $e (@elems)
		{
			my $person_identifier = $self->consume_person($e);
			$self->rdf_triple($e, $id, AWOL_NS.$role, $person_identifier);
			
			if ($role eq 'author' and $is_as)
			{
				$self->rdf_triple($e, $person_identifier, RDF_NS.'type', AAIR_NS.'Actor');
				$self->rdf_triple($e, $id, AAIR_NS.'activityActor', $person_identifier);
			}
		}
	}

	# updated
	{
		my @elems = $fore->getChildrenByTagNameNS(ATOM_NS, 'updated');
		foreach my $e (@elems)
		{
			$self->rdf_triple_literal($e, $id, AWOL_NS.'updated', $e->textContent, XSD_NS.'dateTime');
		}
	}

	# link
	{
		my @elems = $fore->getChildrenByTagNameNS(ATOM_NS, 'link');
		foreach my $e (@elems)
		{
			my $link_identifier = $self->consume_link($e, $id);
			$self->rdf_triple($e, $id, AWOL_NS.'link', $link_identifier);
		}
	}

	# title and rights
	foreach my $role (qw(title rights))
	{
		my @elems = $fore->getChildrenByTagNameNS(ATOM_NS, $role);
		foreach my $e (@elems)
		{
			my $content_identifier = $self->consume_textconstruct($e);
			$self->rdf_triple($e, $id, AWOL_NS.$role, $content_identifier);
		}
	}
	
	# category
	{
		my @elems = $fore->getChildrenByTagNameNS(ATOM_NS, 'category');
		foreach my $e (@elems)
		{
			my $cat_identifier = $self->consume_category($e, $id);
			$self->rdf_triple($e, $id, AWOL_NS.'category', $cat_identifier);
		}
	}

	# Unknown Extensions!
	{
		my @elems = $fore->getChildrenByTagName('*');
		foreach my $e (@elems)
		{
			next if $e->namespaceURI eq ATOM_NS;
			next if $e->namespaceURI eq AS_NS;
			next if $e->namespaceURI eq FH_NS;
			next if $e->namespaceURI eq THR_NS;
			
			my $xml = $self->xmlify_inclusive($e);
			$self->rdf_triple_literal($e, $id, AX_NS.'extension-element', $xml, RDF_NS.'XMLLiteral');
		}
	}

	return $id;
}

sub consume_textconstruct
{
	my $self = shift;
	my $elem = shift;
	
	my $id = $self->bnode($elem);
	$self->rdf_triple($elem, $id, RDF_TYPE, AWOL_NS.'TextContent');
	
	my $lang = $self->get_node_lang($elem);
	
	if (lc $elem->getAttribute('type') eq 'xhtml')
	{
		my $cnt = $self->xmlify($elem, $lang);
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'xhtml', $cnt, RDF_NS.'XMLLiteral');
	}

	elsif (lc $elem->getAttribute('type') eq 'html')
	{
		my $cnt = $elem->textContent;
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'html', $cnt, undef, $lang);
	}

	else
	{
		my $cnt = $elem->textContent;
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'text', $cnt, undef, $lang);
	}
	
	return $id;
}

sub consume_content
{
	my $self = shift;
	my $elem = shift;
	
	my $id = $self->bnode($elem);
	$self->rdf_triple($elem, $id, RDF_TYPE, AWOL_NS.'Content');
	
	my $lang = $self->get_node_lang($elem);
	my $base = $self->get_node_base($elem);
	
	if ($elem->hasAttribute('src'))
	{
		my $link = $self->uri($elem->getAttribute('src'), $elem);
		$self->rdf_triple($elem, $id, AWOL_NS.'src', $link);
		
		if ($self->{'options'}->{'no_fetch_content_src'})
		{
			$self->rdf_triple_literal($elem, $id, AWOL_NS.'type', $elem->getAttribute('type'))
				if $elem->hasAttribute('type');
		}
		else
		{
			my $ua = LWP::UserAgent->new;
			$ua->agent(sprintf('%s/%s ', __PACKAGE__, $VERSION));
			if ($elem->hasAttribute('type'))
			{
				$ua->default_header("Accept" => $elem->getAttribute('type').", */*;q=0.1");
			}
			else
			{
				$ua->default_header("Accept" => "application/xhtml+xml, text/html, text/plain, */*;q=0.1");
			}
			my $response = $ua->get($self->uri($elem->getAttribute('src'), $elem));
			if ($response->is_success)
			{
				$self->rdf_triple_literal($elem, $id, AWOL_NS.'body', $response->decoded_content);
				
				if ($response->content_type)
					{ $self->rdf_triple_literal($elem, $id, AWOL_NS.'type', $response->content_type); }
				elsif ($elem->hasAttribute('type'))
					{ $self->rdf_triple_literal($elem, $id, AWOL_NS.'type', $elem->getAttribute('type')); }

				if ($response->content_language =~ /^\s*([a-z]{2,3})\b/i)
					{ $self->rdf_triple_literal($elem, $id, AWOL_NS.'lang', lc $1, XSD_NS.'language'); }

				if ($response->base)
					{ $self->rdf_triple($elem, $id, AWOL_NS.'base', $response->base); }
			}
			else
			{
				$self->rdf_triple_literal($elem, $id, AWOL_NS.'type', $elem->getAttribute('type'))
					if $elem->hasAttribute('type');
			}
		}
	}
	
	elsif (lc $elem->getAttribute('type') eq 'text' or !$elem->hasAttribute('type'))
	{
		my $cnt = $elem->textContent;
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'body', $cnt, undef, $lang);
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'type', 'text/plain');
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'lang', $lang, XSD_NS.'language') if $lang;
		$self->rdf_triple($elem, $id, AWOL_NS.'base', $base) if $base;
	}
	
	elsif (lc $elem->getAttribute('type') eq 'xhtml')
	{
		my $cnt = $self->xmlify($elem, $lang);
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'body', $cnt, RDF_NS.'XMLLiteral');
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'type', 'application/xhtml+xml');
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'lang', $lang, XSD_NS.'language') if $lang;
		$self->rdf_triple($elem, $id, AWOL_NS.'base', $base) if $base;
	}

	elsif (lc $elem->getAttribute('type') eq 'html')
	{
		my $cnt = $elem->textContent;
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'body', $cnt, undef, $lang);
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'type', 'text/html');
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'lang', $lang, XSD_NS.'language') if $lang;
		$self->rdf_triple($elem, $id, AWOL_NS.'base', $base) if $base;
	}

	elsif ($elem->getAttribute('type') =~ m'([\+\/]xml)$'i)
	{
		my $cnt = $self->xmlify($elem, $lang);
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'body', $cnt, RDF_NS.'XMLLiteral');
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'type', $elem->getAttribute('type'));
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'lang', $lang, XSD_NS.'language') if $lang;
		$self->rdf_triple($elem, $id, AWOL_NS.'base', $base) if $base;
	}
	
	elsif ($elem->getAttribute('type') =~ m'^text\/'i)
	{
		my $cnt = $elem->textContent;
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'body', $cnt, undef, $lang);
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'type', $elem->getAttribute('type'));
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'lang', $lang, XSD_NS.'language') if $lang;
		$self->rdf_triple($elem, $id, AWOL_NS.'base', $base) if $base;
	}
	
	elsif ($elem->hasAttribute('type'))
	{
		my $cnt = $elem->textContent;
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'body', decode_base64($cnt));
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'type', $elem->getAttribute('type'));
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'lang', $lang, XSD_NS.'language') if $lang;
		$self->rdf_triple($elem, $id, AWOL_NS.'base', $base) if $base;
	}

	return $id;
}

sub consume_person
{
	my $self   = shift;
	my $person = shift;
	
	# Person
	my $person_identifier = $self->bnode($person);
	$self->rdf_triple($person, $person_identifier, RDF_TYPE, AWOL_NS.'Person');
	
	# name
	{
		my @elems = $person->getChildrenByTagNameNS(ATOM_NS, 'name');
		foreach my $e (@elems)
		{
			$self->rdf_triple_literal($e, $person_identifier, AWOL_NS.'name', $e->textContent);
		}
	}

	# uri
	{
		my @elems = $person->getChildrenByTagNameNS(ATOM_NS, 'uri');
		foreach my $e (@elems)
		{
			my $link = $self->uri($e->textContent, $e);
			$self->rdf_triple($e, $person_identifier, AWOL_NS.'uri', $link);
		}
	}

	# email
	{
		my @elems = $person->getChildrenByTagNameNS(ATOM_NS, 'email');
		foreach my $e (@elems)
		{
			$self->rdf_triple($e, $person_identifier, AWOL_NS.'email', 'mailto:'.$e->textContent);
		}
	}

	return $person_identifier;
}

sub consume_generator
{
	my $self   = shift;
	my $elem   = shift;
	
	# Person
	my $identifier = $self->bnode($elem);
	$self->rdf_triple($elem, $identifier, RDF_TYPE, AWOL_NS.'Generator');
	
	# name
	{
		my $lang = $self->get_node_lang($elem);
		$self->rdf_triple_literal($elem, $identifier, AWOL_NS.'name', $elem->textContent, undef, $lang);
	}

	# uri
	if ($elem->hasAttribute('uri'))
	{
		my $link = $self->uri($elem->getAttribute('uri'), $elem);
		$self->rdf_triple($elem, $identifier, AWOL_NS.'uri', $link);
	}

	# version
	if ($elem->hasAttribute('uri'))
	{
		$self->rdf_triple($elem, $identifier, AWOL_NS.'version', $elem->getAttribute('version'));
	}

	return $identifier;
}

sub consume_inreplyto
{
	my $self    = shift;
	my $link    = shift;
	
	my $id = $self->bnode($link);
	$self->rdf_triple($link, $id, RDF_TYPE, AWOL_NS.'Entry');
	
	if ($link->hasAttribute('ref'))
	{
		$self->rdf_triple_literal($link, $id, AWOL_NS.'id', $link->getAttribute('ref'), XSD_NS.'anyURI');
	}
	
	if ($link->hasAttribute('href'))
	{
		my $href = $self->uri($link->getAttribute('href'), $link);
		$self->rdf_triple($link, $id, IANA_NS.'self', $href);
	}
	
	# TODO: "type".
	
	if ($link->hasAttribute('source'))
	{
		my $fid  = $self->bnode;
		my $href = $self->uri($link->getAttribute('href'), $link);
		$self->rdf_triple($link, $id, AWOL_NS.'source', $fid);
		$self->rdf_triple($link, $fid, RDF_TYPE, AWOL_NS.'Feed');
		$self->rdf_triple($link, $fid, IANA_NS.'self', $href);
	}
	
	return $id;
}

sub consume_link
{
	my $self    = shift;
	my $link    = shift;
	my $subject = shift || undef;
	
	# Link
	my $link_identifier = $self->bnode($link);
	$self->rdf_triple($link, $link_identifier, RDF_TYPE, AWOL_NS.'Link');

	# Destination
	my $destination_identifier = $self->bnode;
	$self->rdf_triple($link, $destination_identifier, RDF_TYPE, AWOL_NS.'Content');
	$self->rdf_triple($link, $link_identifier, AWOL_NS.'to', $destination_identifier);

	# rel
	{
		my $rel = HTTP::Link::Parser::relationship_uri(
			$link->hasAttribute('rel') ? $link->getAttribute('rel') : 'alternate');
		$self->rdf_triple($link, $link_identifier, AWOL_NS.'rel', $rel);
		
		if ($link->hasAttribute('href') and defined $subject)
		{
			my $href = $self->uri($link->getAttribute('href'), $link);
			$self->rdf_triple($link, $subject, $rel, $href);
		}
	}
	
	# href
	if ($link->hasAttribute('href'))
	{
		my $href = $self->uri($link->getAttribute('href'), $link);
		$self->rdf_triple($link, $destination_identifier, AWOL_NS.'src', $href);
	}

	# hreflang
	if ($link->hasAttribute('hreflang'))
	{
		my $hreflang = $link->getAttribute('hreflang');
		$self->rdf_triple_literal($link, $destination_identifier, AWOL_NS.'lang', $hreflang);
	}

	# length
	if ($link->hasAttribute('length'))
	{
		my $length = $link->getAttribute('length');
		$self->rdf_triple_literal($link, $destination_identifier, AWOL_NS.'length', $length, XSD_NS.'integer');
	}

	# type
	if ($link->hasAttribute('type'))
	{
		my $type = $link->getAttribute('type');
		$self->rdf_triple_literal($link, $destination_identifier, AWOL_NS.'type', $type);
	}

	# title: TODO - check this uses AWOL properly.
	if ($link->hasAttribute('title'))
	{
		my $lang  = $self->get_node_lang($link);
		my $title = $link->getAttribute('title');
		$self->rdf_triple_literal($link, $link_identifier, AWOL_NS.'title', $title, undef, $lang);
	}

	# thr:count
	if ($link->hasAttributeNS(THR_NS, 'count'))
	{
		my $count = $link->getAttributeNS(THR_NS, 'count');
		$self->rdf_triple_literal($link, $link_identifier, AX_NS.'count', $count, XSD_NS.'integer');
	}

	# thr:updated
	if ($link->hasAttributeNS(THR_NS, 'updated'))
	{
		my $u = $link->getAttributeNS(THR_NS, 'updated');
		$self->rdf_triple_literal($link, $link_identifier, AX_NS.'updated', $u, XSD_NS.'dateTime');
	}

	return $link_identifier;
}

sub consume_category
{
	my $self    = shift;
	my $elem    = shift;
	
	# Link
	my $id = $self->bnode($elem);
	$self->rdf_triple($elem, $id, RDF_TYPE, AWOL_NS.'Category');

	# term
	if ($elem->hasAttribute('term'))
	{
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'term', $elem->getAttribute('term'));
	}
	
	# label
	if ($elem->hasAttribute('label'))
	{
		my $lang = $self->get_node_lang($elem);
		$self->rdf_triple_literal($elem, $id, AWOL_NS.'label', $elem->getAttribute('label'), undef, $lang);
	}

	# scheme
	if ($elem->hasAttribute('scheme'))
	{
		my $link = $self->uri($elem->getAttribute('scheme'), $elem);
		$self->rdf_triple($elem, $id, AWOL_NS.'scheme', $link);
	}

	return $id;
}

sub xmlify
# Function only used internally.
{
	my $this = shift;
	my $dom  = shift;
	my $lang = shift;
	my $rv;

	$lang = $this->get_node_lang($dom)
		unless $lang;

	foreach my $kid ($dom->childNodes)
	{
		my $fakelang = 0;
		if (($kid->nodeType == XML_ELEMENT_NODE) && defined $lang)
		{
			unless ($kid->hasAttributeNS(XML_XML_NS, 'lang'))
			{
				$kid->setAttributeNS(XML_XML_NS, 'lang', $lang);
				$fakelang++;
			}
		}
		
		$rv .= $kid->toStringEC14N(1);
		
		if ($fakelang)
		{
			$kid->removeAttributeNS(XML_XML_NS, 'lang');
		}
	}
	
	return $rv;
}


sub xmlify_inclusive
# Function only used internally.
{
	my $this = shift;
	my $dom  = shift;
	my $lang = shift;
	my $rv;
	
	$lang = $this->get_node_lang($dom)
		unless $lang;
	
	my $fakelang = 0;
	if (($dom->nodeType == XML_ELEMENT_NODE) && defined $lang)
	{
		unless ($dom->hasAttributeNS(XML_XML_NS, 'lang'))
		{
			$dom->setAttributeNS(XML_XML_NS, 'lang', $lang);
			$fakelang++;
		}
	}
	
	$rv = $dom->toStringEC14N(1);
	
	if ($fakelang)
	{
		$dom->removeAttributeNS(XML_XML_NS, 'lang');
	}
	
	return $rv;
}

sub get_node_lang
{
	my $this = shift;
	my $node = shift;

	if ($node->hasAttributeNS(XML_XML_NS, 'lang'))
	{
		return valid_lang($node->getAttributeNS(XML_XML_NS, 'lang')) ?
			$node->getAttributeNS(XML_XML_NS, 'lang'):
			undef;
	}

	if ($node != $this->{'DOM'}->documentElement
	&&  defined $node->parentNode
	&&  $node->parentNode->nodeType == XML_ELEMENT_NODE)
	{
		return $this->get_node_lang($node->parentNode);
	}
	
	return undef;
}

sub get_node_base
{
	my $this = shift;
	my $node = shift;

	my @base;

	while (1)
	{
		push @base, $node->getAttributeNS(XML_XML_NS, 'base')
			if $node->hasAttributeNS(XML_XML_NS, 'base');
			
		$node = $node->parentNode;
		last unless blessed($node) && $node->isa('XML::LibXML::Element');
	}
	
	my $rv = URI->new($this->uri); # document URI.
	
	while (my $b = pop @base)
	{
		$rv = URI->new($b)->abs($rv);
	}
	
	return $rv->as_string;
}

sub rdf_triple
# Function only used internally.
{
	my $this = shift;

	my $suppress_triple = 0;
	$suppress_triple = $this->{'sub'}->{'pretriple_resource'}($this, @_)
		if defined $this->{'sub'}->{'pretriple_resource'};
	return if $suppress_triple;
	
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource URI or bnode
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	# First make sure the object node type is ok.
	my $to;
	if ($object =~ m/^_:(.*)/)
	{
		$to = RDF::Trine::Node::Blank->new($1);
	}
	else
	{
		$to = RDF::Trine::Node::Resource->new($object);
	}

	# Run the common function
	return $this->rdf_triple_common($element, $subject, $predicate, $to, $graph);
}

sub rdf_triple_literal
# Function only used internally.
{
	my $this = shift;

	my $suppress_triple = 0;
	$suppress_triple = $this->{'sub'}->{'pretriple_literal'}($this, @_)
		if defined $this->{'sub'}->{'pretriple_literal'};
	return if $suppress_triple;

	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource Literal
	my $datatype  = shift;  # Datatype URI (possibly undef or '')
	my $language  = shift;  # Language (possibly undef or '')
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	# Now we know there's a literal
	my $to;
	
	# Work around bad Unicode handling in RDF::Trine.
	$object = encode_utf8($object);

	if (defined $datatype)
	{
		if ($datatype eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral')
		{
			if ($this->{'options'}->{'use_rtnlx'})
			{
				eval
				{
					require RDF::Trine::Node::Literal::XML;
					$to = RDF::Trine::Node::Literal::XML->new($element->childNodes);
				};
			}
			
			if ( $@ || !defined $to)
			{
				my $orig = $RDF::Trine::Node::Literal::USE_XMLLITERALS;
				$RDF::Trine::Node::Literal::USE_XMLLITERALS = 0;
				$to = RDF::Trine::Node::Literal->new($object, undef, $datatype);
				$RDF::Trine::Node::Literal::USE_XMLLITERALS = $orig;
			}
		}
		else
		{
			$to = RDF::Trine::Node::Literal->new($object, undef, $datatype);
		}
	}
	else
	{
		$to = RDF::Trine::Node::Literal->new($object, $language, undef);
	}

	# Run the common function
	$this->rdf_triple_common($element, $subject, $predicate, $to, $graph);
}

sub rdf_triple_common
# Function only used internally.
{
	my $this      = shift;  # A reference to the Parser object
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $to        = shift;  # RDF::Trine::Node Resource URI or bnode
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	# First, make sure subject and predicates are the right kind of nodes
	my $tp = RDF::Trine::Node::Resource->new($predicate);
	my $ts;
	if ($subject =~ m/^_:(.*)/)
	{
		$ts = RDF::Trine::Node::Blank->new($1);
	}
	else
	{
		$ts = RDF::Trine::Node::Resource->new($subject);
	}

	my $statement;

	# If we are configured for it, and graph name can be found, add it.
	if (ref($this->{'options'}->{'named_graphs'}) && ($graph))
	{
		$this->{Graphs}->{$graph}++;
		
		my $tg;
		if ($graph =~ m/^_:(.*)/)
		{
			$tg = RDF::Trine::Node::Blank->new($1);
		}
		else
		{
			$tg = RDF::Trine::Node::Resource->new($graph);
		}

		$statement = RDF::Trine::Statement::Quad->new($ts, $tp, $to, $tg);
	}
	else
	{
		$statement = RDF::Trine::Statement->new($ts, $tp, $to);
	}

	my $suppress_triple = 0;
	$suppress_triple = $this->{'sub'}->{'ontriple'}($this, $element, $statement)
		if ($this->{'sub'}->{'ontriple'});
	return if $suppress_triple;

	$this->{RESULTS}->add_statement($statement);
}

sub bnode
# Function only used internally.
{
	my $this    = shift;
	my $element = shift;
	
	if (defined $this->{'bnode_generator'})
	{
		return $this->{'bnode_generator'}->bnode($element);
	}
	
	return sprintf('_:AwolAutoNode%03d', $this->{bnodes}++);
}

sub valid_lang
{
	my $value_to_test = shift;

	return 1 if (defined $value_to_test) && ($value_to_test eq '');
	return 0 unless defined $value_to_test;
	
	# Regex for recognizing RFC 4646 well-formed tags
	# http://www.rfc-editor.org/rfc/rfc4646.txt
	# http://tools.ietf.org/html/draft-ietf-ltru-4646bis-21

	# The structure requires no forward references, so it reverses the order.
	# It uses Java/Perl syntax instead of the old ABNF
	# The uppercase comments are fragments copied from RFC 4646

	# Note: the tool requires that any real "=" or "#" or ";" in the regex be escaped.

	my $alpha      = '[a-z]';      # ALPHA
	my $digit      = '[0-9]';      # DIGIT
	my $alphanum   = '[a-z0-9]';   # ALPHA / DIGIT
	my $x          = 'x';          # private use singleton
	my $singleton  = '[a-wyz]';    # other singleton
	my $s          = '[_-]';       # separator -- lenient parsers will use [_-] -- strict will use [-]

	# Now do the components. The structure is slightly different to allow for capturing the right components.
	# The notation (?:....) is a non-capturing version of (...): so the "?:" can be deleted if someone doesn't care about capturing.

	my $language   = '([a-z]{2,8}) | ([a-z]{2,3} $s [a-z]{3})';
	
	# ABNF (2*3ALPHA) / 4ALPHA / 5*8ALPHA  --- note: because of how | works in regex, don't use $alpha{2,3} | $alpha{4,8} 
	# We don't have to have the general case of extlang, because there can be only one extlang (except for zh-min-nan).

	# Note: extlang invalid in Unicode language tags

	my $script = '[a-z]{4}' ;   # 4ALPHA 

	my $region = '(?: [a-z]{2}|[0-9]{3})' ;    # 2ALPHA / 3DIGIT

	my $variant    = '(?: [a-z0-9]{5,8} | [0-9] [a-z0-9]{3} )' ;  # 5*8alphanum / (DIGIT 3alphanum)

	my $extension  = '(?: [a-wyz] (?: [_-] [a-z0-9]{2,8} )+ )' ; # singleton 1*("-" (2*8alphanum))

	my $privateUse = '(?: x (?: [_-] [a-z0-9]{1,8} )+ )' ; # "x" 1*("-" (1*8alphanum))

	# Define certain grandfathered codes, since otherwise the regex is pretty useless.
	# Since these are limited, this is safe even later changes to the registry --
	# the only oddity is that it might change the type of the tag, and thus
	# the results from the capturing groups.
	# http://www.iana.org/assignments/language-subtag-registry
	# Note that these have to be compared case insensitively, requiring (?i) below.

	my $grandfathered  = '(?:
			  (en [_-] GB [_-] oed)
			| (i [_-] (?: ami | bnn | default | enochian | hak | klingon | lux | mingo | navajo | pwn | tao | tay | tsu ))
			| (no [_-] (?: bok | nyn ))
			| (sgn [_-] (?: BE [_-] (?: fr | nl) | CH [_-] de ))
			| (zh [_-] min [_-] nan)
			)';

	# old:         | zh $s (?: cmn (?: $s Hans | $s Hant )? | gan | min (?: $s nan)? | wuu | yue );
	# For well-formedness, we don't need the ones that would otherwise pass.
	# For validity, they need to be checked.

	# $grandfatheredWellFormed = (?:
	#         art $s lojban
	#     | cel $s gaulish
	#     | zh $s (?: guoyu | hakka | xiang )
	# );

	# Unicode locales: but we are shifting to a compatible form
	# $keyvalue = (?: $alphanum+ \= $alphanum+);
	# $keywords = ($keyvalue (?: \; $keyvalue)*);

	# We separate items that we want to capture as a single group

	my $variantList   = $variant . '(?:' . $s . $variant . ')*' ;     # special for multiples
	my $extensionList = $extension . '(?:' . $s . $extension . ')*' ; # special for multiples

	my $langtag = "
			($language)
			($s ( $script ) )?
			($s ( $region ) )?
			($s ( $variantList ) )?
			($s ( $extensionList ) )?
			($s ( $privateUse ) )?
			";

	# Here is the final breakdown, with capturing groups for each of these components
	# The variants, extensions, grandfathered, and private-use may have interior '-'
	
	my $r = ($value_to_test =~ 
		/^(
			($langtag)
		 | ($privateUse)
		 | ($grandfathered)
		 )$/xi);
	return $r;
}

'A man, a plan, a canal: Panama'; # E, r u true?

__END__

=head1 NAME

XML::Atom::OWL - parse an Atom file into RDF

=head1 SYNOPSIS

 use XML::Atom::OWL;
 
 $parser = XML::Atom::OWL->new($xml, $baseuri);
 $graph  = $parser->graph;

=head1 DESCRIPTION

This has a pretty similar interface to L<RDF::RDFa::Parser>.

=head2 Constructor

=over 4

=item C<< new($xml, $baseuri, \%options, $storage) >>

This method creates a new XML::Atom::OWL object and returns it.

The $xml variable may contain an XML (Atom) string, or an
L<XML::LibXML::Document> object. If a string, the document is parsed
using L<XML::LibXML>, which will throw an exception if it is not
well-formed. XML::Atom::OWL does not catch the exception.

The base URI is used to resolve relative URIs found in the document.

Currently only one option is defined, 'no_fetch_content_src', a boolean
indicating whether <content src> URLs should be automatically fetched
and added to the model as if inline content had been provided. They are
fetched by default, but it's pretty rare for feeds to include this attribute.

$storage is an RDF::Trine::Storage object. If undef, then a new
temporary store is created.

=back

=head2 Public Methods

=over 4

=item C<< uri >>

Returns the base URI of the document being parsed. This will usually be the
same as the base URI provided to the constructor.

Optionally it may be passed a parameter - an absolute or relative URI - in
which case it returns the same URI which it was passed as a parameter, but
as an absolute URI, resolved relative to the document's base URI.

This seems like two unrelated functions, but if you consider the consequence
of passing a relative URI consisting of a zero-length string, it in fact makes
sense.

=item C<< dom >>

Returns the parsed XML::LibXML::Document.

=item C<< graph >>

This method will return an RDF::Trine::Model object with all
statements of the full graph.

This method automatically calls C<consume>.

=item C<< root_identifier >>

Returns the blank node or URI for the root element of the Atom
document as an RDF::Trine::Node

Calls C<consume> automatically.

=item C<< set_callbacks(\%callbacks) >>

Set callback functions for the parser to call on certain events. These are only necessary if
you want to do something especially unusual.

  $p->set_callbacks({
    'pretriple_resource' => sub { ... } ,
    'pretriple_literal'  => sub { ... } ,
    'ontriple'           => undef ,
    });

For details of the callback functions, see the section CALLBACKS. C<set_callbacks> must
be used I<before> C<consume>. C<set_callbacks> itself returns a reference to the parser
object itself.

=item C<< consume >>

The document is parsed. Triples extracted from the document are passed
to the callbacks as each one is found; triples are made available in the
model returned by the C<graph> method.

This function returns the parser object itself, making it easy to
abbreviate several of XML::Atom::OWL's functions:

  my $iterator = XML::Atom::OWL->new(undef, $uri)
                 ->consume->graph->as_stream;

You probably only need to call this explicitly if you're using callbacks.

=back

=head1 CALLBACKS

Several callback functions are provided. These may be set using the C<set_callbacks> function,
which taskes a hashref of keys pointing to coderefs. The keys are named for the event to fire the
callback on.

=head2 pretriple_resource

This is called when a triple has been found, but before preparing the triple for
adding to the model. It is only called for triples with a non-literal object value.

The parameters passed to the callback function are:

=over 4

=item * A reference to the C<XML::Atom::OWL> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * Subject URI or bnode (string)

=item * Predicate URI (string)

=item * Object URI or bnode (string)

=item * Graph URI or bnode (string or undef)

=back

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise.

=head2 pretriple_literal

This is the equivalent of pretriple_resource, but is only called for triples with a
literal object value.

The parameters passed to the callback function are:

=over 4

=item * A reference to the C<XML::Atom::OWL> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * Subject URI or bnode (string)

=item * Predicate URI (string)

=item * Object literal (string)

=item * Datatype URI (string or undef)

=item * Language (string or undef)

=item * Graph URI or bnode (string or undef)

=back

Beware: sometimes both a datatype I<and> a language will be passed. 
This goes beyond the normal RDF data model.)

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise.

=head2 ontriple

This is called once a triple is ready to be added to the graph. (After the pretriple
callbacks.) The parameters passed to the callback function are:

=over 4

=item * A reference to the C<XML::Atom::OWL> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * An RDF::Trine::Statement object.

=back

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise. The callback may modify the RDF::Trine::Statement
object.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<RDF::Trine>, L<XML::Atom::FromOWL>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2010-2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

