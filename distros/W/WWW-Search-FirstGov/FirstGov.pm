# FirstGov.pm
# by Dennis Sutch
#

package WWW::Search::FirstGov;


=head1 NAME

WWW::Search::FirstGov - class for searching http://www.firstgov.gov

=head1 SYNOPSIS

    use WWW::Search;
    my $search = new WWW::Search('FirstGov'); # cAsE matters
    my $query = WWW::Search::escape_query("uncle sam");
    $search->native_query($query);
    while (my $result = $search->next_result()) {
      print $result->url, "\n";
    }

=head1 DESCRIPTION

Class specialization of WWW::Search for searching F<http://www.firstgov.gov>.

FirstGov.gov can return up to 100 hits per page.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 OPTIONS

The following search options can be activated by sending a hash as the
second argument to native_query().

=head2 Result Set Partitioning

=over 4

=item   { 'begin_at' => '100' }

Retrieve results starting at 100th match.

This option is not passed to FirstGov.gov.  Instead, this option is used to
set 'offset', 'act.next.x' and 'act.next.y' options to obtain results starting
the requested starting point.

=item   { 'offset' => '100' }

If 'act.next.x' and 'act.next.y' options are set, retrive results starting at
the 100th plus 1 plus the value of the 'nr' option.  If 'act.prev.x' and
'act.prev.y' options are set, retrive results starting at the 100th plus 1
less the value of the 'nr' option.

Note: Do not use this option.  Use the 'begin_at' option instead.

Note: This option was named 'fr' in a past version of FirstGov.gov's search
engine.

=item   { 'act.next.x' => '1', 'act.next.y' => '1' }

Retrieve next set of results, starting at the value of the 'offset' option plus
1 plus the value of the 'nr' option.

Note: Do not use this option.

=item   { 'act.prev.x' => '1', 'act.prev.y' => '1' }

Retrieve previous set of results, starting at the value of the 'offset'
option plus 1 less the value of the 'nr' option.

Note: Do not use this option.

=item   { 'nr' => '40' }

Retrieve 40 results.

FirstGov.gov returns no more than 100 results at a time.

From FirstGov.gov documentation:

The Number of Results parameter (nr) allows you or the user to set how many
search "hits" appear on each search results page.  If this parameter is not
used, nr is defaulted to 10.

=back

=head2 Query Terms

From FirstGov.gov documentation:

You may have noticed many parameters are suffixed by the number zero (0).
This number essentially groups a set of search parameters sharing the same
suffix number together to form a query statement.  It is possible to link
two or more such statements together.  You might have guessed that this is
accomplished by creating another set of search parameters, this time suffixed
by the number one (1) or higher.  Just be careful to keep track of parameters
and follow the same guidelines as outline above.  For example if you have an
mw0, have corresponding ms0, mt0, etc. parameters.  For each mw1, set its own
corresponding ms1, mt1, etc. parameters.  Be forewarned that the more
complicated the query, the longer it may take to process.

=over 4

=item   { 'mw0' => 'uncle sam' }

Return results that contain the words 'uncle' and 'sam'.

The native_query() method sets this option.

WWW::Search::FirstGov defaults the mw0 option to an empty string.

Note: Do not use the 'mw0' option, instead use the native_query() method and
the 'mw1', 'mw2', ... options.  

From FirstGov.gov documentation:

The Main Words parameter is represented by the input field named mw0.  This
is a text input field that allows a user to enter the word or words they
would like to search for.  

=item   { 'mt0' => 'all' }

=item   { 'mt0' => 'any' }

=item   { 'mt0' => 'phrase' }

WWW::Search::FirstGov defaults the mt0 option to 'all'.



From FirstGov.gov documentation:

The Main Type field (mt0) is used to specify how you want to search for the
words entered in the mw0 field.  You can search for documents containing all
the words provided, any of the words provided, or documents containing the
exact phrase in the order the words are entered.  This is done by setting the
mt0 field to "all", "any", or "phrase".  If this field is not provided, it is
defaulted to "all".

=item   { 'ms0' => 'should' }

=item   { 'ms0' => 'mustnot' }

=item   { 'ms0' => 'must' }

WWW::Search::FirstGov defaults the ms0 option to 'must'.

From FirstGov.gov documentation:

Main Sign field (ms0) further specifies your search.  It can be used to specify
whether words should or must not be present in the document.  This is done by
setting the ms0 field to "should" or "mustnot".  If this field is not provided,
it is defaulted to "should".

=item   { 'in0' => 'any' }

=item   { 'in0' => 'title' }

=item   { 'in0' => 'url' }

