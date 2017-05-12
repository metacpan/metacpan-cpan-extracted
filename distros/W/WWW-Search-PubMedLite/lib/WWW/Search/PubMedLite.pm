package WWW::Search::PubMedLite;
use base 'WWW::Search';

use warnings;
use strict;

our $VERSION = '0.05';
our $DEBUG = 0;

use WWW::Search::PubMedLite::Lang;
use HTML::Entities;
use WWW::SearchResult;
use XML::LibXML;

=head1 NAME

WWW::Search::PubMedLite - Access PubMed's database of journal articles

=head1 SYNOPSIS

  use WWW::Search;
  my $search = new WWW::Search('PubMedLite');

  $search->native_query( 126941 );
  my $article = $search->next_result;

  my @fields = qw(
    pmid
    journal
    journal_abbreviation
    volulme
    issue
    title
    page
    year
    month
    affiliation
    abstract
    language
    doi
    text_url
    pmc_id
  );

  foreach my $field ( @fields ) {
    printf "%s: %s\n", $field, $article->{$field};
  }

=cut

sub native_setup_search {
  my( $self, $query ) = @_;
  my @ids = ref $query eq 'ARRAY' ? @$query : ( $query );
  $self->{_ids} = \@ids;
  $self->{_idx} = 0;

  $self->agent_name('WWW-Search-PubMedLite');
  $self->user_agent(1);
  $self->_debug("");
}

sub native_retrieve_some {
  my $self = shift;
  $self->_debug( "native_retrieve_some(): starting..." );

  my $id = $self->{_ids}->[$self->{_idx}++] or return;

  $self->{_current_url} = $self->_main_url($id);

  my %data = ( );
  my @fields = $self->_fields;

  $self->_debug( "native_retrieve_some():  extracting fields" );
  foreach my $field ( @fields ) {
    my $xml_url = $field->{xml_url}->( $self, $id );
    my @keys = ref $field->{key} ? @{$field->{key}} : ($field->{key});
    my @xpath = ref $field->{xpath} ? @{$field->{xpath}} : ($field->{xpath});

    my $doc = $self->_doc( $xml_url );

    my $value = undef;
    foreach my $xpath ( @xpath ) {
      $value = $self->_field_value( $doc, $xpath );
      last if $value;
    }

    $data{$_} = $value foreach @keys;
  }
  $self->_debug( "native_retrieve_some():  done extracting fields" );
  
  $data{year} =~ s/^(\d{4}).*/$1/ if $data{year};

  $data{authors} = $self->_authors( $self->_doc( $self->{_current_url} ) );
  $data{author} = join ', ', @{ $data{authors} };

  $data{language_name} = WWW::Search::PubMedLite::Lang->abbr2name( $data{language} );

  #$data{page} =~ s/-/decode_entities('&ndash;')/ge;

  my $hit = new WWW::SearchResult();
  $hit->{$_} = $data{$_} for keys %data;
  $hit->url( $self->{_current_url} );
  
  push @{$self->{cache}}, $hit;

  $self->{_current_url} = undef;

  $self->_debug( "native_retrieve_some(): done." );

  return 1;
}

sub _authors {
  my( $self, $doc ) = @_;

  my @author_text;
  my $authors = $doc->findnodes('//AuthorList/Author');

  for my $n ( 1 .. $authors->size ) {
    my $auth = $authors->get_node($n);

    my $lastname = $auth->findnodes('LastName') ? ($auth->findnodes('LastName'))[0]->to_literal : '';
    my $initials = $auth->findnodes('Initials') ? ($auth->findnodes('Initials'))[0]->to_literal : '';
    my $firstname = $auth->findnodes('ForeName') ? ($auth->findnodes('ForeName'))[0]->to_literal : '';
    my $fname = $initials
                  ? $initials
                  : $firstname
                      ? substr( $firstname, 0, 1 )
                      : '';

    my $name = sprintf '%s %s', $lastname, $fname if $lastname and $fname;
       $name ||= $lastname if $lastname;

    push @author_text, $name if $name;
  }

  return \@author_text;
}

sub _main_url {
  my( $self, $id ) = @_;
  return sprintf 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=%s&retmode=xml', $id;
}

# text_url
sub _tu_xml_url {
  my( $self, $pmid ) = @_;
  return sprintf 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=%s&cmd=prlinks', $pmid;
}

# pmc_id
sub _pmc_xml_url {
  my( $self, $pmid ) = @_;
  return sprintf 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=%s&db=pmc', $pmid;
}

