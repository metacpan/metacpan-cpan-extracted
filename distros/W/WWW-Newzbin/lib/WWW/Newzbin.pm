package WWW::Newzbin;

use 5.005;
use strict;
use warnings;

use Carp qw(carp croak);
use WWW::Newzbin::Constants qw(:all);

use LWP::UserAgent;

our $VERSION = '0.07';

# lwp::useragent object for communicating with newzbin
my $ua = LWP::UserAgent->new(
	agent => "WWW::Newzbin/$VERSION"
);

#=============================================================================#

# internal carp() - gives us a chance to stop them if user has requested no warnings
sub _carp {
	my $self = shift;
	my $err = shift;
	
	carp("WARNING: WWW::Newzbin " . $err) unless $self->{param}->{nowarnings};
}

sub _croak {
	my $self = shift;
	my $err = shift;
	
	croak("ERROR: WWW::Newzbin " . $err);
}

sub new {
	my $class = shift;
	my $self = {};

	bless($self, $class);

	if (my $err = $self->_init(@_)) {
		$self->_croak("new(): Cannot initialise object: $err");
		return undef;
	} else {
		return $self;
	}
}

sub _init {
	my $self = shift;
	
	(%{$self->{param}}) = @_;
	
	# dismiss unrecognised constructor parameters
	foreach my $param (keys %{$self->{param}}) {
		if ($param !~ /^(username|password|nowarnings|proxy)$/) {
			$self->_carp("new(): Unknown constructor parameter '$param'");
			delete $self->{param}->{"$param"};
		}
	}
	
	# check for existence of required parameters
	foreach my $required (qw(username password)) {
		if (!$self->{param}->{"$required"}) {
			return "missing required parameter '$required'";
		}
	}

	# if a proxy has been specified, pass it to lwp::useragent
	if (exists $self->{param}->{proxy}) {
		eval { $ua->proxy("http", $self->{param}->{proxy}); };
		if ($@) {
			$self->_carp("new(): Cannot use proxy '$self->{param}->{proxy}'");
			delete $self->{param}->{proxy};
		}
	}
}

sub _set_error {
	my $self = shift;
	$self->{error}->{code} = shift;
	$self->{error}->{message} = shift;
}

sub error_code {
	my $self = shift;
	return $self->{error}->{code} || undef;
}

sub error_message {
	my $self = shift;
	return $self->{error}->{message} || undef;
}

sub lwp_useragent {
	my $self = shift;
	return $ua;
}

#-----------------------------------------------------------------------------#

