package WWW::Search::TheITJobBoard;

use strict;
use warnings;

our $VERSION = '0.04';
our $DEBUG   = 0;
our $MAINTAINER = 'Lee Goddard <lgoddard -at- cpan -dot- org';

our $WIN = ($^O =~ /win\d/ig); # For the Win32 bug

use base 'WWW::Search';
use WWW::SearchResult;
use HTML::TokeParser;

=head1 NAME

WWW::Search::TheITJobBoard - Search TheITJobBoard.com

=cut

=head1 SYNOPSIS

	use WWW::Search::TheITJobBoard;
	use Data::Dumper;
	my $oSearch = WWW::Search->new('TheITJobBoard', _debug => undef);
	$oSearch->native_query(
		WWW::Search::escape_query("perl"),
		jobtype => WWW::Search::TheITJobBoard::CONTRACT,
	);
	while (my $oResult = $oSearch->next_result){
		warn Dumper $oResultr;
	}


=head1 DEPENDENCIES

L<WWW::Search>, L<HTML::TokeParser>.

=head1 DESCRIPTION

Gets jobs from the UK IT job site, I<The IT Job Board>.

A sub-class of L<WWW::Search> that uses L<HTML::TokeParser> to return C<WWW::SearchResult> objects
for each result found when querying C<www.theitjobboard.com>.

One frustrating aspect of I<The IT Jobboard> is that, unlike I<JobServe> (L<WWW::Search::Jobserve)>,
it doesn't provide an option to list jobs with full descriptions. So this module offers the ability
to create such a list: provide the constructor parameter C<detailed>, with a value of C<html> or C<text>
to get details as HTML or plain text. This will extend the C<WWW::SearchResult> objects' C<description> field,
and also add a C<details> key, which is itself a hash with interesting keys such as C<location> and C<salary>
- those keys come directly from the HTML page, so YMMV.

At the time of writing, valid options for The IT Job Board search are as below. These should be passed
to C<native_query>, as shown in the example.

=over 4

=item keywords

THe keywords your target job description should contain. Default is C<perl>, of course.

=item jobtype

Valid values are: C<1> for contract (our default), C<2> for permenant, and C<0> for either
You may use constants: C<WWW::Search::TheITJobBoard::CONTRACT>, C<WWW::Search::TheITJobBoard::PERM>,
C<WWW::Search::TheITJobBoard::ANY>.

=cut

use constant ANY  		=> 0;
use constant CONTRACT	=> 1;
use constant PERM 		=> 2;

=item days

The age of the posting, in days, according to the site's records. A value of C<0> represents any age.
Our default is C<1>.

=item orderby

Not especially relevant for us: valid values are C<1> to order by relevance to the keywords;
C<2> to order by date posted; C<3> orders by salary; C<4> puts non-agency jobs first, which is the default.
You may use constants: C<WWW::Search::TheITJobBoard::RELEVANCE>, C<WWW::Search::TheITJobBoard::DATE>,
C<WWW::Search::TheITJobBoard::SALARY>, C<WWW::Search::TheITJobBoard::NONAGENCY>

=cut

use constant RELEVANCE	=> 1;
use constant DATE		=> 2;
use constant SALARY		=> 3;
use constant NONAGENCY	=> 4;


=item locations[]

This ugly-named entity limits the search by location.
The default is to return all jobs, regardless. Valid values are:
C<undef> to return all jobs;
C<180> for UK, C<124> for Netherlands, C<93> for Germany, C<69> for France,
C<308> for Switzerland, C<170> for Republic Of Ireland, C<3> for Austria, C<301> for 'the rest Of the world,'
C<254> for 'other European.'

You may supply C<location> instead of C<location[]>, but you will still have to access the value you set via the latter.

=item currpage

The number of the page to start at, indexed from C<1>.

=item lang

Defaults to C<en> for English, but you could try other two-letter ISO codes.

=back

=cut

# "native_setup_search()" is invoked before the search. It is passed a
# single argument: the escaped, native version of the query.
# http://www.theitjobboard.com/index.php?keywords=HTML&locations%5B%5D=&jobtype=1&days=2&orderby=3&submit=Search&task=JobSearch&xc=0&lang=en
# Blx, it takes opts too


