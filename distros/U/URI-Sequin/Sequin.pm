# Sequin v1.1.2
#
# by Peter Sergeant <cpan@clueball.com>
#
# A module for extracting and parsing search engine URLs from
# server referrer files. Proper usage information is in the
# README file 


# Magic Package Stuff
require 5.005;
use strict;
require Exporter;
package URI::Sequin;
use vars qw(@ISA $VERSION @EXPORT_OK %log_types);
@ISA = qw(Exporter);
@EXPORT_OK = qw(se_extract log_extract %log_types key_extract);
$VERSION = '1.2';



# &log_extract v1.0
# =-=-=-=-=-=- =-=-
#
# 
# The purpose of this subroutine is to allow raw log files lines to be
# handled. The subroutine accepts a log line, plus some information on
# how it should be analysed, and returns a scalar value: the referring
# URL.
#
# The subroutine knows a certain number of log types, and keeps regexs
# with which to handle these logs in a globally accessable hash below,
# called '%log_types'. If your log type is not already in the array it
# can be added and used.
#
# Examples:
# ---------
#
# Adding a new regex to %log_types:
# => $log_types{'MyWebServer'} = '.+? Referer:(.+?) ';
#
#	> It's worth pointing out that the subroutine uses $1 straight
#	> after the match has taken place to get the referrer. Because
#	> of this, you should make sure the part of string to be taken
#	> is enclosed in ()'s. If you're still unsure, this is clearly
#	> demonstrated below, where %log_types is set.
# 
# Parsing a Log Entry
# => $referrer = &log_extract($log_line, 'NCSA');
#
#	> As I hope is clear, $log_line is the log-file line that needs
#	> to be parsed, and 'Apache' refers to the relevant regex below
#	> in the %log_types hash.
#

%log_types = (
	# Microsoft IIS 3.0 and 2.0
	'IIS1'		=>	'(http:.+?),',

	# Microsoft IIS4.0 (W3SVC format)
	'IIS2'		=>	'(http:.+?)$',

	# NCSA (Apache, Netscape)
	'NCSA'		=>	'"(http:.+?)"',

	# O'Reilly WebSite format
	'ORW'		=>	' (http:.+?) ',

	# General (works for most logtypes)
	'General'	=>	'(?:\s|"|,|^)(http:.+?)(\s|"|,|$)',
	
);



sub log_extract {

	my $log_file_line	=	$_[0];
	my $log_file_type	=	$_[1] || 'General';

	chomp($log_file_line);

	# Check that the $log_file_type contains a valid regex by using
	# (eval) on it to see if we crash the regex engine, and by also
	# checking if there is a regex in $log_types{$log_file_type}

	my $re = eval { qr/$log_types{$log_file_type}/ };
	warn "Bad re: '$log_types{$log_file_type}' ($@)\n" if $@;

	unless (defined $log_types{$log_file_type}) {
		warn "Unknown Logtype - \"$log_file_type\"\n";
	}
	
		
	# Return what we found

	if ($log_file_line =~ m/$log_types{$log_file_type}/i) { return $1 };

	return;

}



# &se_extract v1.1
# =-=-=-=-=-= =-=-
#
# The purpose of this subroutine is to break down the referring URL in
# to an array, containing the $search_engine_name and the
# $search_engine_url.
#
# Example:
# => ($name, $url) = @{&se_extract($url)};
#

