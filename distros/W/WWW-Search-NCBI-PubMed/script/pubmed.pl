#!/usr/bin/perl

# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2004 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

use lib 'lib';

use strict;

BEGIN
{
    our $log_history = 0 ;

    if( $log_history )
    {
	open( ARGV_HISTORY, sprintf '>>%s.history_argv', $0 ) or warn "not access to argv history read/write access";

	print ARGV_HISTORY join( "\t", @ARGV ), "\n";
    }
}

END
{
    if( $log_history )
    {
	close( ARGV_HISTORY );
    }
}

### Standard Getopt::Long / Pod::Usage header ###

our $VERSION = '0.02';

use modules qw(Getopt::Long Pod::Usage);

	my %options = ( display => 10, type => 'SGML', pmid => 0, xslt => '' );
        
	GetOptions(\%options, qw( help|? man debug! parse_debug! decode display=i silent! type=s pmid! xslt=s ) ) or pod2usage(2);

	my $DEBUG = $options{'debug'};

	pod2usage(1) if( $options{'help'} || ( @ARGV < 1 && not exists $options{'man'} ) );

        pod2usage( -exitstatus => 0, -verbose => 2 ) if( $options{'man'} );

### Main Program starts here ###

use IO::Extended ':all';

use modules qw(LWP::UserAgent URI HTML::Entities XML::LibXML XML::LibXSLT XML::XPath WWW::Search WWW::Search::NCBI::PubMed);

	if( $options{ pmid } )
	{
	    my @pmid = @ARGV;

	    # 'http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?cmd=Text&db=PubMed&dopt=SGML&pmid=';

	    # 'http://www.ncbi.nlm.nih.gov/entrez/utils/pmfetch.fcgi?db=PubMed&id=&report=sgml&mode=file';

	    my $uri = URI->new( WWW::Search::NCBI::PubMed->site_abs_url );

	    #$uri->port( 80 );

	    #$uri->userinfo( 'user:pw' );

	    $uri->path( '/entrez/utils/pmfetch.fcgi' );

	    $uri->query_form( db => 'PubMed', report => $options{type} || 'sgml', mode => 'file', id => join( ',', @pmid ) );

	    printfln 'URI_PATH: %s URI_QUERY: %s', $uri->path, $uri->query if $DEBUG;

	    warn $uri->as_string, "\n" if $DEBUG;

	    my $ua = LWP::UserAgent->new;

	    my $request = HTTP::Request->new( 'GET', $uri->as_string );

	    my $response = $ua->request( $request );

	    die $response->status_line if $response->is_error;

	    die 'Request not successfull' unless $response->is_success;

	    my $content = $response->content;

	    print $content if $DEBUG;

	    # if source is from html'd xml

	    if( $options{decode} )
	    {
		decode_entities( $content );

		$content =~ s/^<pre>//;

		$content =~ s/<\/pre>$//;

		$content = '<?xml version="1.0" standalone="yes"?>'.$content;

		print "done\n";
	    }

	    if( $options{type} =~ /sgml/i )
	    {
		# Strip DTD, because NLM did some silly mistakes
		
		$content =~ s/^<!DOCTYPE .*?>//;
		
		if( $options{xslt} )
		{
		    foreach ( qw(ascii html) )
		    {
			if( $options{xslt} eq 'to_'.$_ )
			{
			    $options{xslt} = WWW::Search::NCBI::PubMed->_files_enclose->{ 'article_to_'.$_.'.xslt' };
			}
		    }

		    my $parser = XML::LibXML->new();
		    
		    my $xslt = XML::LibXSLT->new();
		    
		    my $stylesheet = $xslt->parse_stylesheet_file( $options{xslt} );
		    
		    my $results = $stylesheet->transform( $parser->parse_string( $content ) );
		    
		    print $stylesheet->output_string($results);
		}
		else
		{
		    my $xp = XML::XPath->new( xml => $content ) or die;
		    
		    foreach my $set ($xp->find('/PubmedArticleSet')->get_nodelist)
		    {
			foreach my $article ($set->find('PubmedArticle')->get_nodelist)
			{
			    #printf "%s"."\n\n", XML::XPath::XMLParser::as_string($article);
			    
			    #print $article->find('common-name')->string_value;
			    
			    #print $article->find('conservation/@status');
			    
			    #print ' (' . $article->find('@name') . ') ';
			    
			    foreach my $field ( qw( ArticleTitle Abstract/AbstractText Affiliation ) )
			    {
				print "$field: ", $article->find('MedlineCitation/Article/'.$field ), "\n\n";
			    }
			}
		    }
		}
	    }
	    else
	    {
		print $content;
	    }
	}
        else
        {
	    foreach my $query ( @ARGV )
	    {
		$query =~ s/'/"/g;

		my $search = new WWW::Search('NCBI::PubMed') or die $!;

		$search->maximum_to_retrieve( $options{display} );

		my $href_options =		    
		{ 
		    dispmax => $search->maximum_to_retrieve,
		    
		    search_debug => $options{debug},
		    
		    search_parse_debug => $options{parse_debug},
		};
		
		$search->native_query( $query, $href_options );
		
		printfln "Query %S [%d hits, display %s]...\n", $query, $search->approximate_result_count, $search->maximum_to_retrieve || 'ALL';
		
		my $result;

                my $cnt = 0;
		
		while ( $result = $search->next_result() )
		{
		    warn "empty result." and next unless $result->title || $result->url || $result->description;
		    
		    unless( $options{silent} )
		    {
			println ++$cnt, ") ";
			
			indn;
			
			printfln "%-10s %s", 'DESC', $result->description, "\n" if $result->description;
			
			printfln "%-10s %s", 'TITLE', $result->title if $result->title;
			
			printfln "%-10s %s", 'SOURCE', $result->source if $result->url;
			
			printfln "%-10s %s", 'URL', URI->new_abs( $result->url, WWW::Search::NCBI::PubMed->site_abs_url ) if $result->url;
			
			printfln "%-10s %s", 'INDX_DATE', $result->index_date, "\n" if $result->description;
			
			indb;
		    }
		}

		println "No results returned. (Refine query?)" and exit unless $cnt;

		printfln "%d/%d hits displayed.", $cnt, $search->approximate_result_count;
	    }
	}