# interface to v3's filefind api
sub search_files {
	my $self = shift;
	$self->_set_error(undef, undef);
	$self->_set_search_files_total(undef);
	
	my (%criteria) = @_;
	
	# check for unrecognised parameters
	foreach my $key (keys %criteria) {
		if ($key !~ /^(query|category|group|retention|minsize|maxsize|filetype|resultoffset|resultlimit|sortfield|sortorder)$/) {
			$self->_carp("search_files(): Unknown parameter '$key'");
			delete $criteria{"$key"};
		}
	}
	
	# check for required parameters
	foreach my $req (qw(query)) {
		if (!$criteria{"$req"}) {
			$self->_croak("search_files(): Missing required parameter '$req'");
		}
	}

	# build post request for filefind
	my %post = (
		username => $self->{param}->{username},
		password => $self->{param}->{password},
		query => $criteria{query},
		filetype => $criteria{filetype},
	);

	# validation for "category"
	if (exists $criteria{category}) {
		if (ref($criteria{category}) =~ /^ARRAY/) {
			$post{category} = join(",", @{$criteria{category}});
		} elsif (!ref($criteria{category})) {
			$post{category} = $criteria{category};
		} else {
			$self->_carp("search_files(): 'category' parameter must be a string or arrayref of strings; parameter not included in search");
		}
	}

	# validation for "group"
	if (exists $criteria{group}) {
		if (ref($criteria{group}) =~ /^ARRAY/) {
			$post{group} = join(",", @{$criteria{group}});
		} elsif (!ref($criteria{group})) {
			$post{group} = $criteria{group};
		} else {
			$self->_carp("search_files(): 'group' parameter must be a string or arrayref of strings; parameter not included in search");
		}
	}

	# validation for "retention"
	if (exists $criteria{retention}) {
		if (($criteria{retention} =~ /^\d+$/) && ($criteria{retention} > 0)) {
			$post{retention} = $criteria{retention};
		} else {
			$self->_carp("search_files(): 'retention' parameter must be a positive integer; parameter not included in search");
		}
	}

	# validation for "minsize"
	if (exists $criteria{minsize}) {
		if (($criteria{minsize} =~ /\D/) || ($criteria{minsize} < 0)) {
			$self->_carp("search_files(): 'minsize' parameter must be a positive integer; parameter not included in search");
			delete $criteria{minsize};
		} elsif ((exists $criteria{maxsize}) && ($criteria{minsize} > $criteria{maxsize})) {
			$self->_carp("search_files(): 'minsize' parameter must be less than 'maxsize' parameter; both parameters not included in search");
			delete $criteria{minsize};
			delete $criteria{maxsize};
		} else {
			$post{bytesmin} = $criteria{minsize};
		}
	}
	
	# validation for "maxsize"
	if (exists $criteria{maxsize}) {
		if (($criteria{maxsize} =~ /\D/) || ($criteria{maxsize} < 0)) {
			$self->_carp("search_files(): 'maxsize' parameter must be a positive integer; parameter not included in search");
			delete $criteria{maxsize};
		} elsif ((exists $criteria{minsize}) && ($criteria{minsize} > $criteria{maxsize})) {
			$self->_carp("search_files(): 'minsize' parameter must be less than 'maxsize' parameter; both parameters not included in search");
			delete $criteria{minsize};
			delete $criteria{maxsize};
		} else {
			$post{bytesmax} = $criteria{maxsize};
		}
	}

	# validation for "resultoffset"
	if (exists $criteria{resultoffset}) {
		if (($criteria{resultoffset} =~ /\D/) || ($criteria{resultoffset} < -1)) {
			$self->_carp("search_files(): 'resultoffset' parameter must be an integer >= 0; offset/limit parameters not included in search");
			delete $criteria{resultlimit};
		} else {
			$post{offset} = $criteria{resultoffset};
		}
	}

	# validation for "resultlimit"
	if (exists $criteria{resultlimit}) {
		if (($criteria{resultlimit} =~ /\D/) || ($criteria{resultlimit} < 0)) {
			$self->_carp("search_files(): 'resultlimit' parameter must be a positive integer; offset/limit parameters not included in search");
			delete $post{offset};
		} else {
			$post{limit} = $criteria{resultlimit};
		}
	}

	# validation for "sortfield"
	if (exists $criteria{sortfield}) {
		if (
			($criteria{sortfield} ne NEWZBIN_SORTFIELD_DATE) &&
			($criteria{sortfield} ne NEWZBIN_SORTFIELD_SUBJECT) &&
			($criteria{sortfield} ne NEWZBIN_SORTFIELD_FILESIZE)
		) {
			$self->_carp("search_files(): 'sortfield' parameter does not have an allowed value; sort parameters not included in search");
			delete $criteria{sortorder};
		} else {
			$post{sortfield} = $criteria{sortfield};
		}
	}

	# validation for "sortorder"
	if (exists $criteria{sortorder}) {
		if (
			($criteria{sortorder} ne NEWZBIN_SORTORDER_ASC) &&
			($criteria{sortorder} ne NEWZBIN_SORTORDER_DESC)
		) {
			$self->_carp("search_files(): 'sortorder' parameter does not have an allowed value; sort parameters not included in search");
			delete $post{sortfield};
		} else {
			$post{sortorder} = $criteria{sortorder};
		}
	}

	# now we're ready to query newzbin
	my $response = $ua->post(
		"http://v3.newzbin.com/api/filefind3/",
		\%post,
		"Content-type" => "application/x-www-form-urlencoded"
	) or $self->_set_error(-1, "Could not send HTTP POST request to Newzbin's FileFind API") and return undef;
	
	# check for valid response
	if (!$response->is_success) {
		if ($response->code == 500) {
			$self->_set_error(-1, "Newzbin's FileFind API is currently unavailable");
		} elsif ($response->code == 403) {
			$self->_set_error(-2, "Invalid Newzbin login credentials given");
		} elsif ($response->code == 402) {
			$self->_set_error(-3, "This is not a Newzbin Premium account");
		} else {
			$self->_set_error(-1, "Invalid response from Newzbin's FileFind API");
		}
		
		return undef;
	}
	
	# were there results for the given query?
	if ($response->code == 204) {
		$self->_set_error(-4, "No search results found");
		return undef;
	}
	
	# process results
	my @raw_results = split(/\n/, $response->content);

	# first line holds the total number of results that would have been returned if offset/limit were not present
	my $total_results = shift(@raw_results);
	$total_results =~ s/^TOTAL=//i;
	$self->_set_search_files_total($total_results);

	my @results;
	foreach (@raw_results) {
		my @result = split(/\t/, $_);

		push(@results, {
			fileid => $result[0],
			subject => $result[1],
			posttime => $result[2],
			filesize => $result[3],
			author => $result[4],
			groups => [ split(/,/, $result[5]) ],
		});
	}

	return @results;
}

