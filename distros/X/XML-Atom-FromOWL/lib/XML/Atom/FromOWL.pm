package XML::Atom::FromOWL;

use 5.010;
use strict;
no warnings;

use Data::UUID;
use RDF::TrineX::Functions -shortcuts_nodes;
use Scalar::Util qw[blessed];
use XML::Atom::Content;
use XML::Atom::Entry;
use XML::Atom::Feed;
use XML::Atom::Link;
use XML::Atom::Person;

use constant AS    => 'http://activitystrea.ms/spec/1.0/';
use constant ATOM  => 'http://www.w3.org/2005/Atom';
use constant FH    => 'http://purl.org/syndication/history/1.0';
use constant THR   => 'http://purl.org/syndication/thread/1.0';
use constant XHTML => 'http://www.w3.org/1999/xhtml';

sub AWOL  { return 'http://bblfish.net/work/atom-owl/2006-06-06/#' . shift; }
sub AAIR  { return 'http://xmlns.notu.be/aair#' . shift; }
sub AX    { return 'http://buzzword.org.uk/rdf/atomix#' . shift; }
sub FOAF  { return 'http://xmlns.com/foaf/0.1/' . shift; }
sub HNEWS { return 'http://ontologi.es/hnews#' . shift; }
sub LINK  { return 'http://www.iana.org/assignments/relation/' . shift; }
sub RDF   { return 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' . shift; }
sub XSD   { return 'http://www.w3.org/2001/XMLSchema#' . shift; }

use namespace::clean;

our ($AUTHORITY, $VERSION);
our (%feed_dispatch, %entry_dispatch);

BEGIN
{
	$AUTHORITY  = 'cpan:TOBYINK';
	$VERSION    = '0.102';

	%feed_dispatch = (
		AWOL('Feed')         => sub {},
		AWOL('entry')        => \&_export_feed_entry,
		AWOL('id')           => \&_export_thing_id,
		AWOL('title')        => \&_export_thing_TextConstruct,
		AWOL('subtitle')     => \&_export_thing_TextConstruct,
		AWOL('rights')       => \&_export_thing_TextConstruct,
		AWOL('updated')      => \&_export_thing_DateConstruct,
		AWOL('icon')         => \&_export_thing_ImageConstruct,
		AWOL('logo')         => \&_export_thing_ImageConstruct,
		AWOL('link')         => \&_export_thing_link,
		AWOL('author')       => \&_export_thing_PersonConstruct,
		AWOL('contributor')  => \&_export_thing_PersonConstruct,
		AWOL('category')     => \&_export_thing_category,
		AX('ArchiveFeed')    => \&_export_feed_fh_archive,
		AX('CompleteFeed')   => \&_export_feed_fh_complete,
		);
	%entry_dispatch = (
		AWOL('Entry')        => sub {},
		AWOL('id')           => \&_export_thing_id,
		AWOL('title')        => \&_export_thing_TextConstruct,
		AWOL('summary')      => \&_export_thing_TextConstruct,
		AWOL('rights')       => \&_export_thing_TextConstruct,
		AWOL('published')    => \&_export_thing_DateConstruct,
		AWOL('updated')      => \&_export_thing_DateConstruct,
		AWOL('link')         => \&_export_thing_link,
		AWOL('author')       => \&_export_thing_PersonConstruct,
		AWOL('contributor')  => \&_export_thing_PersonConstruct,
		AWOL('category')     => \&_export_thing_category,
		AWOL('content')      => \&_export_entry_content,
		AX('total')          => \&_export_entry_thr_total,
		AX('in-reply-to')    => \&_export_entry_thr_in_reply_to,
		AAIR('activityVerb') => \&_export_entry_as_verb,
		AAIR('activityObject') => \&_export_entry_as_ObjectConstruct,
		AAIR('activityTarget') => \&_export_entry_as_ObjectConstruct,
		'http://activitystrea.ms/schema/1.0/*' => \&_export_entry_as_object_type,
		# TODO:- atom:source
		);
}

sub new
{
	my ($class, %options) = @_;
	bless { %options }, $class;
}

sub export_feeds
{
	my ($self, $model, %options) = @_;
	$model = rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my @subjects =  $model->subjects(rdf_resource(RDF('type')), rdf_resource(AWOL('Feed')));

	my @feeds;
	foreach my $s (@subjects)
	{
		push @feeds, $self->export_feed($model, $s, %options);
	}
	
	if ($options{sort} eq 'id')
	{
		return sort { $a->id cmp $b->id } @feeds;
	}
	return @feeds;
}

sub export_entries
{
	my ($self, $model, %options) = @_;
	$model = rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my @subjects =  $model->subjects(rdf_resource(RDF('type')), rdf_resource(AWOL('Entry')));

	my @entries;
	foreach my $s (@subjects)
	{
		push @entries, $self->export_feed($model, $s, %options);
	}
	
	if ($options{sort} eq 'id')
	{
		return sort { $a->id cmp $b->id } @entries;
	}
	return @entries;
}

sub export_feed
{
	my ($self, $model, $subject, %options) = @_;
	$model = rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my $feed = XML::Atom::Feed->new(Version => 1.0);

	my $attr = {
		version => $VERSION,
		uri     => 'https://metacpan.org/release/'.__PACKAGE__,
	};
	$attr->{uri} =~ s/::/-/g;
	$feed->set(ATOM(), 'generator', __PACKAGE__, $attr, 1);

	my $extra_links = {};
	my $triples = $model->get_statements($subject, undef, undef);
	while (my $triple = $triples->next)
	{
		next unless $triple->rdf_compatible;
		
		if (defined $feed_dispatch{$triple->predicate->uri}
		and ref($feed_dispatch{$triple->predicate->uri}) eq 'CODE')
		{
			my $code = $feed_dispatch{$triple->predicate->uri};
			$code->($self, $feed, $model, $triple, %options);
		}
		elsif ($triple->predicate->uri eq RDF('type')
		and $triple->object->is_resource
		and defined $feed_dispatch{$triple->object->uri}
		and ref($feed_dispatch{$triple->object->uri}) eq 'CODE')
		{
			my $code = $feed_dispatch{$triple->object->uri};
			$code->($self, $feed, $model, $triple, %options);
		}
		elsif ($triple->object->is_resource)
		{
			my $rel  = $triple->predicate->uri;
			$rel =~ s'^http://www\.iana\.org/assignments/relation/'';
			$extra_links->{$rel} ||= {};
			$extra_links->{$rel}{$triple->object->uri}++;
		}
		elsif ($triple->object->is_literal)
		{
			$self->_export_thing_LiteralValue($feed, $model, $triple, %options);
		}
	}

	$self->_process_extra_links($feed, $model, $extra_links, %options);
	$feed->id( $self->_make_id ) unless $feed->id;

	return $feed;
}

sub export_entry
{
	my ($self, $model, $subject, %options) = @_;
	$model = rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my $entry = XML::Atom::Entry->new(Version => 1.0);

	my $extra_links;
	my $triples = $model->get_statements($subject, undef, undef);
	while (my $triple = $triples->next)
	{
		next unless $triple->rdf_compatible;
		
		if (defined $entry_dispatch{$triple->predicate->uri}
		and ref($entry_dispatch{$triple->predicate->uri}) eq 'CODE')
		{
			my $code = $entry_dispatch{$triple->predicate->uri};
			$code->($self, $entry, $model, $triple, %options);
		}
		elsif ($triple->predicate->uri eq RDF('type')
		and $triple->object->is_resource
		and defined $entry_dispatch{$triple->object->uri}
		and ref($entry_dispatch{$triple->object->uri}) eq 'CODE')
		{
			my $code = $entry_dispatch{$triple->object->uri};
			$code->($self, $entry, $model, $triple, %options);
		}
		elsif ($triple->predicate->uri eq RDF('type')
		and $triple->object->is_resource
		and defined $entry_dispatch{ ($triple->object->qname)[0] . '*' }
		and ref($entry_dispatch{ ($triple->object->qname)[0] . '*' }) eq 'CODE')
		{
			my $code = $entry_dispatch{ ($triple->object->qname)[0] . '*' };
			$code->($self, $entry, $model, $triple, %options);
		}
		elsif ($triple->object->is_resource)
		{
			my $rel  = $triple->predicate->uri;
			$rel =~ s'^http://www\.iana\.org/assignments/relation/'';
			$extra_links->{$rel} ||= {};
			$extra_links->{$rel}{$triple->object->uri}++;
		}
		elsif ($triple->object->is_literal)
		{
			$self->_export_thing_LiteralValue($entry, $model, $triple, %options);
		}
	}

	$self->_process_extra_links($entry, $model, $extra_links, %options);
	$entry->id( $self->_make_id ) unless $entry->id;

	return $entry;
}

sub _process_extra_links
{
	my ($self, $thing, $model, $extras, %options) = @_;
	return unless keys %$extras;
	
	my $already = {};
	foreach my $link ($thing->links)
	{
		$already->{$link->rel} ||= {};
		$already->{$link->rel}{$link->href}++;
	}
	
	PRED: foreach my $predicate (keys %$extras)
	{
		OBJ: foreach my $object (keys %{ $extras->{$predicate} })
		{
			next OBJ if $already->{$predicate}{$object};
			my $link = XML::Atom::Link->new(Version => 1.0);
			$link->rel($predicate);
			$link->href($object);
			$thing->add_link($link);
		}
	}
}

sub _export_thing_LiteralValue
{
	my ($self, $thing, $model, $triple, %options) = @_;
	my $ns = XML::Atom::Namespace->new(xhtml => XHTML);

	if ($triple->object->is_literal)
	{
		my $attr = {
			content  => $triple->object->literal_value,
			property => $triple->predicate->uri,
			};
		$attr->{'xml:lang'} = $triple->object->literal_value_language
			if $triple->object->has_language;
		$attr->{'datatype'} = $triple->object->literal_datatype
			if $triple->object->has_datatype;
		$thing->set_attr(typeof => '');
		return $thing->set($ns, 'meta', undef, $attr, 1);
	}
}

sub _export_feed_entry
{
	my ($self, $feed, $model, $triple, %options) = @_;
	my $entry = $self->export_entry($model, $triple->object, %options);
	$feed->add_entry($entry);
}

sub _export_feed_fh_archive
{
	my ($self, $feed, $model, $triple, %options) = @_;
	return $feed->set(FH, 'archive');
}

sub _export_feed_fh_complete
{
	my ($self, $feed, $model, $triple, %options) = @_;
	return $feed->set(FH, 'complete');
}

sub _export_entry_thr_total
{
	my ($self, $entry, $model, $triple, %options) = @_;
	return $entry->set(THR, 'total', $triple->object->literal_value)
		if $triple->object->is_literal;
}

sub _export_entry_thr_in_reply_to
{
	my ($self, $entry, $model, $triple, %options) = @_;
	my $attr;
	
	my $iter = $model->get_statements($triple->object);
	while (my $st = $iter->next)
	{
		if ($st->predicate->uri eq LINK('self')
		and $st->object->is_resource)
		{
			$attr->{href} = $st->object->uri;
		}
		elsif ($st->predicate->uri eq AWOL('id')
		and !$st->object->is_blank)
		{
			$attr->{ref} = flatten_node($st->object);
		}
		elsif ($st->predicate->uri eq AWOL('source'))
		{
			my $iter2 = $model->get_statements($st->object, rdf_resource(LINK('self')));
			while (my $st2 = $iter2->next)
			{
				if ($st2->object->is_resource)
				{
					$attr->{source} = $st2->object->uri;
				}
			}
		}
	}
	
	return $entry->set(THR, 'in-reply-to', undef, $attr);
}

sub _export_thing_id
{
	my ($self, $thing, $model, $triple, %options) = @_;
	unless ($triple->object->is_blank)
	{
		return $thing->id( flatten_node($triple->object) );
	}
}

sub _export_thing_link
{
	my ($self, $thing, $model, $triple, %options) = @_;
	
	my $link = XML::Atom::Link->new(Version => 1.0);
	
	my $iter = $model->get_statements($triple->object);
	while (my $st = $iter->next)
	{
		if ($st->predicate->uri eq AWOL('rel')
		and $st->object->is_resource)
		{
			(my $rel = $st->object->uri)
				=~ s'^http://www\.iana\.org/assignments/relation/'';
			$link->rel($rel);
		}
		elsif ($st->predicate->uri eq AWOL('to'))
		{
			my $iter2 = $model->get_statements($st->object);
			while (my $st2 = $iter2->next)
			{
				if ($st2->predicate->uri eq AWOL('type')
				and $st2->object->is_literal)
				{
					$link->type(flatten_node($st2->object));
				}
				elsif ($st2->predicate->uri eq AWOL('src')
				and !$st2->object->is_blank)
				{
					$link->href(flatten_node($st2->object));
				}
				elsif ($st2->predicate->uri eq AWOL('lang')
				and $st2->object->is_literal)
				{
					$link->hreflang(flatten_node($st2->object));
				}
			}
		}
	}
	
	return $thing->add_link($link);
}

sub _export_thing_PersonConstruct
{
	my ($self, $thing, $model, $triple, %options) = @_;
	
	my $person = XML::Atom::Person->new(Version => 1.0);
	
	my $iter = $model->get_statements($triple->object);
	while (my $st = $iter->next)
	{
		if ($st->predicate->uri eq AWOL('email')
		and !$st->object->is_blank)
		{
			(my $e = flatten_node($st->object)) =~ s'^mailto:'';
			$person->email($e);
		}
		elsif ($st->predicate->uri eq AWOL('uri')
		and !$st->object->is_blank)
		{
			$person->url(flatten_node($st->object));
		}
		elsif ($st->predicate->uri eq AWOL('name')
		and $st->object->is_literal)
		{
			$person->name(flatten_node($st->object));
		}
	}
	
	if ($triple->predicate->uri eq AWOL('contributor'))
	{
		return $thing->add_contributor($person);
	}
	if ($triple->predicate->uri eq AWOL('author'))
	{
		return $thing->add_author($person);
	}
}

sub _export_entry_content
{
	my ($self, $entry, $model, $triple, %options) = @_;
	
	my $content = XML::Atom::Content->new(Version => 1.0);
	if ($triple->object->is_literal)
	{
		$content->body(flatten_node($triple->object));
		$content->lang($triple->object->literal_value_language)
			if $triple->object->has_language;
	}
	else
	{
		my $iter = $model->get_statements($triple->object);
		while (my $st = $iter->next)
		{
			if ($st->predicate->uri eq AWOL('base')
			and !$st->object->is_blank)
			{
				$content->base(flatten_node($st->object));
			}
			elsif ($st->predicate->uri eq AWOL('type')
			and $st->object->is_literal)
			{
				$content->type(flatten_node($st->object));
			}
			elsif ($st->predicate->uri eq AWOL('lang')
			and $st->object->is_literal)
			{
				$content->lang(flatten_node($st->object));
			}
			elsif ($st->predicate->uri eq AWOL('body')
			and $st->object->is_literal)
			{
				$content->body(flatten_node($st->object));
			}
			elsif ($st->predicate->uri eq AWOL('src')
			and !$st->object->is_blank)
			{
				$content->set_attr(src => flatten_node($st->object));
			}
		}
	}
	
	return $entry->content($content);
}

sub _export_thing_category
{
	my ($self, $thing, $model, $triple, %options) = @_;
	
	my $category = XML::Atom::Category->new(Version => 1.0);

	if ($triple->object->is_literal)
	{
		$category->term(flatten_node($triple->object));
	}
	else
	{
		my $iter = $model->get_statements($triple->object);
		while (my $st = $iter->next)
		{
			if ($st->predicate->uri eq AWOL('term')
			and $st->object->is_literal)
			{
				$category->term(flatten_node($st->object));
			}
			elsif ($st->predicate->uri eq AWOL('scheme')
			and !$st->object->is_blank)
			{
				$category->scheme(flatten_node($st->object));
			}
			elsif ($st->predicate->uri eq AWOL('label')
			and $st->object->is_literal)
			{
				$category->label(flatten_node($st->object));
				$category->set_attr('xml:lang', $st->object->literal_value_language)
					if $st->object->has_language;
			}
		}
	}
	
	return $thing->add_category($category);
}

sub _export_thing_TextConstruct
{
	my ($self, $thing, $model, $triple, %options) = @_;

	my $tag = {
		AWOL('title')     => 'title',
		AWOL('subtitle')  => 'subtitle',
		AWOL('summary')   => 'summary',
		AWOL('rights')    => 'rights',
		}->{$triple->predicate->uri};
	
	if ($triple->object->is_literal)
	{
		my $attr = { type=>'text' };
		$attr->{'xml:lang'} = $triple->object->literal_value_language
			if $triple->object->has_language;
		return $thing->set(ATOM(), $tag, flatten_node($triple->object), $attr, 1);
	}
	else
	{
		foreach my $fmt (qw(text html xhtml)) # TODO: does 'xhtml' need special handling??
		{
			my $iter = $model->get_statements(
				$triple->object,
				rdf_resource(AWOL($fmt)),
				undef,
				);
			while (my $st = $iter->next)
			{
				if ($st->object->is_literal)
				{
					my $attr = { type=>$fmt };
					$attr->{'xml:lang'} = $st->object->literal_value_language
						if $st->object->has_language;
					return $thing->set(ATOM(), $tag, flatten_node($st->object), $attr, 1);
				}
			}
		}
	}
}

sub _export_thing_DateConstruct
{
	my ($self, $thing, $model, $triple, %options) = @_;

	my $tag = {
		AWOL('published') => 'published',
		AWOL('updated')   => 'updated',
		}->{$triple->predicate->uri};
	
	if ($triple->object->is_literal)
	{
		my $attr = {};
		return $thing->set(ATOM(), $tag, flatten_node($triple->object), $attr, 1);
	}
}

sub _export_thing_ImageConstruct
{
	my ($self, $thing, $model, $triple, %options) = @_;

	my $tag = {
		AWOL('logo') => 'logo',
		AWOL('icon') => 'icon',
		}->{$triple->predicate->uri};
	
	if ($triple->object->is_resource)
	{
		my $attr = {};
		return $thing->set(ATOM(), $tag, flatten_node($triple->object), $attr, 1);
	}
}

sub _export_entry_as_verb
{
	my ($self, $thing, $model, $triple, %options) = @_;

	if ($triple->object->is_resource)
	{
		my $attr = {};
		my $verb = flatten_node($triple->object);
		$verb =~ s#^http://activitystrea\.ms/schema/1\.0/#./#;
		return $thing->elem->addNewChild(AS(), 'as:verb')->appendText($verb);
	}
}

sub _export_entry_as_object_type
{
	my ($self, $thing, $model, $triple, %options) = @_;

	if ($triple->object->is_resource)
	{
		my $attr = {};
		my $type = flatten_node($triple->object);
		$type =~ s#^http://activitystrea\.ms/schema/1\.0/#./#;
		return $thing->elem->addNewChild(AS(), 'as:object-type')->appendText($type);
	}
}

sub _export_entry_as_ObjectConstruct
{
	my ($self, $thing, $model, $triple, %options) = @_;

	my $tag = {
		AAIR('activityObject') => 'object',
		AAIR('activityTarget') => 'target',
		}->{$triple->predicate->uri};
	
	if ($triple->object->is_resource or $triple->object->is_blank)
	{
		my $object_entry = $self->export_entry($model, $triple->object, %options);
		my $node = $thing->elem->addNewChild(AS(), "as:$tag");
		$node->appendChild($_->cloneNode(1)) for $object_entry->elem->childNodes;
		return $node;
	}
}

sub _make_id
{
	my ($self) = @_;
	$self->{uuid} ||= Data::UUID->new;
	return 'urn:uuid:'.$self->{uuid}->create_str;
}

1;

__END__

=head1 NAME

XML::Atom::FromOWL - export RDF data to Atom

=head1 SYNOPSIS

 use LWP::UserAgent;
 use XML::Atom::OWL;
 use XML::Atom::FromOWL;
 
 my $ua       = LWP::UserAgent->new;
 my $r        = $ua->get('http://intertwingly.net/blog/index.atom');
 my $atomowl  = XML::Atom::OWL->new($r->decoded_content, $r->base);
 my $model    = $atomowl->consume->graph;  ## an RDF::Trine::Model
 
 my $exporter = XML::Atom::FromOWL->new;
 print $_->as_xml
	foreach $exporter->export_feeds($model);

=head1 DESCRIPTION

This module reads RDF and writes Atom feeds. It does the reverse
of L<XML::Atom::OWL>.

=head2 Constructor

=over

=item * C<< new(%options) >>

Returns a new XML::Atom::FromOWL object.

There are no valid options at the moment - the hash is reserved
for future use.

=back

=head2 Methods

=over

=item * C<< export_feeds($input, %options) >>

Returns a list of feeds found in the input, in no particular order.

The input may be a URI, file name, L<RDF::Trine::Model> or anything else
that can be handled by the C<parse> function of L<RDF::TrineX::Functions>.

Each item in the list returned is an L<XML::Atom::Feed>.

=item * C<< export_feed($input, $subject, %options) >>

As per C<export_feeds> but exports just a single feed.

The subject provided must be an RDF::Trine::Node::Blank or
RDF::Trine::Node::Resource of type awol:Feed.

=item * C<< export_entries($input, %options) >>

Returns a list of entries found in the input, in no particular order.

The input may be a URI, file name, L<RDF::Trine::Model> or anything else
that can be handled by the C<parse> function of L<RDF::TrineX::Functions>.

Each item in the list returned is an L<XML::Atom::Entry>.

=item * C<< export_entry($input, $subject, %options) >>

As per C<export_entry> but exports just a single entry.

The subject provided must be an RDF::Trine::Node::Blank or
RDF::Trine::Node::Resource of type awol:Entry.

=back

=head2 RDF Input

Input is expected to use AtomOwl
L<http://bblfish.net/work/atom-owl/2006-06-06/#>.

=head2 Feed Output

This module doesn't attempt to enforce many of OWL's semantic
constraints (e.g. it doesn't enforce that an entry has only one
title). It relies on L<XML::Atom::Feed> and L<XML::Atom::Entry>
for that sort of thing, but if your input is sensible that
shouldn't be a problem.

=head1 SEE ALSO

L<XML::Atom::OWL>, L<HTML::Microformats>, L<RDF::TrineX::Functions>,
L<XML::Atom::Feed>, L<XML::Atom::Entry>.

L<http://bblfish.net/work/atom-owl/2006-06-06/>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

