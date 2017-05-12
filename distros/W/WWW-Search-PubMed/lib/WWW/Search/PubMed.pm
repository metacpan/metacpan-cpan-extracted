package WWW::Search::PubMed;

=head1 NAME

WWW::Search::PubMed - Search the NCBI PubMed abstract database.

=head1 SYNOPSIS

 use WWW::Search;
 my $s = new WWW::Search ('PubMed');
 $s->native_query( 'ACGT' );
 while (my $r = $s->next_result) {
  print $r->title . "\n";
  print $r->description . "\n";
 }

=head1 DESCRIPTION

WWW::Search::PubMed provides a WWW::Search backend for searching the
NCBI/PubMed abstracts database.

=head1 VERSION

This document describes WWW::Search::PubMed version 1.004,
released 31 October 2007.

=head1 REQUIRES

 L<WWW::Search|WWW::Search>
 L<XML::DOM|XML::DOM>

=cut

our($VERSION)	= '1.004';

use strict;
use warnings;

require WWW::Search;
require WWW::SearchResult;
use WWW::Search::PubMed::Result;
use base qw(WWW::Search);

use XML::DOM;
our $debug				= 0;

use constant	ARTICLES_PER_REQUEST	=> 20;
use constant	QUERY_ARTICLE_LIST_URI	=> 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=500';	# term=ACTG
use constant	QUERY_ARTICLE_INFO_URI	=> 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed';	# &id=12167276&retmode=xml

=begin private

=item C<< native_setup_search ( $query, $options ) >>

Sets up the NCBI search using the supplied C<$query> string.

=end private

=cut

sub native_setup_search {
	my $self	= shift;
	my $query	= shift;
	my $options	= shift;
	
	$self->user_agent( "WWW::Search::PubMed/${VERSION} libwww-perl/${LWP::VERSION}; <http://kasei.us/code/pubmed/>" );
	
	my $ua			= $self->user_agent();
	my $url			= QUERY_ARTICLE_LIST_URI . '&term=' . WWW::Search::escape_query($query);
	my $response	= $ua->get( $url );
	my $success		= $response->is_success;
	if ($success) {
		my $parser	= new XML::DOM::Parser;
		my $content	= $response->content;
		$self->{'_xml_parser'}	= $parser;
		my $doc	= $parser->parse( $content );
		
		$self->{'_count'}	= eval { ($doc->getElementsByTagName('Count')->item(0)->getChildNodes)[0]->getNodeValue() } || 0;
		
		my @articles;
		my $ids	= $doc->getElementsByTagName('Id');
		my $n	= $ids->getLength;
		foreach my $i (0 .. $n - 1) {
			my $node		= $ids->item( $i );
			my @children	= $node->getChildNodes();
			push(@articles, + $children[0]->getNodeValue() );
		}
		$self->{'_article_ids'}	= \@articles;
	} else {
		return undef;
	}
}

=begin private

=item C<< native_retrieve_some >>

Requests search results from NCBI, adding the results to the WWW::Search object's cache.

=end private

=cut

