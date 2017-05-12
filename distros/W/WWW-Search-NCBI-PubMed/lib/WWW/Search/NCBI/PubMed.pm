package WWW::Search::NCBI::PubMed;

use strict; use warnings;

our $VERSION = '0.01';

our $MAINTAINER = 'muenalan@cpan.org';

use WWW::Search qw(generic_option strip_tags);

use WWW::SearchResult;

use Carp;

use IO::Extended qw(:all);

use URI;

use Path::Class;

our @ISA = qw(WWW::Search);

   # add all enclosed files (xslt) to a central registry (in a OS-independant way)
   # they are supposed to live near this modules dir

our $_href_files_enclosed;

BEGIN
{
    my $dir = Path::Class::File->new( __FILE__ )->dir->subdir( 'PubMed' );

    foreach ( qw(article_to_ascii.xslt article_to_html.xslt) )
    {
	$_href_files_enclosed->{ $_ } = $dir->file( $_ ).'';
    }
}

sub _files_enclosed { $_href_files_enclosed }

sub site_abs_url { 'http://www.ncbi.nlm.nih.gov' }

sub native_setup_search 
{
        my $this = shift;

	my $native_query = shift;

	my $href_options = shift;


        $this->{_debug} = $href_options->{'search_debug'};

	$this->{_debug_parse} = $href_options->{'search_parse_debug'};

        $this->{agent_e_mail} = 'nomail@nospam.com';			       
								
        $this->{_next_to_retrieve} = 1;
				
        $this->{_num_hits} = 0;

        $this->user_agent('user');


	  # Copy options to cgi_params

	my $cgi_params = {};

        foreach ( sort keys %$href_options )
	{
	    next if generic_option($_);

	    $cgi_params->{$_} = $href_options->{$_};
	}

	  # Construct cgi URI

	my $uri = URI->new( WWW::Search::NCBI::PubMed->site_abs_url );
	
	#$uri->port( 80 );
	
	#$uri->userinfo( 'user:pw' );
	
	$uri->path( 'entrez/query.fcgi' );

#<Li>db=db_name (mandatory)</Li>
#<Li>report=[docsum, brief, abstract, citation, medline, asn.1, mlasn1, uilist, sgml, gen] (Optional; default is asn.1)</Li>
#<Li>mode=[html, file, text, asn.1, xml] (Optional; default is html)</Li>
#<Li>dispstart - first element to display, from 0 to count - 1, (Optional; default is 0)</Li>
#<Li>dispmax - number of items to display (Optional; default is all elements, from dispstart)</Li>

	my $cgi_params_default = 
	{
	    term => '',
	    
	    db => 'PubMed', 
	    
	    orig_db => 'PubMed',
	    
	    cmd_current => '',
	    
	    WebEnv => '',
	    
	    cmd => 'search',
	};

	  # WWW::Search::escape_query not required because URI already escapes carefully

	$cgi_params_default->{term} = $native_query;

	  # nice trick to override default parameters via the user-supplied params/options

	$uri->query_form( %$cgi_params_default, %$cgi_params );

	printfln 'URI: %s', $uri->as_string if $this->{_debug};

	$this->{_next_url} = $uri->as_string;
}