sub se_extract {

	my $input_url = $_[0];
	chomp($input_url);

	# Break down the $input_url into two more useful variables, so
	# that we can check if there is information in the query
	# string, and if there is, we just get on with life.

	my ($location, $query_string) = split(/\?/, $input_url);
	return [] unless $query_string;

	my $search_engine_name;
	my $search_engine_url;

	# This is a scary regex. It picks out with suprising accuracy
	# the main part of a URL - the 'MSN' part of:
	# http://biteme15.search.cgi.msn.com.uk/?asdfasdf

	if ($location =~ m!(http://)?(\d+\.\d+\.\d+\.\d+(\:\d+)?)/!) {
		return ["Unknown (IP)", $2];
	}

	if ($location =~ m!^(.+?\.
				([^\.]+)
				\.
				(com|net|org|int|mil|\w\w|
					(gov|mil|com|net|org|\w\w)\.\w\w
				)
				(?:/|:\d+/)
			  )!x) {
		$search_engine_url	= $1;
	 	$search_engine_name	= "\u$2";

	} elsif ($location =~ m!^(http://)?((\w+)\.\w+(\:\d+/?)?)!) {
  		$search_engine_url	= $2;
		$search_engine_name	= "\u$3";
	} elsif ($location =~ m!^(http://)?((\w+)([^\.\w:]|(\:\d+/?)?))!) {
	  	$search_engine_url 	= $2;
	        $search_engine_name	= "\u$3";
	}


	# This has allowed us to quite accurately get the name and URL
	# of any given search-engine. However, in the interests of
	# total accuracy, we have a list of search-engines that we know
	# so we can provide even more information, and make sure it's
	# correct.

	# Define this list:

	my @search_engine_array = (
		['Altavista',	'http://www.av.com',
			'(altavista|av)'],
		['HotBot',	'http://www.hotbot.com',
			'hotbot\.lycos'],
		['Infoseek',	'http://www.infoseek.com',
			'infoseek\.go'],
		['Magellan',	'http://magellan.excite.com',
			'magellan\.excite'],
		['Ask Jeeves',	'http://www.aj.com',
			'(aj|askjeeves)'],
		['CNET Search',	'http://www.search.com',
			'(cnet|search\.com|savysearch)'],
	);

	# Cycle through the list

	for (@search_engine_array) {

		my ($se_name, $se_url, $se_regex) = @{$_};

		if ($location =~ m/$se_regex/) {
			$search_engine_url = $se_url;
			$search_engine_name = $se_name;
		}

	}

	# Return what we know.
	# jm: allow HTTPS search engines too ;)

	if (defined $search_engine_url && $search_engine_url !~ m!^https?://!) {
		$search_engine_url =~ s!^!http://!;
	}

	return [$search_engine_name, $search_engine_url];

}


# &key_extract v1.1
# =-=-=-=-=-= =-=-
#
# The purpose of this subroutine is to break down the referring URL in
# to a string containing the search terms.
#
# Example:
# => $terms = &key_extract($url);
#

sub key_extract {

	my $input_url = $_[0];

	chomp($input_url);

	# Break down the $input_url in to two more useful variables

	my ($location, $query_string) = split(/\?/, $input_url);
	return unless $query_string;

	# Google Caching ... What a bitch... This will deal with it,
	# how Google currently works...
	
	if ($query_string =~ m!q=cache\:.+/(.+?)&!i) {
		$_ = $1;
		tr/+/ /;
		s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
		s/\s+/ /gs;
		s/^\s+//g;
		s/\s+$//g;
		return $_;
	}
	
	# There are a number of ways in which we now try and determine
	# what the search terms are. The first is quite clever, IMHO.
	# We search for spaces in any of the submitted fields that
	# isn't called 'next' or 'submit' or 'col' or 'btnG' (blame
	# google).

	

	if ($query_string =~ m/(?<!next)(?<!col)(?<!btnG)(?<!submit)
				(?<!rfr)(?<!WILDCARD)(?<!METAENGINE)=
				([^&]*(?:\+|%2b)[^&]*)/xi) {

		
		my $key_string = $1;
		my $false = 0;

		# Some search engines are determined to try and fool us
		# :). Therefore, we kill some pseudo-matches containing
		# %07C ( a pipe: | ) and %02C, by setting the $false
		# scalar to a positive value, that overides a little
		# later on.

		$false++ if $key_string =~ m/(%02|%7C%7C)/;

		# Clean our information from those nasty escape
		# sequences.

		for ($key_string) {
			tr/+/ /;
			s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
			s/\s+/ /gs;
		}

		# Unless we decided to abort earlier, return the
		# field that we found.

		return $key_string unless ($false);

	}

	# Okay. If that failed, then we need to take a closer look.
	# In the array below are many many possible prefixes for a term
	# that might contain our data. They're in a particular order
	# because some search engines use two of the variables.

	# NB: This isn't quite finished. If you're finding that the
	#     wrong prefix is being used, please email me and tell me
	#     at pete_sergeant@hotmail.com

	# If you're wondering why they're ordered in this slightly 
	# bizarre and seemingly random order, it's because some 
	# search engines have decided to use more than one of these
	# variables, and the order these are in hopefully pick the
	# right one first.

	my @prefix_array = (

		
		'\w*query\w*',   # CNET Search, Netscape
		'\w*search(?!Type)\w*',
		'\w*term\w*',
		'ask',             # Ask Jeeves
		'.\w?key.\w?',
		'palabras',
		'DTqb1',
		'request',
		'ShowMatch',    # syndic8
		'keywords?',  # Snap, overture.com
		'general',  # MetaCrawler, Go2Net
		'key',      # Looksmart
    'MetaTopic', # AJ
		'query0', # elf8888.at, thx to http://www.tnl.net/
		'queryString', # blogdigger.com
		'serachfor', # mysearch.com dyslexia ;)
	  'terms', # abcsearch.com
	  'word', # baidu.com
    'rn',
		'mt',  # MSN, HotBot
		'qt',  # Go, Infoseek, search.com
		'oq',
		'dom', # Domainsurfer
	  's',   # Excite, blogsphere.us
		'q',   # Altavista, Google, Dogpile, Evreka, Metafind
		'p',   # Yahoo
		't',
		'qry',
		'qkw', # dpxml, msxml
		'qr',  # northernlight.com
		'qu',
		'kw',  # Sapo
		'general',
		'B1',
		'sc',  # Gohip
		'szukaj',
		'PA',
		'MT',  # goo.ne.jp
		'req', # dir.com
		'k',   # galaxy.com
	  'cat', # Dmoz
		'u',   # Google translation
		'va',  # search.yahoo.com
		'K',   # srd.yahoo.com
		'as_epq' # Google, sometimes. Advanced query maybe?

	);

	# Cycle through each prefix and see if it's contained in the
	# query_string. If it is, we extract the field, clean it, and
	# return it. Simple.


	for (@prefix_array) {
		if ($query_string =~ m/(^|\&)$_=(.+?)(\&|$)/i) {

			my $key_string = $2;

			for ($key_string) {
				tr/+/ /;
				s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
				s/\s+/ /gs;
			}

			if ($key_string =~ /\w/) {
				return $key_string;
			}

		}

	}

	# Failing all that, some Search-Engines don't overload the
	# query_string with values, and just make the query_string
	# the search terms. The next part looks for that, and returns
	# the whole query_string (cleaned) if this appears to be the
	# case.


	if ($query_string !~ /\=/) {

		for ($query_string) {
			tr/+/ /;
			s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
			s/\s+/ /gs;
		}

		return $query_string;
	}


	return;
}

1;

__END__

=head1 NAME

URI::Sequin - Extract information from the URLs of Search-Engines

=head1 SYNOPSIS


	use URI::Sequin qw/se_extract key_extract log_extract %log_types/;

	$url = &log_extract($line_from_log_file, 'NCSA');

	$log_types{'MyLogType'} = '^(.+?) -> .+$';
	$url = &log_extract($line_from_log_file, 'MyLogType');

	$keyword_string = &key_extract($url);

	($search_engine_name, $search_engine_url) = @{&se_extract($url)};


=head1 DESCRIPTION

This module provides three tools to aid people trying to analyse
Search-Engine URLs. It’s meant mainly for those who want to analyse
referrer logs and pick out key information about site visitors, such as
which Search-Engine and keywords they used to find the site.

The functions and globals provided (and exported by default) from this
module are:

=over

=item log_extract($log_line, 'Type')

This will pick out the referring URL from a line of a logfile. The 'type' can
be one of the built in types or can be a user-created one. For more
information, see %log_types below. This subroutine accepts a scalar, and
returns a scalar.

=item key_extract($url)

This will try and determine the keywords used in $url. It accepts a scalar
and returns a scalar. Should nothing be found, it returns an undefined value.

=item se_extract($url)

This will try and determine the name of the Search-Engine used and its URL.
It accepts a scalar, and returns an array containing firstly the Search-
Engine’s name and secondly the Search-Engine’s URL. Should the URL appear not
to be from a Search Query, it returns a reference to an empty array.

=item %log_types

There are five built-in logfile types already in this hash. They are:

=over 4

=item * IIS1 - Microsoft IIS 3.0 and 2.0

=item * IIS2 - Microsoft IIS4.0 (W3SVC format)

=item * NCSA - For APACHE, NETSCAPE and any other NCSA format logs

=item * ORW - O'Reilly WebSite format

=item * General - A generalised one that will work with most logfiles

=back

It’s easy to add another one. Simply add a key to the hash, with a value that
is a regex. Parenthesise the part that is the referring URL, as the script
uses $1 to obtain the URL. (see the example in the Synopsis section).

I have only one request for people who use this module. *Please* tell me where
and how you've used it, and if you have any thoughts or suggestions on it, tell
me!

=back

=head1 BUGS

Doesn't like the Amnesi Search Engine. But then, neither do I. Also,
the 'General' log type needs to be used with discretion ... be sure
that none of the URLs contain literal " if you use it.

=head1 AUTHOR

Peter Sergeant E<lt>pete@grou.chE<gt>

=head1 COPYRIGHT

Copyright 2001 Peter Sergeant.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