sub native_retrieve_some {
	my $self	= shift;
	
	return undef unless scalar (@{ $self->{'_article_ids'} || [] });
	my $ua			= $self->user_agent();
	my $url			= QUERY_ARTICLE_INFO_URI . '&id=' . join(',', splice(@{ $self->{'_article_ids'} },0,ARTICLES_PER_REQUEST)) . '&retmode=xml';
	warn 'Fetching URL: ' . $url if ($debug);
	my $response	= $ua->get( $url );
	if ($response->is_success) {
		my $content	= $response->content;
		if ($debug) {
			open (my $fh, ">/tmp/pubmed.article.info");
			print { $fh } $content;
			close($fh);
			warn "Saved response in /tmp/pubmed.article.info\n";
		}
		my $doc			= $self->{'_xml_parser'}->parse( $content );
		my $articles	= $doc->getElementsByTagName('PubmedArticle');
		my $n			= $articles->getLength;
		warn "$n articles found\n" if ($debug);
		my $count		= 0;
		foreach my $i (0 .. $n - 1) {
			my $article	= $articles->item( $i );
			my $id		= ($article->getElementsByTagName('PMID')->item(0)->getChildNodes)[0]->getNodeValue();
			warn "$id\n" if ($debug);
			my $title	= ($article->getElementsByTagName('ArticleTitle')->item(0)->getChildNodes)[0]->getNodeValue();
			warn "\t$title\n" if ($debug);
			my $url		= 'http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?cmd=Retrieve&db=PubMed&list_uids=' . $id . '&dopt=Abstract';
			my @authors;
			my $authornodes	= $article->getElementsByTagName('Author');
			my $n		= $authornodes->getLength;
			foreach my $i (0 .. $n - 1) {
				my ($author, $fname, $lname);
				eval {
					$author	= $authornodes->item($i);
					$lname	= ($author->getElementsByTagName('LastName')->item(0)->getChildNodes)[0]->getNodeValue();
					$fname	= substr( ($author->getElementsByTagName('ForeName')->item(0)->getChildNodes)[0]->getNodeValue(), 0, 1) . '.';
				};
				if ($@) {
					warn $@ if ($debug);
					next unless ($lname);
				} else {
					push(@authors, join(' ', $lname, $fname));
				}
			}
			my $author	= join(', ', @authors);
			warn "\t$author\n" if ($debug);
			
			my $journal		= $self->get_text_node( $article, 'MedlineTA' );
			my $page		= $self->get_text_node( $article, 'MedlinePgn' );
			my $volume		= $self->get_text_node( $article, 'Volume' );
			my $issue		= $self->get_text_node( $article, 'Issue' );
			my $pmid		= $self->get_text_node( $article, 'PMID' );
			my $abstract	= $self->get_text_node( $article, 'AbstractText' );
			
			my @date;
			{
				my $date		= $article->getElementsByTagName('PubDate')->item(0);
				push(@date, $self->get_text_node( $date, 'Year' ));
				push(@date, $self->get_text_node( $date, 'Month' ));
				push(@date, $self->get_text_node( $date, 'Day' ));
			}
			
			my $hit		= new WWW::Search::PubMed::Result;
			
			my $source	= '';
			my $date	= join(' ', grep defined, @date);
			$hit->date( $date );
			$hit->year( $date[0] ) if (defined($date[0]));
			$hit->month( $date[1] ) if (defined($date[1]));
			$hit->day( $date[2] ) if (defined($date[2]));
			
			$source	= "${journal}. "
					. ($date ? "${date}; " : '')
					. ($volume ? "${volume}" : '')
					. ($issue ? "(${issue})" : '')
					. ($page ? ":$page" : '');
			$source	= "(${source})" if ($source);
			warn "\t$source\n" if ($debug);
			
			$hit->add_url( $url );
			$hit->title( $title );
			
			$hit->pmid( $pmid );
			$hit->abstract( $abstract ) if ($abstract);
			
			my $desc	= join(' ', grep {$_} ($author, $source));
			$hit->description( $desc );
			push( @{ $self->{'cache'} }, $hit );
			$count++;
			warn "$count : $title\n" if ($debug);
		}
		return $count;
	} else {
		warn "Uh-oh." . $response->error_as_HTML();
		return undef;
	}
	
}

=begin private

=item C<< get_text_node ( $node, $name )

Returns the text contained in the named descendent of the XML $node.

=end private

=cut

sub get_text_node {
	my $self	= shift;
	my $node	= shift;
	my $name	= shift;
	my $text	= eval { ($node->getElementsByTagName($name)->item(0)->getChildNodes)[0]->getNodeValue() };
	if ($@) {
		warn "XML[$name]: $@" if ($debug);
		return undef;
	} else {
		warn "XML[$name]: $text\n" if ($debug);
		return $text;
	}
}

1;

__END__

=head1 SEE ALSO

L<WWW::Search::PubMed::Result>
L<http://www.ncbi.nlm.nih.gov:80/entrez/query/static/overview.html>
L<http://eutils.ncbi.nlm.nih.gov/entrez/query/static/esearch_help.html>
L<http://eutils.ncbi.nlm.nih.gov/entrez/query/static/efetchlit_help.html>

=head1 COPYRIGHT

Copyright (c) 2003-2007 Gregory Todd Williams. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=cut