sub native_retrieve_some 
{
    my $this = shift;

        open ( STORE, '>www_search_response.txt' ) or die $! if $this->{_debug_parse};;

        print STDERR "**PubMed Search Underway**\n" if $this->{_debug_parse};;

        return undef unless defined( $this->{_next_url} );

        # If this is not the first page of results, sleep so as to not
        # overload the server:

        $this->user_agent_delay if 1 < $this->{'_next_to_retrieve'};

        my ( $response ) = $this->http_request( GET => $this->{_next_url} );

	printf "RESPONSE %d bytes content received\n", length $response->content if $this->{_debug_parse};;
    
        $this->{response} = $response;

	unless( $response->is_success )
	{
	    print "RESPONSE DID NOT SUCCEEDED" if $this->{_debug_parse};;

	    return undef;
	}

        $this->{'_next_url'} = undef;

        print STDERR "**PubMed Response\n" if $this->{_debug_parse};;

        # parse the output

        my ($HEADER, $AUTHORS, $URL, $TITLE) = qw(HE AUTHORS URL DE);

        my $state_next = $HEADER;

        my $hit; # WWW::SearchResult object

	my $line_cnt = 0;

	my @content_lines = $this->split_lines( $response->content);

	printfln 'DEBUG %d lines of content', scalar @content_lines if $this->{_debug_parse};;

	foreach ( @content_lines )
	{
	    chomp;

	    next unless length; #m@^$@; # short circuit for blank lines

	    printfln STORE "    %3d> $_", $line_cnt++ if $this->{_debug_parse};;
	    
	    #Items 1-20 of 152</td>
	    #Page 1 of 8</td>

	    # switched from Page to Items - MUENALAN

	    if( $state_next eq $HEADER && m{>Items.*of\s+(\d+)<}i )
	    {
		print STORE "HEAD> $_\n" if $this->{_debug_parse};;

		$this->approximate_result_count($1);
		
		$state_next = $AUTHORS;
	    }

#<td width="100%"><font size="-1"><a href="/entrez/query.fcgi?cmd=Retrieve&db=pubmed&dopt=Abstract&list_uids=15105374">Bulgakov OV, Eggenschwiler JT, Hong DH, Anderson KV, Li T.</a></font></td>

            # Get URL

	    elsif( $state_next eq $AUTHORS && m{<a href="(/entrez/query\.fcgi\?cmd=Retrieve&db=pubmed&dopt=Abstract&list_uids=\d+)">(.+?)</a>}i )
	    {
		my ($url, $authors) = ( $1, $2 );

		$url =~ s/dopt=Abstract/dopt=Medline/g;

		$hit = new WWW::SearchResult;

		$hit->add_url( $url );

		$hit->description( $authors );

		$state_next = $URL;
		
		print STORE "AUTH> $_\n"  if $this->{_debug_parse};;
		
		$this->{_num_hits}++;

		$state_next = $TITLE; # enforce that a description is found next
	    }
 
              # Get DESC (the last of entry fields)

	    elsif( $state_next eq $TITLE && m{td colspan=\"2\">(.+)<\/font></td>}i )
	    {
		my $str = $1;

		$str =~ s/<font size=\"-1\">//gi;

		my ( $title, $journal, $record_status ) = split/<br>/, $str;

		$hit->title($title);

                $hit->index_date( $record_status );

		$hit->source( $journal );

		$state_next = $AUTHORS;
		
		print STORE "DESC> $_\n"  if $this->{_debug_parse};;

	        if( defined($hit) )
	        {
	            push @{$this->{cache}}, $hit;

	            $hit = undef;
	        }
	    }
           
	    $this->{_next_url} = undef;
	}

return $this->{_num_hits};
}

1;

__END__


=head1 NAME

WWW::Search::NCBI::PubMed - fetch bibliographic entries in NLM's PubMed database

=head1 SYNOPSIS

 use WWW::Search;

  my $www_search = new WWW::Search('NCBI::PubMed');

  $www_search->maximum_to_retrieve( 10 );

  $www_search->native_query( my $query_pubmed = 'estradiol [NM]' );

  while ( my $r = $www_search->next_result )
  {
     print "$_\n" for ( $r->url, $r->title, $r->description );
  }

=head1 KEYWORDS

internet, searching, content retrieval, PubMed, MEDLINE, NCBI, National Center for Biotechnology Information, National Library of Medicine, NLM.

=head1 DESCRIPTION

PubMed is the National Library of Medicine's search service that provides access to over 11 million citations in MEDLINE, PreMEDLINE, and other related databases, with links to participating online journals. This module is an interface to access this service via the generic C<WWW::Search> interface. This class exports no public interface; all interaction should be done through WWW::Search objects.

=head1 QUERY FORMAT

Please visit L<http://www.ncbi.nlm.nih.gov/entrez/query/static/help/pmhelp.html> for a comprehensive introduction. Also
enhance to the section L</SEARCH FIELD TAGS> below to get a compressed overview of available query syntax.

=head1 IMPORTANT NOTE (from the service provider)

=head2 SERVICE LOAD

Do not overload NCBI's systems. Users intending to send numerous queries and/or retrieve large numbers of records from Entrez should comply with the following: Run retrieval scripts between 7 PM and 5 AM Eastern Time weekdays or any time on weekends. Make no more than one request every 2 seconds.

=head2 COPYRIGHT

NCBI's Disclaimer and Copyright notice must be evident to users of your service. NLM does not hold the copyright on the abstracts found in PubMed, the journal publishers do. NLM provides no legal advice concerning distribution of copyrighted materials.  This advice should be sought from your legal counsel.

=head2 IDENTIFIER NUMBERS

Note: In the future a MEDLINE UI will no longer be assigned to PubMed citations. Citations will only be assigned a PubMed UI (PMID).

=head1 QUERY FORMAT

This is a short version of the section "Search Field Descriptions and Tags" as described in L<http://www.ncbi.nlm.nih.gov/entrez/query/static/help/pmhelp.html#SearchFieldDescriptionsandTags> (27 April 2004). You should read the original because the information below may be already invalid or outdated. A very comprehensive tutorial is available at L<http://www.nlm.nih.gov/bsd/pubmed_tutorial/m1001.html>.

Only the keyword within the brackets [] are used in the query. So if one wants to search the sex hormone "estradiol" within the "Substance Name" field [NM] you should form the query as:

 $query_pubmed = 'Estradiol [NM]'

=head1 QUERY EXAMPLES

=head2 Lists the 10 most recent entries from the author "Birchmeier W"

 $query_pubmed = '"Birchmeier W" [au]'

=head2 Lists the 10 most recent entries from the author "Paus R" with the string "hair" in the title

 $query_pubmed = '"Paus"[au] AND hair[ti]'

=head2 Query all publications from "Paus-R" with mesh heading 'hair follicle'

 $query_pubmed = '"Paus-R" [au] AND hair follicle[me]'

=head2 Query all publications with "hair follicle" or "anagen" anywhere in the record

 $query_pubmed = 'hair follicle [ALL] OR anagen [ALL]'

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

=head1 EXTRA METHODS

=head2 WWW::Search::NCBI::PubMed->_files_enclose

This returns a static href with enclosed files added to the distribution. Escpecially these are xslt files used by the pubmed.pl script which is part of this distribution. The href looks like:

 {
   "article_to_ascii.xslt" => "lib\\WWW\\Search\\NCBI\\PubMed\\article_to_ascii.xslt",
   "article_to_html.xslt"  => "lib\\WWW\\Search\\NCBI\\PubMed\\article_to_html.xslt",
 }

=head2 WWW::Search::NCBI::PubMed->site_abs_url

Returns the absolute base url of the PubMed service L<http://www.ncbi.nlm.nih.gov>.

=head1 FURTHER TOOLS and API

NCBI cgi service scripts are well documented L<http://www.ncbi.nlm.nih.gov:80/entrez/utils/utils_index.html>. The utilities conform to the NCBIPubMed DTD, NLMMedline DTD, NLMMedlineCitation DTD, and NLMCommon DTD.

=head1 AUTHOR

muenalan@cpan.org <Murat Uenalan>.

C<WWW::Search::NCBI::PubMed> was inspired by the outdated C<WWW::Search::PubMed> (last updated 2000). 
C<WWW::Search::PubMed> was written by Jim Smyser <jsmyser@bigfoot.com>.

=head1 COPYRIGHT AND DISCLAIMERS

This module is Copyright (c) 1994-2003 Murat Uenana. Germany. All rights
reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. 

=head1 NCBI DISCLAIMER AND COPYRIGHT 

I personally encourage everybody to read L<http://www.ncbi.nlm.nih.gov/About/disclaimer.html> before using the service. This command-line utility is like surfing the original pages and therefore all legal consequences that refer to the website should be inherited by this tool. 

While this tool tries to present the original information in its essence via extracting interesting information, it may fail to do so. So do not rely on the information retreived by this tool without rigorous confirmation of the original sources (http://www.pubmed.com website or original print journal articles).

Please read http://www.ncbi.nlm.nih.gov/About/disclaimer.html.

=cut