sub _set_search_files_total {
	my $self = shift;
	$self->{searchfiles}->{total} = shift;
}

sub search_files_total {
	my $self = shift;
	return $self->{searchfiles}->{total} || undef;
}

#-----------------------------------------------------------------------------#

# interface to v3's directnzb api
sub get_nzb {
	my $self = shift;
	$self->_set_error(undef, undef);
	
	my (%request) = @_;
	
	# check for unrecognised parameters
	foreach my $key (keys %request) {
		if ($key !~ /^(reportid|fileid|nogzip|leavegzipped)$/) {
			$self->_carp("get_nzb(): Unknown parameter '$key'");
			delete $request{"$key"};
		}
	}
	
	# can only specify either reportid or fileid, not both...
	if ((exists $request{reportid}) && (exists $request{fileid})) {
		$self->_croak("get_nzb(): 'reportid' and 'fileid' cannot both be passed as parameters");
	# ...but still must supply one of them
	} elsif ((!exists $request{reportid}) && (!exists $request{fileid})) {
		$self->_croak("get_nzb(): must supply either 'reportid' or 'fileid' as a parameter");
	}
	
	if (exists $request{reportid}) {
		if ($request{reportid} =~ /\D/) {
			$self->_croak("get_nzb(): 'reportid' parameter must be an integer");
		}
	} elsif (exists $request{fileid}) {
		# an integer or an arrayref of integers is acceptable here
		if (ref($request{fileid}) =~ /^ARRAY/) {
			foreach my $fid (@{$request{fileid}}) {
				if ($fid =~ /\D/) {
					$self->_croak("get_nzb(): 'fileid' parameter must be an integer or arrayref of integers");
				}
			}
		} else {
			if ($request{fileid} =~ /\D/) {
				$self->_croak("get_nzb(): 'fileid' parameter must be an integer or arrayref of integers");
			}
		}
	}
	
	# check for compress::zlib
	eval { require Compress::Zlib; };
	my $compress_zlib = ($Compress::Zlib::VERSION ? 1 : 0);
	
	my $response = $ua->post(
		"http://v3.newzbin.com/api/dnzb/",
		{
			username => $self->{param}->{username},
			password => $self->{param}->{password},
			reportid => (exists $request{reportid} ? $request{reportid} : ""),
			fileid => (exists $request{fileid} ? (ref($request{fileid}) =~ /^ARRAY/ ? join(",", @{$request{fileid}}) : $request{fileid}) : ""),
		},
		# if compress::zlib is installed and gzip compression hasn't been disabled, send a header that will result in a gzipped response
		"Accept-Encoding" => (((!$request{nogzip}) && ($compress_zlib)) ? "gzip" : "")
	);
	
	# examine http response code, filter out errors
	if (!$response->is_success) {
		if ($response->code == 500) {
			# newzbin server error
			$self->_set_error(-1, "Invalid response from Newzbin's DirectNZB API");
		} elsif ($response->code == 503) {
			# directnzb down for maintenance
			$self->_set_error(-1, "Newzbin's DirectNZB API is currently unavailable");

		# examine newzbin-specific response code, filter out errors
		} elsif ($response->header("X-DNZB-RCode") =~ /^400/) {
			# missing parameters
			$self->_croak("get_nzb(): must supply either 'reportid' or 'fileid' as a parameter; 'reportid' must be an integer, and 'fileid' must be an integer or arrayref of integers");
		} elsif ($response->header("X-DNZB-RCode") =~ /^401/) {
			# invalid credentials
			$self->_set_error(-2, "Invalid Newzbin login credentials given");
		} elsif ($response->header("X-DNZB-RCode") =~ /^402/) {
			# no premium credit
			$self->_set_error(-3, "This is not a Newzbin Premium account");
		} elsif ($response->header("X-DNZB-RCode") =~ /^404/) {
			# data unavailable
			$self->_set_error(-4, "Data requested does not exist or is unavailable");
		} elsif ($response->header("X-DNZB-RCode") =~ /^450/) {
			# too many nzb download requests
			# get number of seconds user has to wait
			my $timeout = $response->header("X-DNZB-RText");
			$timeout =~ s/.*Try Later, wait (\d+) second.*/$1/i;
			$self->_set_error(($timeout =~ /\D/ ? 60 : $timeout), "Too many NZB download requests; try again in $timeout second" . ($timeout == 1 ? "" : "s"));
		} else {
			$self->_set_error(-1, "Newzbin's DirectNZB API is currently unavailable");
		}

		return undef;
	}
	
	if ($response->header("X-DNZB-RCode") =~ /^200/) {
		# nzb contents are in body of document
		
		# if response headers indicate that content is compressed with gzip, uncompress it
		my $nzb_file;
		if (($response->header("Content-Encoding") =~ /gzip/) && (!$request{leavegzipped})) {
			my $raw = $response->content;
			$nzb_file = Compress::Zlib::memGunzip($raw) or $self->_carp("get_nzb(): could not decompress NZB file; try passing 'nogzip => 1' as a parameter") and $self->_set_error(-5, "Could not decompress NZB file") and return undef;
		} else {
			$nzb_file = $response->content;
		}
		
		if ($request{reportid}) {
			# if this is a report download, newzbin also supplies a name and category in the http headers
			return ($nzb_file, $response->header("X-DNZB-Name"), $response->header("X-DNZB-Category"));
		} elsif ($request{fileid}) {
			return $nzb_file;
		}
	} else {
		$self->_set_error(-1, "Invalid response from Newzbin's DirectNZB API");
		return undef;
	}
}