__END__

=head1 NAME

pubmed - inofficial shell interface to the PubMed service of the NLM L<http://www.pubmed.com>

=head1 SYNOPSIS

pubmed (options) query [query, ...]

pubmed (options) --pmid pmid [pmid, ...]

B<query> shall be a query-string as it would be entered in web frontend at L<http://www.pubmed.com>.

B<pmid> are PubMed Id's as primary identifiers of records within the PubMed database

B<options> are

   --display (integer)               maximum hits to display
   --silent  (boolean)               does not list the hits
   --pmid    (boolean)               fetches entries by pmid instead of doing search query
   --xslt    (string)                xslt file to transform XML output

   --debug   (boolean)               turn verbose debug information ON
   --help    (boolean)               brief help message
   --man     (boolean)               full documentation

=head1 OPTIONS

=head2 --debug

Turn verbose debug information ON.

=head2 --help

Print a brief help message and exits.

=head2 --man

Prints the manual page and exits.

=head2 --pmid

Instead of retreiving via a search query entries are fetched via PubMed ID's.
This allows to control the type of information returned (--type).

=head2 --xslt

This is an optional path to a xslt file. It will be used to transform and output the incoming xml markup. The keywords "to_html" and "to_ascii" are reserved as a value which refers to internal xslt files.

=head2 --type

Return type format:

    "SGML" => "XML/SGML",  
    
    "DocSum" => "Summary",
    
    "Brief" => "Brief",
    
    "Abstract" => "Abstract",
    
    "Citation" => "Citation",
    
    "MEDLINE" => "MEDLINE",
    
    "ASN.1" => "ASN.1",
    
    "ExternalLink" => "LinkOut",

Deprecated are:

    "pmlink_Related" => "Related Articles",

    "pmlink_AALinks" => "Protein Links",
    
    "pmlink_DNALinks" => "Nucleotide Links",
    
    "pmlink_PSLinks" => "Popset Links",
    
    "pmlink_StrLinks" => "Structure Links",
    
    "pmlink_GenLinks" => "Genome Links",
    
    "pmlink_OmLinks" => "OMIM Links",

=head1 DESCRIPTION