sub native_query {
	my ($self, $native_query, $opts) = (shift, shift, ref($_[0])? shift : {@_});
	return $self->SUPER::native_query( $native_query, $opts);
}

# =head2 METHOD native_setup_search
#
# Sets up default search parameters. B<NOTE> that the first argument is the same as the option C<keywords: see
# L<DESCRIPTION>, above. Unlike other modules in this namespace, you may provide options, after the query,
# as either a reference to a hash, or as a list.
#
# =cut

sub native_setup_search {
	my ($self, $native_query, $opts) = (shift, shift, ref($_[0])? shift : {@_});
	$self->user_agent('non-robot');
	$self->{_hits_per_page} 			= 100;
	$self->{_next_to_retrieve} 			= 1;
	$self->{search_base_url} 			||= 'http://www.theitjobboard.com';
	$self->{search_base_path} 			||= '/index.php';
	$self->{search_url}					||= $self->{search_base_url} . $self->{search_base_path};
	$self->{_options}->{keywords}		||= $native_query || 'PERL';
	$self->{_options}->{task}			||= 'JobSearch';
	$self->{_options}->{xc}				||= '0';
	$self->{_options}->{lang}			||= 'en';
	if ($self->{_options}->{locations}){
		$self->{_options}->{'locations[]'} = $self->{_options}->{locations};
		delete $self->{_options}->{locations};
	}
	$self->{_options}->{'locations[]'}	||= undef;  # 180=UK
	$self->{_options}->{jobtype}		||= '1';    # 0=any, 1=contract, 2=perm
	$self->{_options}->{days}			||= '1';	# 0=all, otherwise literal
	$self->{_options}->{orderby}		||= '4';	# 1=relevance, 2=date posted, 3=salary, 4=non-agency
	$self->{_options}->{currpage}		||= 1;		# Current page of results
	$self->{_debug}						||= $DEBUG;
	if ($opts){
		foreach my $i (keys %$opts){
			$self->{_options}->{$i} = $opts->{$i};
		}
	}
	$self->{_next_url} = $self->{search_url} .'?' . $self->hash_to_cgi_string($self->{_options});
}




=head2 METHOD native_retrieve_some

Retrieve some results. Returns the number of results found. Will make as many HTTP requests
as necessary to get to the maximum results you specify.

=cut

# After WWW::Search::Yahoo::Advanced