#=============================================================================#

1;

__END__

#=============================================================================#

=pod

=head1 NAME

WWW::Newzbin - Interface to Newzbin.com's Usenet index

=head1 SYNOPSIS

	use WWW::Newzbin;
	use WWW::Newzbin::Constants qw(:all);
	
	my $nzb = WWW::Newzbin->new(
		username => "joebloggs",
		password => "secretpass123"
	);

	$nzb->lwp_useragent->timeout(10); # ADVANCED: allow less time for responses from newzbin
	
	my @results = $nzb->search_files(
		query => "the john smith orchestra",
		category => [ NEWZBIN_CAT_MUSIC, NEWZBIN_CAT_MOVIES ], # search in Newzbin's "music" and "movies" categories...
		group => [ "alt.binaries.music", "alt.binaries.test" ], # ...and return results from these groups only
		retention => 30, # no more than 30 days old
		resultlimit => 50, # return maximum of 50 results
		sortfield => NEWZBIN_SORTFIELD_SUBJECT, # sort by subject...
		sortorder => NEWZBIN_SORTORDER_ASC # ...in ascending order
	);
	
	if ($nzb->error_code) {
		print "Error # " . $nzb->error_code . ": " . $nzb->error_message;
	} else {
		print "Total number of results found: " . $nzb->search_files_total;
		print "Subject of result #1: " . $results[0]->{subject};
	}
	
	# make an nzb file for binaries in newzbin report #12345678
	my ($nzb_file, $report_name, $report_category) = $nzb->get_nzb(reportid => 12345678);
	
	# make an nzb file for binaries in newzbin report #12345678, and leave the nzb file gzip-compressed
	my ($nzb_file_gzipped, $report_name, $report_category) = $nzb->get_nzb(
		reportid => 12345678,
		leavegzip => 1
	);
	
	# make an nzb file for binaries with the newzbin file ids #123, #456 and #789, and don't compress it when downloading it
	my $nzb_file = $nzb->get_nzb(
		fileid => [ 123, 456, 789 ],
		nogzip => 1
	);