B<pubmed> searches the PubMed service from the shell. It runs queries against the service cgi scripts (currently described by L<http://www.ncbi.nlm.nih.gov/entrez/utils/pmfetch_help.html> and returns the result locally interpreted (xml via xslt) or as formated by NCBI. As a fallback it utilizes WWW::Search::NCBI::PubMed to extract information from the html outputs instead of retrieving preformatted plain data.

=head1 QUERY FORMAT

Please visit L<http://www.ncbi.nlm.nih.gov/entrez/query/static/help/pmhelp.html> for a comprehensive introduction. Also
enhance to the section L</SEARCH FIELD TAGS> below to get a compressed overview of available query syntax.

=head2 FORMAT MODIFICATIONS

Because both, win32 default shell and query field, use double quotes as standard string text delimiters, shell doublequotes are required to be escaped.
I therefore added the translation of singlequotes to doulequotes to have a more convenient syntax.

 pubmed "'Birchmeier W' [au]" 

is translated to (more cryptic)

 pubmed "\"Birchmeier W\" [au]" 

Note that this is just a simple replacement within the query string syntax from the shell tool, not the web search form field.

=head1 IMPORTANT NOTE (from the service provider)

=head2 SERVICE LOAD

Do not overload NCBI's systems. Users intending to send numerous queries and/or retrieve large numbers of records from Entrez should comply with the following: Run retrieval scripts between 7 PM and 5 AM Eastern Time weekdays or any time on weekends. Make no more than one request every 2 seconds.

=head2 COPYRIGHT

NCBI's Disclaimer and Copyright notice must be evident to users of your service. NLM does not hold the copyright on the abstracts found in PubMed, the journal publishers do. NLM provides no legal advice concerning distribution of copyrighted materials.  This advice should be sought from your legal counsel.

=head2 IDENTIFIER NUMBERS

Note: In the future a MEDLINE UI will no longer be assigned to PubMed citations. Citations will only be assigned a PubMed UI (PMID).

=head1 EXAMPLES

=head2 Lists the 10 most recent entries from the author "Birchmeier W"

 pubmed "'Birchmeier W' [au]" --display 10

=head2 Lists the 10 most recent entries from the author "Paus R" with the string "hair" in the title

 pubmed "'Paus>[au] AND hair[ti]' --display 10

=head2 Query all publications from "Paus-R" with mesh heading 'hair follicle'

 pubmed "'Paus-R' [au] AND hair follicle[me]" --display 10

=head2 Query all publications with "hair follicle" or "anagen" anywhere in the record

 pubmed "hair follicle [ALL] OR anagen [ALL]"

=head2 Show an PubMed record in XML

 pubmed --pmid 11179999

=head2 Show a PubMed record

 pubmed --pmid --type=ABSTRACT 9306958

=head2 Show PubMed records XML and transform with a XSLT file

 pubmed --pmid --xslt=xml/article_to_ascii.xslt --debug 9306958

=head2 Show PubMed records XML and transform with a XSLT file

 pubmed --pmid --xslt=xml/article_to_html.xslt --debug 9306958

=head2 Print record in SGML/XML format

 pubmed --pmid --type=SGML 9306958

=head2 Print record in Summary format

 pubmed --pmid --type=DocSum 9306958

=head2 Print record in Brief format

 pubmed --pmid --type=Brief 9306958

=head2 Print record in Abstract format 

 pubmed --pmid --type=Abstract 9306958

=head2 Print record in Citation format 

 pubmed --pmid --type=Citation 9306958

=head2 Print record in MEDLINE format 

 pubmed --pmid --type=MEDLINE 9306958

=head2 Print record in ASN.1 format 

 pubmed --pmid --type=ASN.1 9306958

=head2 Print record in LinkOut format 

 pubmed --pmid --type=ExternalLink 9306958

=head2 Print record after transformed by the internal to_ascii xslt file

 pubmed --pmid --xslt=to_ascii 9306958

=head2 Print record after transformed by a custom xslt file

 pubmed --pmid --xslt=/xslt/to_output.xslt 9306958

=head1 QUERY FORMAT

This is a short version of the section "Search Field Descriptions and Tags" as described in L<http://www.ncbi.nlm.nih.gov/entrez/query/static/help/pmhelp.html#SearchFieldDescriptionsandTags> (27 April 2004). You should read the original because the information below may be already invalid or outdated. A very comprehensive tutorial is available at L<http://www.nlm.nih.gov/bsd/pubmed_tutorial/m1001.html>.

Only the keyword within the brackets [] are used in the query. So if one wants to search the sex hormone "estradiol" within the "Substance Name" field [NM] you should form the query as:

 pubmed "Estradiol [NM]"

=head2 SEARCH FIELD TAGS

=head3 Affiliation [AD]

May include the institutional affiliation and address (including e-mail address) of the first author of the article as it appears in the journal. This field can be used to search for work done at specific institutions (e.g., cleveland [ad] AND clinic [ad]).  

=head3 All Fields [ALL]

Includes all searchable PubMed fields. However, only terms where there is no match found in one of the Translation tables or Indexes via the Automatic Term Mapping process will be searched in All Fields. PubMed ignores stopwords from search queries. 

=head3 Author [AU]

Various limits on the number of authors included in the MEDLINE citation have existed over the years (see NLM policy on author names). The format to search for this field is: last name followed by a space and up to the first two initials followed by a space and a suffix abbreviation, if applicable, all without periods or a comma after the last name (e.g., fauci as or o'brien jc jr). Initials and suffixes may be omitted when searching. PubMed automatically truncates on an author's name to account for varying initials, e.g., o'brien j [au] will retrieve o'brien ja, o'brien jb, o'brien jc jr, as well as o'brien j. To turn off this automatic truncation, enclose the author's name in double quotes and qualify with [au] in brackets, e.g., "o'brien j" [au] to retrieve just o'brien j. Full names display in the FAU field on the MEDLINE display format. The FAU field is not searchable. 

=head3 Corporate Author [CN] 

Identifies the corporate authorship of an article. Corporate names display exactly as they appear in the journal. Note: Citations indexed pre-2000 and some citations indexed in 2000-2001 retain corporate authors at the end of the title field. For comprehensive searches, consider including terms and/or words searched in the title field [ti]. 

=head3 EC/RN Number [RN]

Number assigned by the Enzyme Commission (EC) to designate a particular enzyme or by the Chemical Abstracts Service (CAS) for Registry Numbers, e.g., 1-5-20-4[rn] 

=head3 Entrez Date [EDAT]

Date the citation was added to the PubMed database. The Entrez Date is set to the Publication Date on citations before September 1997, when this field was first added to PubMed. Citations are  displayed in Entrez Date order which is last in, first out. Dates or date ranges must be entered using the format YYYY/MM/DD [edat], e.g., 1998/04/06 [edat] . The month and day are optional (e.g., 1998 [edat] or 1998/03 [edat]). To enter a date range, insert a colon (:) between each date (e.g., 1996:1997 [edat] or 1998/01:1998/04 [edat]). 

Note: 
The Entrez Date is not changed to reflect the date a publisher supplied record is elevated to in process or when an in process record is elevated to indexed for MEDLINE. Therefore, use caution when your strategy includes MeSH terms and a date or date range using the search field tag, [edat].
Filter [FILTER] [SB] Technical tags used by LinkOut, filters include: 
loall[sb] - Citations with LinkOut links in PubMed.
free full text[sb]  - Citations that include a link to a free full-text article.
full text[sb] - Citations that include a link to a full-text article.

Use Preview/Index to browse the LinkOut index. Select Filter from the All Fields pull-down menu, enter 'loprov' in the query box, click Index. PubMed displays an alphabetic list of the LinkOut providers. The 'losubj' and 'loattr' entries are links indexed by Subject Types and Attributes. The  'loftext' entries include a link to the online full-text of a journal citation. 

=head3 Grant Number [GR]

Research grant numbers, contract numbers, or both that designate financial support by any agency of the US PHS (Public Health Service). The three pieces of the grant number (LM05545 - number, LM - acronym, and NLM - institute mnemonic) are each individually searchable using the [gr] tag. 

=head3 Issue [IP]

The number of the journal issue in which the article was published. 
Investigator [IR] Names of the NASA-funded principal investigator(s) who conducted the research. Search names following the Author field format, e.g., soller b [ir] 

=head3 Journal Title [TA]

The journal title abbreviation, full journal title, or ISSN number (e.g., J Biol Chem, Journal of Biological Chemistry, 0021-9258). The Journals database is available from the PubMed homepage sidebar to look up the full name, abbreviation, and ISSN number of a journal. If a journal title contains special characters, e.g., parentheses, brackets, enter the name without these characters, e.g., enter J Hand Surg [Am] as J Hand Surg Am. 

=head3 Language [LA]

The language in which the article was published. Note that many non-English articles have English language abstracts. You can either enter the language or enter just the first three characters of most languages, e.g., chi [la] retrieves the same as chinese [la]. The most notable exception is jpn [la] for Japanese. 

=head3 MeSH Date [MHDA] 

The date the citation was indexed with MeSH Terms and elevated to MEDLINE for citations with an Entrez Date after March 4, 2000.  The MeSH Date is initially set to the Entrez Date when the citation is added to PubMed. If the MeSH Date and Entrez Date on a citation are the same, and the Entrez Date is after March 4, 2000, the citation has not yet been indexed.  Dates or date ranges must be entered using the format YYYY/MM/DD [mhda], e.g. 2000/03/15 [mhda] . The month and day are optional (e.g., 2000 [mhda] or 2000/03 [mhda]). To enter a date range, insert a colon (:) between each date (e.g., 1999:2000 [mhda] or 2000/03:2000/04 [mhda]). 

=head3 MeSH Major Topic [MAJR]

A MeSH term that is one of the main topics discussed in the article denoted by an asterisk on the MeSH term or MeSH/Subheading combination, e.g., Cytokines/physiology* See MeSH Terms L<http://www.ncbi.nlm.nih.gov/entrez/query/static/help/pmhelp.html>.

=head3 MeSH Subheadings [SH]

MeSH Subheadings are used with MeSH terms to help describe more completely a particular aspect of a subject. For example, the drug therapy of asthma is displayed as asthma/drug therapy, see MeSH/Subheading Combinations. The MeSH Subheading field allows users to "free float" Subheadings, e.g., hypertension [mh] AND toxicity [sh]. MeSH Subheadings automatically include the more specific Subheading terms under the term in a search. To turn off this automatic feature, use the search syntax [sh:noexp], e.g., therapy [sh:noexp].  In addition, you can enter the MEDLINE two letter MeSH Subheading abbreviations rather than spelling out the Subheading, e.g., dh [sh] = diet therapy [sh]. 

=head3 MeSH Terms [MH]

NLM's Medical Subject Headings controlled vocabulary of biomedical terms that is used to describe the subject of each journal article in MEDLINE. MeSH contains more than 22,000 terms and is updated annually to reflect changes in medicine and medical terminology. MeSH terms are arranged hierarchically by subject categories with more specific terms arranged beneath broader terms. PubMed allows you to view this hierarchy and select terms for searching in the MeSH Database. 
Skilled subject analysts examine journal articles and assign to each the most specific MeSH terms applicable - typically ten to twelve. Applying the MeSH vocabulary ensures that articles are uniformly indexed by subject, whatever the author's words. 

=head3 NLM Unique ID [JID]

The alpha-numeric identifier for the cited journal that was assigned by NLM's Integrated Library System LOCATORplus, e.g., 0375267 [jid]. 
Other Term [OT] Mostly non-MeSH subject terms (keywords), including NASA Space Flight Mission, assigned by an organization other than NLM. The Other Term data may be marked with an asterisk to indicate a major concept, however asterisks are for display only. You cannot search Other Terms with a major concept tag. The OT field is searchable with the Text Word [tw] and Other Term [ot] search tags. 
Owner Acronym that identifies the organization that supplied the citation data. Search using owner + the owner acronym, e.g. ownernasa. 

=head3 Pagination [PG]

Enter only the first page number that the article appears on. The citation will display the full pagination of the article but this field is searchable using only the first page number. See Single Citation Matcher L<http://www.ncbi.nlm.nih.gov/entrez/query/static/help/pmhelp.html>.

=head3 Personal Name as Subject [PS]

Use this search field tag to limit retrieval to where the name is the subject of the article, e.g., varmus h [ps]. Search names following the Author field format, e.g., varmus h[ps]. 

=head3 Pharmacologic Action MeSH Terms [PA]

Substances known to have a particular pharmacologic action. Each pharmacologic action term index is created with the drug/substance terms known to have that affect. This includes both MeSH terms and terms for Supplementary Concept Records. 

=head3 Place of Publication [PL]

Indicates the cited journal's country of publication. Geographic Place of Publication regions are not searchable. In order to retrieve records for all countries in a region (e.g., North America) it is necessary to OR together the countries of interest. Note: This field is not included in All Fields or Text Word retrieval. 

=head3 Publication Date [DP]

The date that the article was published. Dates or date ranges must be searched using the format YYYY/MM/DD [dp], e.g. 1998/03/06 [dp] . The month and day are optional (e.g., 1998 [dp] or 1998/03 [dp]). To enter a date range, insert a colon (:) between each date (e.g., 1996:1998 [dp] or 1998/01:1998/04 [dp]). 
Note: 

Journals vary in the way the publication date appears on an issue. Some journals include just the year, whereas others include the year plus month or year plus month plus day. And, some journals use the year and season (e.g., Winter 1997). The publication date in the citation is recorded as it appears in the journal, e.g., 1996 [dp] or 1995:2000 [dp].

=head3 Publication Type [PT]

Describes the type of material the article represents (e.g., Review, Clinical Trial, Retracted Publication, Letter); see full listing, e.g., review[pt]. 

=head3 Secondary Source ID [SI]

The SI field identifies secondary source databanks and accession numbers of molecular sequences discussed in MEDLINE articles.  The field is composed of the source followed by a slash followed by an accession number and can be searched with one or both components, e.g., genbank [si], AF001892 [si], genbank/AF001892 [si]. 

=head3 Subset [SB]

Method of restricting retrieval by Subject Subsets and Citation Status Subsets. Searchable with [SB]. Other Subsets are available for searching that do not use this search tag. See also Limits and LinkOut L<http://www.ncbi.nlm.nih.gov/entrez/query/static/help/pmhelp.html>.

=head3 Substance Name [NM]

The name of a chemical discussed in the article. Synonyms to the Supplementary Concept Substance Name will automatically map when qualified with [nm]. This field was implemented in mid-1980. Many chemical names are searchable as MeSH terms before that date. 

=head3 Text Words [TW]

Includes all words and numbers in the title, abstract, other abstract, MeSH terms, MeSH Subheadings, chemical substance names, personal name as subject, MEDLINE Secondary Source, and Other Terms typically non-MeSH subject terms (keywords), including NASA Space Flight Mission, assigned by an organization other than NLM. 

=head3 Title [TI]

Words and numbers included in the title of a citation. 

=head3 Title/Abstract [TIAB]

Words and numbers included in the title, abstract, and other abstract of a citation. 

=head3 Unique Identifier [UID]

PubMed Unique Identifier PMID. To search for the PMID type in the number with or without the search field tag [uid]. You can search for several ID numbers by entering each number in the query box separated by a space (e.g., 95091318 97465762); PubMed will OR the terms together. 
To search in combination with other terms, you must enter the search field tag, e.g., smith [au] AND (10403340 [uid] OR vaccines [mh]). 

=head3 Volume [VI]

The number of the journal volume in which an article is published. See Single Citation Matcher L<http://www.ncbi.nlm.nih.gov/entrez/query/static/help/pmhelp.html>.

=head1 BUGS AND CAVEATS

Because the parser depends on the static webserver response it may brake as soon as the html is significantly altered. Please inform the author via L<http://rt.cpan.org> if this happens and subject all other reports there. Escpecially I am open to every improvement towards robust parsing.
 
=head1 FURTHER TOOLS and API

NCBI cgi service scripts are well documented L<http://www.ncbi.nlm.nih.gov:80/entrez/utils/utils_index.html>. The utilities conform to the NCBIPubMed DTD, NLMMedline DTD, NLMMedlineCitation DTD, and NLMCommon DTD.

=head1 AUTHOR

Murat Uenalan <murat.uenalan@gmx.de>

=head1 COPYRIGHT AND DISCLAIMERS

I personally encourage everybody to read L<http://www.ncbi.nlm.nih.gov/About/disclaimer.html> before using the service. This command-line utility is like surfing the original pages and therefore all legal consequences that refer to the website should be inherited by this tool. 

While this tool tries to present the original information in its essence via extracting interesting information, it may fail to do so. So do not rely on the information retreived by this tool without rigorous confirmation of the original sources (http://www.pubmed.com website or original print journal articles).

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 NCBI DISCLAIMER AND COPYRIGHT 

Please read http://www.ncbi.nlm.nih.gov/About/disclaimer.html.