Note: The value 'anywhere' was used in place of 'any' in a past version of
FirstGov.gov's search engine.  The value 'home' used in a past version of
FirstGov.gov's search engine is obsolete.

From FirstGov.gov documentation:

The In parameter (in0) can be implemented to tell the search engine where
specifically to search.  Setting in0 to "anywhere" searches the complete web
page of all web pages in a particular database.  [...]  Setting in0 to "title"
searches only the Titles of web pages of a particular database.

=item   { 'in0' => 'domain', 'dom0' => 'doc.gov noaa.gov', 'domToggle' => ' +(' }

=item   { 'in0' => 'domain', 'dom0' => 'doc.gov noaa.gov', 'domToggle' => ' -(' }

The query is limited to searching the doc.gov and noaa.gov domains when the
doToggle option is set to ' +(' (note leading space).  The query is limited to
searching all but the doc.gov and noaa.gov domains when the doToggle option is
set to ' -(' (note leading space).

From the FirstGov.gov documentation:

Setting in0 to "domain" allows you to search only a certain domain or domains,
or domain/path combinations.  Use of this attribute also requires an
additional parameter, the Domain parameter (dom0).  The Domain parameter (dom0),
when used with in0="domain", allows searching of specific domains or
domain/path combinations as described above.  This is useful if you want
a "site search" for your website.  To do this, you could set in0 to domain
and then dom0 to yourdomain.com.  This would ensure that users are only
searching web pages within your domain.  In fact, you may specify as many
domain or domain/path combinations up to 20 that you would like to limit your
searches to.  You can use any combination of domains or domain/path elements
as long as they are separated by a comma or a space.

=item   { 'rs' => '1' }

Results will include variations (example: vote, voting).

=item   { 'doc' => '' }

=item   { 'doc' => 'text/html' }

=item   { 'doc' => 'application/pdf' }

=item   { 'doc' => 'text/xml' }

=item   { 'doc' => 'application/msword' }

=item   { 'doc' => 'application/vnd.ms-excel' }

=item   { 'doc' => 'application/vnd.ms-powerpoint' }

=item   { 'doc' => 'text/plain' }

Restrict results to a type of document.

=item   { 'age' => 'any' }

=item   { 'age' => '1m' }

=item   { 'age' => '3m' }

=item   { 'age' => '6m' }

=item   { 'age' => '9m' }

=item   { 'age' => '1y' }

Restrict results to date document was updated.

=item   { 'sop' => '<', 'siz' => '512', 'byt' => 'b' }

Restrict results to documents less than 512 bytes.

The attribute sop may be set to '<' or '>'.  The attribute 'byt' may be set to
'b', 'kb', or 'mb'.

=item   { 'lang' => '' }

The query is not limited by language.

To limit a query to documents of a specific language, set this option to one of
FirstGov's language abbreviations (an empty string denotes "Any language"):
af - Afrikaans,
sq - Albanian,
ar - Arabic,
eu - Basque,
be - Byelorussian,
bg - Bulgarian,
ca - Catalan,
tzh - Chinese (trad),
szh - Chinese (simp),
hr - Croatian,
cs - Czech,
da - Danish,
nl - Dutch,
en - English,
et - Estonian,
fo - Faeroese,
fi - Finnish,
fr - French,
fy - Frisian,
gl - Galician,
de - German,
el - Greek,
he - Hebrew,
hu - Hungarian,
is - Icelandic,
id - Indonesian,
it - Italian,
ja - Japanese,
ko - Korean,
la - Latin,
lv - Latvian,
lt - Lithuanian,
ms - Malay,
no - Norwegian,
pl - Polish,
pt - Portuguese,
ro - Romanian,
ru - Russian,
sk - Slovak,
sl - Slovenian,
es - Spanish,
sv - Swedish,
th - Thai,
tr - Turkish,
uk - Ukrainian,
vi - Vietnamese,
cy - Welsh

=back

=head2 Specifying Federal and/or State Government Databases

=over 4

=item   { 'db' => 'www' }

Note: The db and st options have been merged into the the db option in the
current version of FirstGov.gov's search engine.  The value 'states' now
specifies searches against all states.

From FirstGov.gov documentation:

The Database field (db) allows you to specify if a search should query
Federal Government websites, State Government websites, or both.  This is done
by setting db to "www" for a Federal Search, setting db to "states" for a
State Search, or "www-fed-all" to search both.  [...]  If the db field is not
provided, it is defaulted to Federal.