=head1 DESCRIPTION

This module is a Perl interface to the Newzbin.com v3 direct APIs. Newzbin is a Usenet binary indexing service that also offers .nzb files - short summary files containing all the information a newsreader requires to download any given binary or set of binaries from Usenet.

=head1 METHODS

=head2 COMMON METHODS

=head3 new

	my $nzb = WWW::Newzbin->new(
		username => "joebloggs",
		password => "secretpass123"
	);

The C<new()> method constructs a new C<WWW::Newzbin> object.

C<username> and C<password> should be valid Newzbin credentials, and both must be supplied for the object to be successfully constructed. The C<new()> method B<does not> check whether these credentials are valid.

Other (optional) parameters are:

=over

=item *

C<nowarnings> - C<WWW::Newzbin> C<warn>s whenever something unexpected happens (for example, if an unrecognised parameter is passed to a method, or if a recognised parameter is passed in an incorrect manner). Any true value (e.g. C<1>) for C<nowarnings> disables all warnings issued by C<WWW::Newzbin>.

=item *

C<proxy> - Defines a proxy server that the underlying L<LWP::UserAgent> object will use when accessing Newzbin. Should be given in the format C<http://proxy.address:port>.

=back

C<die>s if the username or password are missing, and C<warn>s if any unrecognised parameters are given.

=head3 error_code

	print "Error code for last error: " . $nzb->error_code;

If an error occurred during the last method call, this method will return an integer describing what kind of error occurred (or C<undef> if an error did not occur during the last method call). Check the documentation for each individual method for a list of expected return values from C<error_code>.

This method's output is programmatically useful, but isn't pretty to give back to a user. Consider L</"error_message"> for user feedback.

=head3 error_message

	print "An error occurred while processing your request: " . $nzb->error_message;

If an error occurred during the last method call, this method will return a short description of the error (or C<undef> if an error did not occur during the last method call). Check the documentation for each individual method for an idea of what to expect for a return value from this method - the message will depend on the L</"error_code">.

This method's output is useful for user feedback, but isn't very useful programmatically. Consider L</"error_code"> for handling errors using code.

=head3 search_files

	my @results = $nzb->search_files(
		query => "the john smith orchestra",
		category => [ NEWZBIN_CAT_MUSIC, NEWZBIN_CAT_MOVIES ],
		group => [ "alt.binaries.music", "alt.binaries.test" ],
		retention => 30,
		resultlimit => 50,
		sortfield => NEWZBIN_SORTFIELD_SUBJECT,
		sortorder => NEWZBIN_SORTORDER_ASC
	);