sub native_retrieve_some { my $self = shift;
	$self->{state} = WWW::Search::SEARCH_BEFORE;
	$self->{number_retrieved} ||= 0;
	$self->{_done_uris} = {};

	# printf STDERR (" +   %s::native_retrieve_some()\n", __PACKAGE__) if $self->{_debug};

	# Initially _next_url is preset; we then undef it and try to get it from the HTML returned by the query:
	HTTP_REQUEST:
	while (defined $self->{_next_url} and not exists $self->{_done_uris}->{$self->{_next_url}}){ # fast exit if already done

		# If this is not the first page of results, sleep so as to not overload the server:
		$self->user_agent_delay if 1 < $self->{_next_to_retrieve};

		$self->{state} = WWW::Search::SEARCH_RETRIEVING;

		# Get one page of results:
		print STDERR " +   submitting URL (", $self->{_next_url}, ")\n" if $self->{_debug};
		$self->{response} = $self->http_request($self->http_method, $self->{_next_url});
		print STDERR " +     got response\n", $self->{response}->headers->as_string, "\n" if 2 <= $self->{_debug};
		$self->{_prev_url} = $self->{_next_url};
		$self->{_done_uris}->{$self->{_next_url}} ++;
		$self->{state} = WWW::Search::SEARCH_UNDERWAY;

		# Assume there are no more results, unless we find out otherwise when we parse the html:
		$self->{_next_url} = undef;
		print STDERR " --- HTTP response is:\n", $self->{response}->as_string if 4 < $self->{_debug};
		if (! $self->{response}->is_success) {
			if ($self->{_debug}) {
				print STDERR " --- HTTP request failed, response is:\n", $self->{response}->as_string;
			}
			return undef;
		}

		my $html = $self->{response}->content;

		# Parse the output:
		# No matches:
		if ($html =~ /There are no vacancies matching your search criteria/g){
			if ($self->{_debug}) {
				print STDERR " --- search failed: there are no vacancies matching your search criteria";
			}
			return undef;
		}

		$self->{_parser} = HTML::TokeParser->new(\$html);
		# Nice ppl they are, they provide a <div id="results"> containing lots of <div class="jobdet">
		# so loop over div class jobdet:
		PARSE_PAGE:
		while (my $token = $self->{_parser}->get_tag("div")) {
			# A 'div' with a 'class' attribute:
			if ($token->[1] and defined $token->[1]->{class}){
				# Found a job description:
				use Data::Dumper; die Dumper $token if not $token->[1]->{class};
				if ($token->[1]->{class} eq 'jobdet'){
					my $xtoken_a = $self->{_parser}->get_tag("a");
					if (not $xtoken_a){
						print STDERR " --- unexpected result format (code 'a'): please inform author";
						return undef;
					}
					my $title = $self->{_parser}->get_trimmed_text("/a");
					if (not $title){
						print STDERR " --- unexpected result format (code '/a'): please inform author";
						return undef;
					}
					my $token_br = $self->{_parser}->get_tag("br");
					if (not $token_br){
						print STDERR " --- unexpected result format (code 'br'): please inform author";
						return undef;
					}
					my $all = $self->{_parser}->get_trimmed_text("/p");
					if (not $token_br){
						print STDERR " --- unexpected result format (code '/p'): please inform author";
						return undef;
					}
					my ($last_posted) = $all =~ /LAST POSTED: (\d{2}\/\d{2}\/\d{4} \d{2}:\d{2}:\d{2})/g;
					my $hit = WWW::SearchResult->new;
					$hit->add_url(
						($xtoken_a->[1]->{href} =~ /^\//? $self->{search_base_url} : '')
						. $xtoken_a->[1]->{href}
					);
					$hit->title( $title );
					$hit->description( $all );
					$hit->change_date( $last_posted );

					# Get the details, if user desires:
					if ($self->{detailed}){
						$hit->{details} = {} if not exists $hit->{details};
						my $response = $self->http_request('GET', $hit->url);
						print STDERR " +     got response for detail\n", $response->headers->as_string, "\n" if 2 <= $self->{_debug};
						print STDERR " --- HTTP response for detail is:\n", $response->as_string if 4 < $self->{_debug};
						if (! $response->is_success) {
							if ($self->{_debug}) {
								print STDERR " --- HTTP request for detail failed, response is:\n", $response->as_string;
							}
							return undef;
						}
						my $p = HTML::TokeParser->new(\$response->content);
						# Get to the div id "jobdescription"
						while (my $xtoken = $p->get_tag("div")){
							last if $xtoken->[1]->{id} and $xtoken->[1]->{id} eq 'jobdescription';
						}
						# Just get text?
						if (lc $self->{detailed} ne 'html'){
							$hit->{description} = $p->get_trimmed_text('/div')
						} else {
							$hit->{description} = '';
							while ($token = $p->get_token){ # reuse $token
								if ($token->[0] eq 'S'){
									$hit->{description} .= $token->[4];
								}
								elsif ($token->[0] eq 'S'){
									$hit->{description} .= $token->[2];
								}
								elsif ($token->[0] eq 'T'){
									$hit->{description} .= $token->[2];
								}
							}
						}
						# Get to the table after the div/id=jobparticulars and div/id=jobs
						while (my $xtoken = $p->get_tag("div")){
							last if $xtoken->[1]->{id} and $xtoken->[1]->{id} eq 'jobs';
						}
						$p->get_tag("table");
						# use the table labels as hash keys - naughty...but nice!
						my $key;
						while (my $xtoken = $p->get_token){
							last if $xtoken->[0] eq 'E' and $xtoken->[1] eq 'table';
							next if $xtoken->[0] ne 'S' or $xtoken->[1] ne'td';
							# Set the key
							if (exists $xtoken->[2]->{class} and $xtoken->[2]->{class} eq 'jobslabel'){
								$key = $p->get_trimmed_text('/td');
								$key =~ s/\s+/_/sg;
								$key =~ s/[^\w\d_]+//sg;
								$key = lc $key;
							}
							# Set the value
							elsif ($key) {
								$hit->{details}->{$key} = $p->get_trimmed_text('/td');
								undef $key;
							}
						} # Next token of details' table

					} # End getting details

					push @{$self->{cache}}, $hit;
					$self->{_num_hits} ++;
				} # End found job

			} # End found div/class

			# Links to more results
			elsif ($token->[1]->{id} and $token->[1]->{id} eq 'prevnextpage'){
				while (my $xtoken_a = $self->{_parser}->get_tag("a")){
					next unless $xtoken_a->[1]->{title} and $xtoken_a->[1]->{title} eq 'Next';
					if ($WIN){
						# Weird bug in the latest (3.19) HTML::Parser.ppm TokeParser binary from AS
						# So have to do this:
						($xtoken_a->[1]->{href}) = $xtoken_a->[3] =~ /href=([^\s>]+)/;
						($xtoken_a->[1]->{href}) = $xtoken_a->[1]->{href} =~ /^.(.*).$/;
					}
					my $uri = ($xtoken_a->[1]->{href} =~ /^\//? $self->{search_base_url} : '') . $xtoken_a->[1]->{href};
					# IF we've not done it:
					if (not exists $self->{_done_uris}->{$uri}){
						$self->{_next_url} = $uri;
						print STDERR " + next URI: ".$self->{_next_uri} if $self->{_debug};
						last PARSE_PAGE;
					}
					# else { it's the end of the result set }
				}
			} # End found more results

		} # Next PARSE_PAGE

		$self->{_options}->{currpage} ++;

		last HTTP_REQUEST if $self->{number_retrieved} + $self->{_num_hits} >= $self->{maximum_to_retrieve};
	} # Next HTTP_REQUEST

	$self->{state} = WWW::Search::SEARCH_DONE;
	return $self->{_num_hits};
}



1;

__END__

=head1 BUGS

Posibly. Please use rt.cpan.org to report them.

=head1 SEE ALSO

This module was composed after reading L<WWW::Search>, L<WWW::Search::Yahoo>, L<WWW::Search::Yahoo::Advanced>
and L<WWW::Search::Jobserve>. If this module is useful to you, check out the latter too.

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 2006. Some Rights Reserved.

=head1 LICENCE

This work is licensed under a I<Creative Commons Attribution-NonCommercial-ShareAlike 2.0 England and Wales License>:
L<http://creativecommons.org/licenses/by-nc-sa/2.0/uk|http://creativecommons.org/licenses/by-nc-sa/2.0/uk>.

=for html

<!--Creative Commons License--><a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/2.0/uk/"><img alt="Creative Commons License" border="0" src="http://creativecommons.org/images/public/somerights20.png"/></a>
<br/>This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/2.0/uk/">Creative Commons Attribution-NonCommercial-ShareAlike 2.0 England &amp; Wales License</a>.
<!--/Creative Commons License-->

=end html

=for xml

<!-- <rdf:RDF xmlns="http://web.resource.org/cc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
	<Work rdf:about="">
	<license rdf:resource="http://creativecommons.org/licenses/by-nc-sa/2.0/uk/" />
	<dc:title>WWW::Search::TheITJobBoard</dc:title>
	<dc:date>2006</dc:date>
	<dc:creator><Agent><dc:title>Lee Goddard</dc:title></Agent></dc:creator>
	<dc:rights><Agent><dc:title>Lee Goddard</dc:title></Agent></dc:rights>
	<dc:type rdf:resource="http://purl.org/dc/dcmitype/InteractiveResource" />
		</Work>
		<License rdf:about="http://creativecommons.org/licenses/by-nc-sa/2.0/uk/"><permits rdf:resource="http://web.resource.org/cc/Reproduction"/><permits rdf:resource="http://web.resource.org/cc/Distribution"/>
		<requires rdf:resource="http://web.resource.org/cc/Notice"/>
		<requires rdf:resource="http://web.resource.org/cc/Attribution"/>
		<prohibits rdf:resource="http://web.resource.org/cc/CommercialUse"/>
		<permits rdf:resource="http://web.resource.org/cc/DerivativeWorks"/>
		<requires rdf:resource="http://web.resource.org/cc/ShareAlike"/></License>
	</rdf:RDF>
-->

=end xml



=cut