List of State and Territory Abbreviations for FirstGov Searching:
AS - All States,
AL - Alabama,
AK - Alaska,
AZ - Arizona,
AR - Arkansas,
CA - California,
CO - Colorado,
CT - Connecticut,
DC - D.C.,
DE - Delaware,
FL - Florida,
GA - Georgia,
HI - Hawaii,
ID - Idaho,
IL - Illinois,
IN - Indiana,
IA - Iowa,
KS - Kansas,
KY - Kentucky,
LA - Louisiana,
ME - Maine,
MD - Maryland,
MA - Massachusetts,
MI - Michigan,
MN - Minnesota,
MS - Mississippi,
MO - Missouri,
MT - Montana,
NE - Nebraska,
NV - Nevada,
NH - New Hampshire,
NJ - New Jersey,
NM - New Mexico,
NY - New York,
NC - North Carolina,
ND - North Dakota,
OH - Ohio,
OK - Oklahoma,
OR - Oregon,
PA - Pennsylvania,
RI - Rhode Island,
SC - South Carolina,
SD - South Dakota,
TN - Tennessee,
TX - Texas,
UT - Utah,
VT - Vermont,
VA - Virginia,
WA - Washington,
WV - West Virginia,
WI - Wisconsin,
WY - Wyoming,
SA - American Samoa,
GU - Guam,
MP - Mariana Islands,
MH - Marshall Islands,
FM - Micronesia,
PR - Puerto Rico,
VI - Virgin Islands.

=back

=head2 Result Presentation

=over 4

=item   { 'rn' => '2' }

Request FirstGov.gov to return pages using affiliate #2's page format.

This option is used by FirstGov.gov to return result pages customized
with headers and footers for the affiliate as identified by the 'rn' option.

When not set, FirstGov.gov currently sets the 'rn' parameter to '2'.

Note: It is suggested that this option not be used (since this class was
developed using results returned with the 'rn' option not set).

From FirstGov.gov documentation:

The Referrer Name (rn) field is used to uniquely identify your affiliate.
Each Affiliate, upon registration, is assigned a referrer ID that corresponds
to it.

=item   { 'srt' => '' }