sub _fields { (
  { key => 'pmid',                 xml_url => \&_main_url,    xpath => '//PMID' },
  { key => 'journal',              xml_url => \&_main_url,    xpath => '//Journal/Title' },
  { key => 'journal_abbreviation', xml_url => \&_main_url,    xpath => [ '//Journal/ISOAbbreviation', '//MedlineJournalInfo/MedlineTA', '//Journal/Title' ] },
  { key => 'volume',               xml_url => \&_main_url,    xpath => '//JournalIssue/Volume' },
  { key => 'issue',                xml_url => \&_main_url,    xpath => '//JournalIssue/Issue' },
  { key => 'title',                xml_url => \&_main_url,    xpath => '//Article/ArticleTitle' },
  { key => 'page',                 xml_url => \&_main_url,    xpath => '//Pagination/MedlinePgn' },
  { key => 'year',                 xml_url => \&_main_url,    xpath => [ '//JournalIssue/PubDate/Year', '//PubDate/MedlineDate' ] },
  { key => 'month',                xml_url => \&_main_url,    xpath => '//JournalIssue/PubDate/Month' },
  { key => 'affiliation',          xml_url => \&_main_url,    xpath => '//Affiliation' },
  { key => 'abstract',             xml_url => \&_main_url,    xpath => '//Abstract/AbstractText' },
  { key => 'language',             xml_url => \&_main_url,    xpath => '//Article/Language' },
  { key => 'doi',                  xml_url => \&_main_url,    xpath => '//PubmedData/ArticleIdList/ArticleId[@IdType="doi"]' },
  { key => 'text_url',             xml_url => \&_tu_xml_url,  xpath => '//IdUrlSet/ObjUrl/Url' },
  { key => 'pmc_id',               xml_url => \&_pmc_xml_url, xpath => '/eLinkResult/LinkSet/LinkSetDb[LinkName="pubmed_pmc"]/Link/Id' },

  # author
) }

sub _field_value {
  my( $self, $doc, $xpath ) = @_;
  $self->_debug( "_field_value(): searthing for $xpath" );
  $self->_debug( "_field_value(): \$doc is undef" ), return undef unless $doc;

  my $node = ($doc->findnodes($xpath))[0];
  $self->_debug( "_field_value(): no node, returning undef" ), return undef unless $node;

  my $value = $node->to_literal;
  $self->_debug( "_field_value(): got $value" );
  return $value;
}

#
# Returns the content from $url, warning on error.
#

sub _fetch_data {
  my( $self, $url ) = @_;
  $self->user_agent->timeout(10);

  $self->_debug( "_fetch_data(): fetching $url" );

  my $res = $self->user_agent->get($url);
  if( ! $res->is_success ) {
    $self->_debug( sprintf "_fetch_data(): could not fetch %s: error %s (agent: %s)", $url, $res->status_line, $self->user_agent->agent );
    return undef;
  }

  return $res->content;
}

#
# Given an $xml_url, returns a parsed XML document. Uses caching.
# 

my %Doc;
sub _doc {
  my( $self, $xml_url ) = @_;
  if( exists $Doc{$xml_url} ) {
    $self->_debug( "_doc(): cache for $xml_url" );
    return $Doc{$xml_url};
  }
  $self->_debug(   "_doc(): no cache for $xml_url" );

  my $xml = $self->_fetch_data($xml_url);
  $self->_debug( "_doc(): empty page" ), return undef unless $xml;

  my $parser = new XML::LibXML();
  $Doc{$xml_url} = $parser->parse_string($xml);

  return $Doc{$xml_url};
}

sub _debug {
  my( $self, @msg ) = @_;
  warn @msg, "\n" if $DEBUG;
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

=head2 NCBI error 803/temporarily unavailable

As of November 2008, the NCBI/PubMed servers have been a bit
unpredictable in returning results to queries issued by
W::S::PubMedLite. The only queries that appear to be failing are those
that request the PubMed Central ID; for example:

  L<http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=16402093&db=pmc>

The error returned by NCBI is "error 803/temporarily unavailable",
which prevents WWW::Search::PubMedLite from filling the C<pmc_id>
field in results.

This impacts C<make test>; specifically, if this error is encountered,
the "pmc_id" test will be skipped and a brief explanation will be
given. It should be safe to continue with the installation provided
that the other tests are working. Again, it appears that this problem
is confined to the C<pmc_id> field.

=head2 Bug reports

Please report any bugs or feature requests to
C<bug-www-search-pubmedlite at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Search-PubMedLite>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Search::PubMedLite

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Search-PubMedLite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Search-PubMedLite>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Search-PubMedLite>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Search-PubMedLite>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