Searches Newzbin's files index for a given string, and (optionally) filters the results based on given criteria. B<Please note> that it is not possible to search Newzbin without a valid Premium account.

Search criteria are passed as parameters to the method. The following parameters are allowed; each is optional unless otherwise specified:

=over

=item *

C<query> B<(required)> - The string of text to search for.

=item *

C<category> - The Newzbin category (or categories) to search. Any of the C<NEWZBIN_CAT_*> constants specified in L<WWW::Newzbin::Constants> are valid. May be a single constant if only one category is to be searched, or an arrayref of constants if more than one category is to be searched. Default is none (i.e. all categories are searched).

=item *

C<group> - The Usenet newsgroup (or newsgroups) to search. May be a scalar containing the name of a single newsgroup to search, or an arrayref of scalars if more than one newsgroup is to be searched. Default is none (i.e. all newsgroups are searched).

=item *

C<retention> - The maximum age (in days) of a file that is permitted for it to be included as a search result. Must be at least 1, and at most 240 (this might change without notice; see L</"LIMITATIONS">). Default is currently 7 (again, this might change without notice; see L</"LIMITATIONS">).

=item *

C<minsize> and C<maxsize> - Respectively, the minimum and maximum sizes (in bytes) that files must be to count as results. Either parameter may be given; if both are given, C<minsize> must be less than or equal to C<maxsize>, otherwise neither criteria will be considered in the search. Defaults are 0 for both parameters (i.e. no file size restrictions).

=item *

C<filetype> - Filter by file type. At the time of writing, values currently accepted by Newzbin for this field are I<SFV>, I<NFO> and I<NZB> (this might change without notice; see L</"LIMITATIONS">). Default is none (i.e. all file types are allowed).

=item *

C<resultoffset> and C<resultlimit> - Respectively, the offset at which to begin returning results and the maximum number of results to return for this search. Either parameter (or both) may be specified. C<resultoffset> should be at least 0 and C<resultlimit> must be at most 5000 (this might change without notice; see L</"LIMITATIONS">), otherwise neither criteria will be considered in the search. Defaults are 0 for C<resultoffset> and 500 for C<resultlimit> (again, this might change without notice; see L</"LIMITATIONS">).

=item *