Sort results by relevance (FirstGov.gov's default).

Additional values are: 8 (Date - ascending), 7 (Date - descending), 6
(Size - ascending), and 5 (Size - descending).

=item   { 'dsc' => 'det' }

=item   { 'dsc' => 'sum' }

Whether ('det') or not ('sum') to highlight search terms in result
summaries.

=back

=head2 Other Options

=over 4

=item   { 'parsed' => 'true' }

The default behavior for FirstGov.gov's search engine is to parse all search
requests, and, if any options are missing or deprecated, rewrite the options
and redirect the browser back to FirstGov.gov.  When the parsed option is set
to "true", FirstGov.gov does not perform this action.

=item   { 'sp' => '1' }

Check spelling of the query terms.  FirstGov.gov will return a message and
a resubmit buttion if it finds misspelled query terms.

Note: WWW::Search::FirstGov does not parse the results for this option.

=item   { 'submit' => 'Search' }

Submit button.

=item   { 'md' => 'adv' }

Function is unknown.

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,
or the specialized AltaVista searches described in options.

An email list is for notifying users of updates to Perl's 
WWW::Search::FirstGov module is avilalable at
http://two.pairlist.net/mailman/listinfo/www-search-firstgov .
It is meant to be a very low volume list that only notifies users when there
is a new version of the module available, and possibly when changes to the
FirstGov search engine have broken the latest version of the module.

=head1 HOW DOES IT WORK?

C<native_setup_search> is called before we do anything.
It initializes our private variables (which all begin with underscores)
and sets up a URL to the first results page in C<{_next_url}>.

C<native_retrieve_some> is called (from C<WWW::Search::retrieve_some>)
whenever more hits are needed.  It calls the LWP library
to fetch the page specified by C<{_next_url}>.
It parses this page, appending any search hits it finds to
C<{cache}>.  If it finds a ``next'' button in the text,
it sets C<{_next_url}> to point to the page for the next
set of results, otherwise it sets it to undef to indicate we're done.

=head1 SUPPORT

Send questions, comments, suggestions, and bug reports to <dsutch@doc.gov>.

To be notified of updates to WWW::Search::FirstGov, subscribe to the update
notification list at http://two.pairlist.net/mailman/listinfo/www-search-firstgov

=head1 AUTHOR

C<WWW::Search::FirstGov> is written and maintained
by Dennis Sutch - <dsutch@doc.gov>.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 BUGS

None reported.

=head1 VERSION HISTORY

1.14  2003-04-08 - Updated parsing.
                   Documented new search parameters.
1.13  2002-06-04 - Updated Makefile.PL to reflect requirement for WWW::Search version 2.33.
                   Rewrote tests to use WWW::Search::Test.
1.12  2002-06-03 - Updated to reflect changes to FirstGov (on 2002 Jun 03 they switched to a new search engine built by Fast Search & Transfer of Oslo, Norway).
                     * The native_query options 'fr' and 'st' are obsolete.
                     * the native_query option 'in0' now accepts the value 'any' instead of 'anywhere', and the value of 'home' is obsolete.
                   Removed redefined WWW::Search functionality.

1.11  2002-03-13 - Upated to reflect changed FirstGov search engine parameters.
                   approximate_result_count() now returns 1 more than the result count when FirstGov's result count is "more than X relevant results". 
                   Changed test case 4 (in test.pl) to finish sooner.

1.10  2002-03-05 - Updated to handle new FirstGov search engine format and to use HTML::TreeBuilder.
                   Fixed problem that caused one too many searches against FirstGov.gov.
                   Documented additional options, including adding notes from FirstGov.gov documentation.

1.04  2001-07-16 - Fixed parsing problem.

1.03  2001-03-01 - Removed 'require 5.005_62;'.

1.02  2001-03-01 - Removed 'my' declarations for package variables.

1.01  2001-02-26 - Fixed problem with quoted sring on MSWin.
                   Removed 'our' declarations.

1.00  2001-02-23 - First publicly-released version.

=cut

#####################################################################
use strict;

require Exporter;
@WWW::Search::FirstGov::EXPORT = qw();
@WWW::Search::FirstGov::EXPORT_OK = qw();
@WWW::Search::FirstGov::ISA = qw( WWW::Search Exporter );
$WWW::Search::FirstGov::VERSION = '1.14';

$WWW::Search::FirstGov::MAINTAINER = 'Dennis Sutch <dsutch@doc.gov>';

use Carp ();
use WWW::Search( 'generic_option' );
require WWW::SearchResult;

my $SEARCH_URL_PATH = 'http://www.firstgov.gov/fgsearch/';

my $default_option = {
		'search_url' => $SEARCH_URL_PATH . 'index.jsp',
#		'mw0' => '',  # search words
		'offset' => 0,  # return results starting at match number 'offset' plus 1 and plus (or minus) 'nr', when act.next.x and .y (or act.prev.x and .y) are set
		'nr' => 20,  # number of results returned per page (max = 100)
		'mt0' => 'all',  # match: "all" = All of the words | "any" = Any of the words | "phrase" = The exact phrase
		'ms0' => 'must',  # "should" = Should include | "mustnot" = Must not include | "must" = Must include
		'parsed' => 'true',  # (added by FirstGov.gov's redirect)
		};

sub native_setup_search {
	my($self, $native_query, $native_options_ref) = @_;
	$self->{'_debug'} = $native_options_ref->{'search_debug'};
	$self->{'_debug'} = 2 if ($native_options_ref->{'search_parse_debug'});
	$self->{'_debug'} = 0 if (!defined($self->{'_debug'}));

	print STDERR " + WWW::Search::FirstGov::native_setup_search()\n" if ($self->{'_debug'});

	$self->{'agent_name'} = ref($self) . '/' . $WWW::Search::FirstGov::VERSION;
	$self->user_agent('non-robot');

	my $oTree = new HTML::TreeBuilder;
	$oTree->store_comments(1);  # comments are required to parse results page
	$self->{'_treebuilder'} = $oTree;

	$self->{'_next_to_retrieve'} = 0;

	$self->{'_num_hits'} = 0;

	if (! defined($self->{'_options'})) {
		foreach (keys %$default_option) {
			$self->{'_options'}{$_} = $default_option->{$_};
		}
		$self->{'_options'}{'mw0'} = $native_query;
	}
	if (defined($native_options_ref)) {
		foreach (keys %$native_options_ref) {
			$self->{'_options'}{$_} = $native_options_ref->{$_} if ($_ ne 'begin_at');
		}
	}
	# if user has set 'begin_at' option, then handle other options to get desired result
	if (exists($native_options_ref->{'begin_at'}) && defined($native_options_ref->{'begin_at'})) {
		my $begin_at = $native_options_ref->{'begin_at'} || 1;
		$begin_at = 1 if ($begin_at < 1);
		$self->{'_options'}{'offset'} = $begin_at - 1 - $self->{'_options'}{'nr'};
		$self->{'_options'}{'act.next.x'} = 1;
		$self->{'_options'}{'act.next.y'} = 1;
	}
	my $options = '';
	foreach (sort keys %{$self->{'_options'}}) {
		next if (generic_option($_));
		$options .= '&' if ($options);
		$options .= $_ . '=' . $self->{'_options'}{$_};
	}
	$self->{'_next_url'} = $self->{'_options'}{'search_url'} . '?' . $options;
}

sub parse_tree {
	my($self, $tree) = @_;

	print STDERR " + WWW::Search::FirstGov::parse_tree()\n" if ($self->{'_debug'});

	print STDERR " + (parse_tree) result HTML page tree:\n" if ($self->{'_debug'} > 1);
	$tree->dump( *STDERR ) if ($self->{'_debug'} > 1);

	return undef if (! defined($self->{'_prev_url'}));  # fast exit if already done

	# approximate_result_count
	my $result_count = undef;
	my @td = $tree->look_down('_tag', 'td');
	while (! defined($result_count) && (my $td = shift(@td))) {
		my $text = $td->as_text();
		if ($text =~ m{Your\s+(.*\s)?search\s+(for.*\s.*\s)?returned\s+(\d+)\s+results\.}is) {
			$result_count = $3;
		} elsif ($text =~ m{Your\s+(.*\s)?search\s+(for.*\s)?returned\s+more\s+than\s+(\d+)\s+(relevant\s+)results\.}is) {
			$result_count = $3 + 1;
		} elsif ($text =~ m{Your\s+(.*\s)?search\s+(for.*\s.*\s)?did\s+not\s+return\s+any\s+documents\.}is) {
			$result_count = 0;
		}
	}
	if (defined($result_count)) {
		$self->approximate_result_count($result_count);
	}
	print STDERR " + (parse_tree) approximate_result_count is " . $result_count . "\n" if ($self->{'_debug'});

	# SearchResults
	my $hits_found = 0;
	my $results_table_comment = $tree->look_down('_tag', '~comment', sub { $_[0]->attr('text') =~ m{Begin\s+display\s+of\s+search\s+results}si });
	return undef if (! defined($results_table_comment));  # exit if no results table comment
	my $results_table = $results_table_comment->right();  # locate table containing results
	return undef if (! defined($results_table));  # exit if no results table
	my @results_tds = $results_table->look_down('_tag', 'td');  # get array of all TDs within the table of results
	my %result = ();  # hash to contain one result
	foreach my $result_td (@results_tds) {
		next if ($result_td->as_text() =~ m{^(\s|\xA0)*$}s);  # ignore any white space (or &nbsp;) TDs
		print STDERR " + (parse_tree) result_td: " . $result_td->as_text() . "\n" if ($self->{'_debug'} > 1);
		if (! exists($result{'count'})) {  # count TD occurs first
			if ($result_td->as_text() =~ m{^\s*(\d+)\.?\s*$}s) {  # digit(s) with optional period
				$result{'count'} = $1;
			}  # else ignore this TD
		} elsif (! exists($result{'url'})) {  # url/title (anchor) TD occurs second
			if (my $result_a = $result_td->look_down('_tag', 'a')) {  # if TD contains A
				$result{'url'} = $result_a->attr('href');
				if ($result{'url'} =~ m{url=([^&]+)}i) {  # strip URL out of FirstGov.gov's redirect URL
					$result{'url'} = $1;
				}
				$result{'title'} = $result_a->as_text();
			}  # else ignore this TD
		} else {  # description TD occurs third
			my $hit = WWW::SearchResult->new();
			$hit->add_url($result{'url'});
			$hit->title($result{'title'});
			$hit->description(&WWW::Search::strip_tags($result_td->as_text()));
			push(@{$self->{cache}}, $hit);
			$self->{'_num_hits'} += 1;
			$hits_found += 1;
			%result = ();
		} # the URL TD occurs fourth and is ignored when looking for count TD
	}

	# _next_url
	my $a_href = undef;
	if ($tree->look_down('_tag', 'table', sub {
			defined($_[0]->look_down('_tag', 'font', sub {
				defined($a_href = $_[0]->look_down('_tag', 'a', sub {
					defined($_[0]->look_down('_tag', 'img', sub {
						$_[0]->attr('alt') =~ /next/i }))}))}))})) {
		$self->{'_next_url'} = $SEARCH_URL_PATH . $a_href->attr('href');
		print STDERR " + (parse_tree) _next_url is " . $self->{'_next_url'} . "\n" if ($self->{'_debug'});
	} else {
		print STDERR " + (parse_tree) _next_url is undefined\n" if ($self->{'_debug'});
	}

	print STDERR " + (parse_tree) hits_found: " . $hits_found . "\n" if ($self->{'_debug'});
	return $hits_found;
}

1;