C<sortfield> and C<sortorder> - Respectively, the field by which to sort and the order in which to sort. Any of the C<NEWZBIN_SORTFIELD_*> constants specified in L<WWW::Newzbin::Constants> are valid for the C<sortfield> parameter, and any of the C<NEWZBIN_SORTORDER_*> constants specified in L<WWW::Newzbin::Constants> are valid for the C<sortorder> parameter. If an invalid value is used for either parameter, the values given for both parameters will not be considered as search criteria. Defaults are C<NEWZBIN_SORTFIELD_DATE> (the file's posted date) for C<sortfield> and C<NEWZBIN_SORTORDER_ASC> (ascending) for C<sortorder> (either of these might change without notice; see L</"LIMITATIONS">).

=back

If the search is successful, the method returns an array of results (with the first result at the head of the array). Each result is a hashref containing the following keys:

=over

=item *

C<fileid> - Newzbin's unique, internal ID for this file. Suitable for use in L</"get_nzb">.

=item *

C<subject> - The file's subject (title), as given by its poster.

=item *

C<posttime> - Unix representation of the date and time at which the file was posted to Usenet (may not be completely accurate; see L</"LIMITATIONS">).

=item *

C<filesize> - The size of the file, in bytes (may not be completely accurate; see L</"LIMITATIONS">).

=item *

C<author> - The name of the user who posted the file to Usenet.

=item *

C<groups> - An arrayref containing a list of the newsgroups to which this file was posted.

=back

The method C<die>s if required parameters were not passed to it, and C<warn>s if unrecognised parameters were passed (but the search will still progress). If the search was otherwise unsuccessful, the method returns C<undef> and L</"error_code"> will return one of the following values:

=over

=item *

C<-1> - The search could not be carried out due to a technical fault; L</"error_message"> gives a more verbose reason.

=item *

C<-2> - Invalid Newzbin account credentials were given in the constructor for C<WWW::Newzbin>.

=item *

C<-3> - The account credentials given in the constructor were valid, but the account is not a Newzbin Premium account. A Premium account is required for searching.

=item *

C<-4> - No results that matched the given search criteria could be found.

=back

=head3 search_files_total

	print "Total number of files found: " . $nzb->search_files_total;

If used after a successful call to L</"search_files">, this method returns the total number of results that would have been returned if C<resultlimit> had not been specified. If used after an unsuccessful (or no) call to L</"search_files">, returns C<undef>.

=head3 get_nzb

	my ($nzb_file, $report_name, $report_category) = $nzb->get_nzb(reportid => 12345678);
	
	my ($nzb_file_gzipped, $report_name, $report_category) = $nzb->get_nzb(
		reportid => 12345678,
		leavegzip => 1
	);
	
	my $nzb_file = $nzb->get_nzb(
		fileid => [ 123, 456, 789 ]
	);

Constructs an NZB (.nzb file) based on either a Newzbin report ID or one or more Newzbin file IDs. B<Please note> that it is not possible to construct NZB files without a valid Premium account.

NZB files are easily compressed, and Newzbin supports I<gzip> file compression for NZB downloads. If L<Compress::Zlib> is available, C<WWW::Newzbin> will transparently handle compression to reduce bandwidth usage; otherwise, the NZB file will be downloaded uncompressed.

Either (but B<not both>) of the following parameters are required:

=over

=item *

C<reportid> - A scalar containing the ID of the Newzbin report to download. All files listed in the report will be included in the NZB.

=item *

C<fileid> - A scalar or arrayref of scalars containing the Newzbin file ID or IDs to include in the NZB.

=back

Other acceptable parameters for this method are as follows (all parameters listed below are optional):

=over

=item *

C<nogzip> - If set to a true value (i.e. C<1>), forcefully disables the compression feature explained above. Use this if L<Compress::Zlib> is installed but isn't working for some reason.

=item *

C<leavegzipped> - If set to a true value (i.e. C<1>), download the compressed version of the NZB file, but leave it compressed when the method returns (rather than decompressing it and returning that, which is the default behaviour). Useful if the NZB file needs to be transferred over a network to another end-user.

=back

The method's return value depends on how it was called:

=over

=item *

If C<fileid> was supplied, the method returns a scalar containing the NZB file.

=item *

If C<reportid> was supplied, the method returns an array containing the following (in this order):

=over

=item *

A scalar containing the NZB file;

=item *

A scalar containing the name of the report;

=item *

The Newzbin category in which the report was filed (see L<WWW::Newzbin::Constants>).

=back

=back

The method C<die>s if one of the required parameters were not passed to it, and C<warn>s if unrecognised parameters were passed (but the download will still occur). If the download was otherwise unsuccessful, the method returns C<undef> and L</"error_code"> will return one of the following values:

=over

=item *

Any integer greater than C<0> - Newzbin rate-limits the number of NZB download requests that a user can make in a given timeframe. A positive integer means your account is being rate-limited and that you must wait this many seconds before sending your request again. See L</"LIMITATIONS">.

=item *

C<-1> - The download could not be requested due to a technical fault; L</"error_message"> gives a more verbose reason.

=item *

C<-2> - Invalid Newzbin account credentials were given in the constructor for C<WWW::Newzbin>.

=item *

C<-3> - The account credentials given in the constructor were valid, but the account is not a Newzbin Premium account. A Premium account is required for downloading NZB files.

=item *

C<-4> - In the words of Newzbin's documentation: I<"the data trying to be fetched does not exist or is not accessible">. If this error code is returned, do not try the same request again because you will receive the same response.

=item *

C<-5> - C<WWW::Newzbin> downloaded the compressed version of the NZB and tried to decompress it using L<Compress::Zlib>, but failed for some reason. If this error code is returned, consider using C<nogzip> or C<leavegzipped> to bypass decompression.

=back

=head2 ADVANCED METHODS

=head3 lwp_useragent

	$nzb->lwp_useragent->timeout(30);

Grants access to the underlying L<LWP::UserAgent> object that powers C<WWW::Newzbin>. Useful for fine-tuning; if you just need to specify a proxy server for L<LWP::UserAgent>, consider using the far-neater C<proxy> parameter in the L</"new"> constructor.

=head1 LIMITATIONS

=head2 USENET LIMITATIONS

The C<posttime> and C<filesize> values returned for each result by L</"search_files"> may not always be accurate because Newzbin reports the post time and file size based on the first news server on which it sees the file. Newzbin's I<FileFind> documentation states that the file size I<"should be accurate to within a few kilobytes">, however.

=head2 NEWZBIN LIMITATIONS

I<FileFind>, the Newzbin API upon which L</"search_files"> relies, has default values for a number of its parameters (specifically: C<retention>, C<resultoffset> and C<resultlimit>). The C<WWW::Newzbin> documentation states these defaults but they are actually set by the Newzbin API, not by this module. This means, of course, that the Newzbin developers could change these default values at any time, which may drastically alter the search results that C<WWW::Newzbin> returns. Every effort will be made to keep this documentation up-to-date with any changes made to the default values in the I<FileFind> API, but you are advised to explicitly specify L</"search_files"> parameters rather than relying too much on the defaults.

Newzbin's retention is currently 240 days. At the moment no mainstream Usenet provider has a retention that Newzbin doesn't cover, but this might change in future. Therefore, while the C<WWW::Newzbin> documentation states that the L</"search_files"> C<retention> parameter must not exceed 240, this limit is not hardcoded and specifying longer retentions will not result in a warning or error.

Newzbin intentionally caps I<FileFind>'s result limit to 5000. The L</"search_files"> C<resultlimit> parameter, therefore, should not exceed 5000; although Newzbin could of course change or remove this limit at any time without notice, so C<WWW::Newzbin> will not produce a warning or error if C<resultlimit> is greater than 5000.

The L</"search_files"> C<filetype> parameter only accepts a handful of file types. Newzbin's I<FileFind> documentation states that you're welcome to contact them to request indexing of other file types. Nevertheless, the I<FileFind> documentation also states that file type filtering is I<"fairly accurate, but don't rely on it as any malicious Usenet poster could easily circumvent it">.

I<DirectNZB>, the Newzbin API upon which L</"get_nzb"> relies, only allows B<either> one report ID B<or> several file IDs per request. The documentation states that this is unlikely to change in future.

I<DirectNZB> also limits the rate at which accounts can generate NZB files - currently the restriction is 5 NZB files per minute per IP address. If L</"get_nzb"> reports a positive integer as its C<error_code>, you are advised to wait that many seconds (or, preferably, 60 seconds) before calling L</"get_nzb"> again. Failure to do so might result in your IP address (or even the entire account) being banned from accessing Newzbin.

=head1 DEPENDENCIES

L<WWW::Newzbin::Constants>, L<LWP::UserAgent>

Optional: L<Compress::Zlib>

=head1 SEE ALSO

Documentation for associated modules (see L</"DEPENDENCIES">).

L<http://docs.newzbin.com/index.php/Newzbin:FileFind> - Newzbin documentation for I<FileFind>, which powers the L</"search_files"> method.

L<http://docs.newzbin.com/index.php/Newzbin:DirectNZB> - Newzbin documentation for I<DirectNZB>, which powers the L</"get_nzb"> method.

=head1 AUTHOR

Chris Novakovic <chrisn@cpan.org>

=head1 COPYRIGHT

Copyright 2007-8 Chris Novakovic.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
