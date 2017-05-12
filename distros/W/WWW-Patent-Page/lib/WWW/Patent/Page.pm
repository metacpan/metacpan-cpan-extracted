package WWW::Patent::Page;    #modeled vaguely on LWP::UserAgent
use strict;
use warnings;
use diagnostics;
use Carp qw(carp cluck confess);
use English qw( -no_match_vars );

#use HTML::Display;    ## comment out after completion; used for testing.  see sub request 
#my $browser = HTML::Display->new(class => 'HTML::Display::Win32::IE',);   #comment out after completion; used for testing.  see sub request 


# use criticism 'brutal'; # handled in tests; author only
# $ prove -l lib --verbose  t/999_critic.t  # example of using prove
require LWP::UserAgent;
use WWW::Patent::Page::Response;

#use HTTP::Cache::Transparent; 
#HTTP::Cache::Transparent::init( {
#	BasePath => '/tmp/cache' ,
#	NoUpdate => 60 * 60 *24 * 7 * 52  # seconds 2 minutes 2 hours 2 days 2 weeks 2 years = 1 year 
#}); 

use subs qw( new country_known get_page _load_modules _agent _load_country_known );
my (%METHODS, %_country_known);
my (%MODULES, $default_country, $default_office, @modules_to_load);

use version; our $VERSION = qv('0.109.0');    # January, 2012
use base qw( LWP::UserAgent );
%_country_known = _load_country_known();

# user set variables:
@modules_to_load = (
	'USPTO', 
	#'MICROPATENT', 
	#'JPO_IPDI' , 
	# 'ESPACE_EP', # 'ESPACE_EP' bad  August 2009 due to captcha use 
	# , 'OPEN_PATENT_SERVICES'     # Watch this space!
);

# if you write your own module; please send to wanda_b_Anon@yahoo.com for distribution

$default_country = 'US';
# $default_office  = 'ESPACE_EP';    # they support many countries/entities
$default_office  = 'USPTO';    # 'ESPACE_EP' bad  August 2009 due to captcha use 

sub new {
	my ($class, $doc_id, %passed_parm);
	if (@_ % 2) {($class, %passed_parm) = (@_);}
	else {($class, $doc_id, %passed_parm) = (@_);}

	# if an odd number of parameters is passed, the first is the doc_id
	# the other pairs are the hash of values, including UserAgent settings

	#	my ($class) = shift @_;
	my %parent_parms = (
		agent => "WWW::Patent::Page/$VERSION",

		#	     cookie_jar => {},
	);
	my %default_parameter = (
		'is_success'          => undef,
		'message'             => undef,
		'office'              => $default_office,     # USPTO is provided
		'office_username'     => undef,               # e.g. MicroPatent account
		'office_password'     => undef,               # e.g. MicroPatent password
		'session_token'       => undef,               # e.g. session number in Micropatent, from username and password
		'country'             => $default_country,    #US is provided
		'doc_id'              => undef,               # US_6,123,456 as entered
		'doc_id_standardized' => undef,               # US6123456    sparse
		'doc_id_commified'    => undef,               # US6,123,456
		'doc_type'            => undef,               # PP, RE, D, etc
		'format'              => 'pdf',               # pdf html
		'page'                => undef,

		#		'version'             => undef,
		'comment' => undef,
		'kind'    => undef,                           # A B etc (not yet used)
		'number'  => undef,                           # 6123456
		'tempdir' => undef,                           # directory for temp files USPTO_pdf
	);

	#	my %passed_parms;
	if ($doc_id) {
		$default_parameter{'doc_id'} = $doc_id;
		$passed_parm{'doc_id'}       = $doc_id;
	}

	# if an odd number of parameters is passed, the first is the doc_id
	# the other pairs are the hash of values, including UserAgent settings
	#	%passed_parm = @_;

#	if ( defined($passed_parm{'country'} or defined($passed_parm{'number'}) { delete $passed_parm{'doc_id'}; $self->{'patent'}->{'doc_id'} = undef  }
# Keep the patent-specific parms before creating the object.
# (the parameters defined above are the only user exposed parameters allowed)
	while (my ($key, $value) = each %passed_parm) {
		if (exists $default_parameter{$key}) {
			$default_parameter{$key} = $value;
		}
		else {
			$parent_parms{$key} = $value;
		}
	}
	my $self = $class->SUPER::new(%parent_parms);
	bless $self, ref $class || $class;    # or is it: bless $self, $class;

	# Use the patent parms now that we have a patent object.
	for my $parm (keys %default_parameter) {
		$self->{'patent'}->{$parm} = $default_parameter{$parm};
	}

	$self->cookie_jar({});
	$self->env_proxy();                   # get the proxy stuff set up from the environment via LWP::UserAgent
	 # $self->proxy(['http', 'ftp'], 'http://localhost:5364/'); #Howard P. Katseff, "Web Scraping Proxy" wsp http://www.research.att.com/~hpk/
	$self->timeout(240);    # set to timeout to 240 seconds from the traditional 180 seconds
	push @{$self->requests_redirectable}, 'POST';    # redirect HTTP 1.1 302s  LWP::UserAgent
	if (!defined $self->agent) {$self->agent = $class->_agent}
	$self->_load_modules(@modules_to_load);          # list your custom modules here,
	                                                 # and put them into the folder that holds the others, e.g. USPTO.pm
	if (    defined $passed_parm{'country'}
		and defined $passed_parm{'number'})
	{
		delete $passed_parm{'doc_id'};
		$self->{'patent'}->{'doc_id'} = $passed_parm{'country'} . $passed_parm{'number'};
	}
	if ($self->{'patent'}->{'doc_id'}) {             # if called with doc ID, parse it- unless it seems to be parsed already
		$self->parse_doc_id();
	}
	return $self;
}

sub country_known {
	my $self = shift;
	my ($country_in_question) = shift;
	if (exists $_country_known{$country_in_question}) {
		return ($_country_known{$country_in_question});
	}
	else {
		return (undef);
	}
}

sub parse_doc_id {
	my ($self, $id) = (@_);
	$self->{'patent'}->{'message'} = q{};
	if (!$id) {
		$id = $self->{'patent'}->{'doc_id'}
			or (carp 'No document id to parse' and return);
	}
	my ($found, $country, $type, $number, $kind, $comment) = (undef, undef, undef, undef, undef, undef);

	# start country parsing
	if (   $id =~ m{^    # anchor to beginning of string
    [, _\.\t-]*   #separator(s) (optional)
    (\D\D){0,1}   # country (optional) (well, sometimes the type, if country not supplied because known by other means)
    [, _\.\t-]*            #separator(s) (optional)
    (D|PP|RE|T|H|RX|AI|d|pp|re|t|h|rx|ai|S|M|s|m){0,1}   # type, if accompanied by country (use below also!)
    [, _\.\t-]*            #separator(s) (optional)
    ([, _\d-]+)  # "number" REQUIRED to have digits - with interspersed separator(s) (optional)
    [, _\.\t-]*            #separator(s) (optional)
    (
        A$|A[, _\.\t-]+|B$|B[, _\.\t-]+|D$|D[, _\.\t-]+|E$|E[, _\.\t-]+|H$|H[, _\.\t-]+|
        L$|L[, _\.\t-]+|M$|M[, _\.\t-]+|O$|O[, _\.\t-]+|P$|P[, _\.\t-]+|S$|S[, _\.\t-]+|
        T$|T[, _\.\t-]+|U$|U[, _\.\t-]+|W$|W[, _\.\t-]+|X$|X[, _\.\t-]+|Y$|Y[, _\.\t-]+|
        Z$|Z[, _\.\t-]+|
        A0|A1|A2|A3|A4|A5|A6|A7|A8|A9|B1|B2|B3|B4|B5|B6|B8|B9|C$|C0|C1|C2|C3|C4|C5|
        C8|C[, _\.\t-]+|F1|F2|H1|H2|P1|P2|P3|P4|P9|T1|T2|T3|T4|T5|T9|U0|U1|U2|U3|U4|
        U8|W1|W2|X0|X1|X2|Y1|Y2|Y3|Y4|Y5|Y6|Y8|

        a$|a[, _\.\t-]+|b$|b[, _\.\t-]+|d$|d[, _\.\t-]+|e$|e[, _\.\t-]+|h$|h[, _\.\t-]+|
        l$|l[, _\.\t-]+|m$|m[, _\.\t-]+|o$|o[, _\.\t-]+|p$|p[, _\.\t-]+|s$|s[, _\.\t-]+|
        t$|t[, _\.\t-]+|u$|u[, _\.\t-]+|w$|w[, _\.\t-]+|x$|x[, _\.\t-]+|y$|y[, _\.\t-]+|
        z$|z[, _\.\t-]+|
        a0|a1|a2|a3|a4|a5|a6|a7|a8|a9|b1|b2|b3|b4|b5|b6|b8|b9|c$|c0|c1|c2|c3|c4|c5|
        c8|c[, _\.\t-]+|f1|f2|h1|h2|p1|p2|p3|p4|p9|t1|t2|t3|t4|t5|t9|u0|u1|u2|u3|u4|
        u8|w1|w2|x0|x1|x2|y1|y2|y3|y4|y5|y6|y8

        ){0,1}
                  # kind code (eats up separator required before comment)
    (.*)     # comment (optional, if used, required to be preceded by at least one separator)
	}mx
		)
	{
		$country = $1;
		$type    = $2;
		$number  = $3;
		$kind    = $4;
		$comment = $5;

		if ($country) {$country = uc $country;}
		else {$country = $default_country}

		#        $type = $2;
		if ($type) {
			$type = uc $type;
		}    #actually, required to be upper case
		else {$type = undef;}
		if ((!defined $type) && !$type && (!$_country_known{$country})) {
			if ($country =~ m/(D|PP|RE|T|H|RX|AI|d|pp|re|t|h|rx|ai|S|M|s|m)/mx) {
				$type    = $country;
				$country = $default_country;
			}
			else {

				# carp "unrecognized _country or type: country: from '$id' ";
				$self->{'patent'}->{'country'}    = undef;
				$self->{'patent'}->{'is_success'} = undef;
				$self->{'patent'}->{'message'}    = "unrecognized _country or type: country: from '$id'";
				return (undef);
			}
		}

		if (      (!exists $_country_known{$country})
			|| ($type
				&& (!$type =~ m/(^D$|^PP$|RE|T|H|RX|AI|d|pp|re|t|h|rx|ai)/mx))
			)
		{

			# carp "unrecognized _country or type: country: '$country' type: '$type' from '$id' ";
			$self->{'patent'}->{'country'}    = undef;
			$self->{'patent'}->{'is_success'} = undef;
			$self->{'patent'}->{'message'}    = "unrecognized _country or type: country: '$country' type: '$type' from '$id'";
			return (undef);
		}

		#		$number = $3;
		if ($number) {$number =~ s/[, _\- ]//mxg;}
		else {print "\nno number!!!\n"}

		#		$kind = $4;
		if ($kind) {$kind = uc $kind}
		if ($kind) {$kind =~ s/[, _\- ]//mxg;}

		#		$comment = $5;
		if ($comment) {
			$comment =~ s/^[,_\- ]*//mxg;
			$comment =~ s/[,_\- ]*$//mxg;
		}

		$self->{'patent'}->{'country'}  = $country;
		$self->{'patent'}->{'doc_type'} = $type;
		$self->{'patent'}->{'number'}   = $number;
		$self->{'patent'}->{'kind'}     = $kind;
		$self->{'patent'}->{'comment'}  = $comment;
	}
	else {
		carp "document id '$id'\nnot parsed.";
		$self->{'patent'}{'is_success'} = undef;
		$self->{'patent'}{'message'}    = "document id '$id' not parsed.";
		return (undef);
	}
## Japanese number fiddling- later, this bind of crap may go into JPO_IPDI_parse_doc_id

	if ($self->{'patent'}->{'country'} eq 'JP') {

		#	print "country = jp type = $self->{'patent'}->{'doc_type'}\n";
		if (uc($self->{'patent'}->{'doc_type'}) eq 'H' or uc($self->{'patent'}->{'doc_type'}) eq 'S' or uc($self->{'patent'}->{'doc_type'}) eq 'T' or uc($self->{'patent'}->{'doc_type'}) eq 'M') {
			my $year = substr($self->{'patent'}->{'number'}, 0, 2);    # Heisei < 10 must have 0 prefix
			$self->{'patent'}->{'number'} =~ s{^\d\d}{}xm;
			$self->{'patent'}->{'doc_type'} .= "$year-";
		}
#		elsif (uc($self->{'patent'}->{'doc_type'}) eq 'S') {
#			my $year = substr($self->{'patent'}->{'number'}, 0, 2);    # Heisei < 10 must have 0 prefix
#			$self->{'patent'}->{'number'} =~ s{^\d\d}{}xm;
#			$self->{'patent'}->{'doc_type'} .= "$year-";
#		}
#		elsif (uc($self->{'patent'}->{'doc_type'}) eq 'T') {
#			my $year = substr($self->{'patent'}->{'number'}, 0, 2);    # Heisei < 10 must have 0 prefix
#			$self->{'patent'}->{'number'} =~ s{^\d\d}{}xm;
#			$self->{'patent'}->{'doc_type'} = "$year-";
#		}
#		elsif (uc($self->{'patent'}->{'doc_type'}) eq 'M') {
#			my $year = substr($self->{'patent'}->{'number'}, 0, 2);    # Heisei < 10 must have 0 prefix
#			$self->{'patent'}->{'number'} =~ s{^\d\d}{}xm;
#			$self->{'patent'}->{'doc_type'} .= "$year-";
#		}
		elsif ( (substr($self->{'patent'}->{'number'}, 3, 1) ne q(-))
			and (length($self->{'patent'}->{'number'}) > 7)
			and (substr($self->{'patent'}->{'number'}, 0, 4) > 1992)
			and substr($self->{'patent'}->{'number'}, 0, 4) <= ((localtime(time))[5] + 1900))
		{
			$self->{'patent'}->{'number'} =~ s{^(\d\d\d\d)}{$1-}xm;
		}
	}

	$found = undef;
	if (defined $self->{'patent'}->{'country'}) {
		$found .= " country:$self->{'patent'}->{'country'} ";
	}
	else {$found .= ' country: "" ';}
	if (defined $self->{'patent'}->{'doc_type'}) {
		$found .= " type:$self->{'patent'}->{'doc_type'} ";
	}
	else {$found .= ' doc_type: "" ';}
	if (defined $self->{'patent'}->{'number'}) {
		$found .= " number:$self->{'patent'}->{'number'} ";
	}
	else {$found .= ' number: "" ';}
	if (defined $self->{'patent'}->{'kind'}) {
		$found .= " kind:$self->{'patent'}->{'kind'} ";
	}
	else {$found .= ' kind: "" ';}
	if (defined $self->{'patent'}->{'comment'}) {
		$found .= " comment:$self->{'patent'}->{'comment'} ";
	}
	else {$found .= ' comment: "" ';}

	if (   $self->{'patent'}->{'doc_type'}
		&& $self->{'patent'}->{'kind'})
	{
		$self->{'patent'}->{'doc_id_standardized'} = $self->{'patent'}->{'country'}
			. $self->{'patent'}->{'doc_type'}
			. $self->{'patent'}->{'number'}
			. $self->{'patent'}->{'kind'};
	}
	elsif ((!$self->{'patent'}->{'doc_type'})
		&& (!$self->{'patent'}->{'kind'}))
	{
		$self->{'patent'}->{'doc_id_standardized'} = $self->{'patent'}->{'country'} . $self->{'patent'}->{'number'};
	}
	elsif (!$self->{'patent'}->{'kind'}) {
		$self->{'patent'}->{'doc_id_standardized'}
			= $self->{'patent'}->{'country'} . $self->{'patent'}->{'doc_type'} . $self->{'patent'}->{'number'};
	}
	else {
		$self->{'patent'}->{'doc_id_standardized'}
			= $self->{'patent'}->{'country'} . $self->{'patent'}->{'number'} . $self->{'patent'}->{'kind'};
	}
	return $found;    
}

sub get_page {
	my $self = shift;
	my $count;
	if (@_ % 2) {
		$self->{'patent'}->{'doc_id'} = shift @_;
	}
	my %passed_parm = @_;

	# Keep the patent-specific parms before USING the object.
	# (the parameters defined above are the only user exposed parameters allowed)
	while (my ($key, $value) = each %passed_parm) {
		if (exists $self->{$key}) {
			$self->{$key} = $value;
		}
		elsif (exists $self->{'patent'}->{$key}) {
			$self->{'patent'}->{$key} = $value;
		}
	}
	if ($self->{'patent'}->{'doc_id'}) {$self->parse_doc_id();}
	my $response = WWW::Patent::Page::Response->new(%{$self->{'patent'}});    # make it here to run sanity tests
	if (!$response->get_parameter('country')) {
		$response->set_parameter('is_success', undef);
		$response->set_parameter('message',    'no country defined');

		#        print "no country defined\n";
		return $response;
	}
	if (!$_country_known{$response->get_parameter('country')}) {
		$response->set_parameter('is_success', undef);
		$response->set_parameter('message',    q{country '} . $response->get_parameter('country') . q{' not recognized});

		#		print "country not recognized";
		return $response;
	}
	if (!$response->get_parameter('number')) {
		$response->set_parameter('is_success', undef);
		$response->set_parameter('message',    'no patent number defined');
		return $response;
	}
	if (!$response->get_parameter('office')) {
		$response->set_parameter('is_success', undef);
		$response->set_parameter('message',    'no office defined');
		return $response;
	}
	if (!$response->get_parameter('format')) {
		$response->set_parameter('is_success', undef);
		$response->set_parameter('message',    'no format defined');
		return $response;
	}
	my $provide_doc = "$self->{'patent'}->{'office'}" . '_' . "$self->{'patent'}->{'format'}";
	if (!exists $METHODS{$provide_doc}) {
		$response->set_parameter('is_success', undef);
		$response->set_parameter('message',    "method '$provide_doc' not provided");
		return $response;
	}
	my $function_reference = $METHODS{$provide_doc}
		or carp "No method '$provide_doc'";

	#		print "pass hash\n";
	$response = &{$function_reference}($self, $response)    # pass our hash to a specific fetcher
		or carp "No response for method '$provide_doc'";

	#		print "hash back\n";
	if (!$response) {carp 'no response to return'}
	return $response;
}

sub terms {
	my $self = shift;    # pass $self, then optionally the office whose terms you need, or use that office set in $self
	my $office;
	if (@_ % 2) {$office = shift @_}
	else {$office = $self->{'patent'}->{'office'}}
	if (!exists $METHODS{$office . '_terms'}) {
		carp "Undefined method $office" . '_terms in Patent:Document::Retrieve';
		return (  'WWW::Patent::Page uses publicly available information that may be subject to copyright.' . "\n"
				. 'The user is responsible for observing intellectual property rights. ');
	}
	my $terms              = $office . '_terms';
	my $function_reference = $METHODS{$terms};
	return &{$function_reference}($self);
}

sub request {
	# intercept the LWP request to allow various things
	my $self = shift; 	
	my $count = 0;
#	my $response=$HTTP::Response->new();
	my $response = LWP::UserAgent::request($self, @_); 
	while (($count < 2) && (! $response->is_success) ) { # make $count assignable at start-up, configurable 
		$count++;
		if ( $response->code == 500 ) { sleep 5; $response = LWP::UserAgent::request($self, @_); cluck 'server responded with code 500, internal server error, trying again for you in case they got their act together in the last few seconds' } # second chance
		if ( $response->code == 503 ) { sleep 5; $response = LWP::UserAgent::request($self, @_); cluck 'server responded with code 503, Service Unavailable, trying again for you in case it became available in the last few seconds' } # second chance
	}
	if ( ! $response->is_success) {confess 'original url = "'.$_[0]->as_string().'", request that caused this response = "'	. $response->request()->as_string.'", response code = "', $response->code(),'" = "'.$response->message.'", response as string = "'.$response->as_string. q(") ; }
#	my $browser = HTML::Display->new(class => 'HTML::Display::Win32::IE',); # this will open a new window for every page of html! 
#    $browser->display(html => $response->content);   # for testing to see the web pages 
	return $response; 	
} 

sub login {
	my $self = shift;    # pass $self, then optionally the office whose terms you need, or use that office set in $self
	my $username = shift || $self->{'patent'}->{'office_username'};
	my $password = shift || $self->{'patent'}->{'office_password'};
	my $login    = $self->{'patent'}->{'office'} . '_login';

	#	print $login ;
	my $function_reference = $METHODS{$login};

	#	print $$function_reference ;
	return &{$function_reference}($self, $username, $password);
}
sub _agent {return "WWW::Patent::Page/$WWW::Patent::Page::VERSION"}

sub _load_modules {
	my ($class, @modules) = (@_);    # pass a list of the modules that will be available;
	                                 # add more to your call for this, for custom modules for other patent offices
	my $baseclass = ref $class || $class;

	# Go to each module and use them.  Also record what methods
	# they support and enter them into the %METHODS hash.
	foreach my $module (@modules) {
		my $modpath = "${baseclass}::${module}";
		if (!defined $MODULES{$modpath}) {    # unless already visited
			                                  # Have to use an eval here because perl doesn't like to use strings.
			eval "use $modpath;";
			if ($EVAL_ERROR) {carp $EVAL_ERROR}
			$MODULES{$modpath} = 1;

			# Methodhash will continue method-name, function ref
			# pairs.
			my %methodhash = $modpath->methods;
			my ($method, $value);
			while (($method, $value) = each %methodhash) {
				$METHODS{$method} = $value;
			}
		}
	}
	return;
}

sub _load_country_known {

	# from HANDBOOK ON INDUSTRIAL PROPERTY INFORMATION AND DOCUMENTATION
	# Standard ST.3
	# see http://www.wipo.int/scit/en/standards/pdf/03-03-01.pdf
	# these codes reflect the versions used since 1978
	# e.g. Algeria used to be AG, which is now Antigua, and Algeria is DZ.
	# where no conflicts exist, antiquated codes are included
	# such as CS for Czechoslovakia along with CZ for Czech Republic
	# and SU for Soviet Union.
	# Conflicts exist for International Patent Institute IB
	# and Democratic Yemen SY
	# see below for list by country, alphabetical
	return (
		'AE' => 'United Arab Emirates',
		'AF' => 'Afghanistan',
		'AG' => 'Antigua and Barbuda',
		'AI' => 'Anguilla',
		'AL' => 'Albania',
		'AM' => 'Armenia',
		'AN' => 'Netherlands Antilles',
		'AO' => 'Angola',
		'AP' => 'African Regional Intellectual Property Organization',
		'AR' => 'Argentina',
		'AT' => 'Austria',
		'AU' => 'Australia',
		'AW' => 'Aruba',
		'AZ' => 'Azerbaijan',
		'BA' => 'Bosnia and Herzegovina',
		'BB' => 'Barbados',
		'BD' => 'Bangladesh',
		'BE' => 'Belgium',
		'BF' => 'Burkina Faso',
		'BG' => 'Bulgaria',
		'BH' => 'Bahrain',
		'BI' => 'Burundi',
		'BJ' => 'Benin',
		'BM' => 'Bermuda',
		'BN' => 'Brunei Darussalam',
		'BO' => 'Bolivia',
		'BR' => 'Brazil',
		'BS' => 'Bahamas',
		'BT' => 'Bhutan',
		'BV' => 'Bouvet Island',
		'BW' => 'Botswana',
		'BX' => 'Benelux Trademark Office',
		'BY' => 'Belarus',
		'BZ' => 'Belize',
		'CA' => 'Canada',
		'CD' => 'Democratic Republic of the Congo',
		'CF' => 'Central African Republic',
		'CG' => 'Congo',
		'CH' => 'Switzerland',
		'CI' => 'Côte d’Ivoire',
		'CK' => 'Cook Islands',
		'CL' => 'Chile',
		'CM' => 'Cameroon',
		'CN' => 'China',
		'CO' => 'Colombia',
		'CR' => 'Costa Rica',
		'CS' => 'Czechoslovakia',
		'CU' => 'Cuba',
		'CV' => 'Cape Verde',
		'CY' => 'Cyprus',
		'CZ' => 'Czech Republic',
		'DD' => 'Germany (Democratic Republic)',
		'DE' => 'Germany',
		'DJ' => 'Djibouti',
		'DK' => 'Denmark',
		'DL' => 'Germany (Democratic Republic)',
		'DM' => 'Dominica',
		'DO' => 'Dominican Republic',
		'DZ' => 'Algeria',
		'EA' => 'Eurasian Patent Organization',
		'EC' => 'Ecuador',
		'EE' => 'Estonia',
		'EG' => 'Egypt',
		'EH' => 'Western Sahara',
		'EM' => 'Office for Harmonization in the Internal Market',
		'EP' => 'European Patent Office',
		'ER' => 'Eritrea',
		'ES' => 'Spain',
		'ET' => 'Ethiopia',
		'FI' => 'Finland',
		'FJ' => 'Fiji',
		'FK' => 'Falkland Islands (Malvinas)',
		'FO' => 'Faroe Islands',
		'FR' => 'France',
		'GA' => 'Gabon',
		'GB' => 'United Kingdom',
		'GC' => 'Patent Office of the Cooperation Council for the Arab States of the Gulf',
		'GD' => 'Grenada',
		'GE' => 'Georgia',
		'GG' => 'Guernsey',
		'GH' => 'Ghana',
		'GI' => 'Gibraltar',
		'GL' => 'Greenland',
		'GM' => 'Gambia',
		'GN' => 'Guinea',
		'GQ' => 'Equatorial Guinea',
		'GR' => 'Greece',
		'GS' => 'South Georgia and the South Sandwich Islands',
		'GT' => 'Guatemala',
		'GW' => 'Guinea-Bissau',
		'GY' => 'Guyana',
		'HK' => 'The Hong Kong Special Administrative Region of the People’s Republic of China',
		'HN' => 'Honduras',
		'HR' => 'Croatia',
		'HT' => 'Haiti',
		'HU' => 'Hungary',
		'IB' => 'International Bureau of the World Intellectual Property Organization',
		'ID' => 'Indonesia',
		'IE' => 'Ireland',
		'IL' => 'Israel',
		'IM' => 'Isle of Man',
		'IN' => 'India',
		'IQ' => 'Iraq',
		'IR' => 'Iran (Islamic Republic of)',
		'IS' => 'Iceland',
		'IT' => 'Italy',
		'JE' => 'Jersey',
		'JM' => 'Jamaica',
		'JO' => 'Jordan',
		'JP' => 'Japan',
		'KE' => 'Kenya',
		'KG' => 'Kyrgyzstan',
		'KH' => 'Cambodia',
		'KI' => 'Kiribati',
		'KM' => 'Comoros',
		'KN' => 'Saint Kitts and Nevis',
		'KP' => 'Democratic People’s Republic of Korea',
		'KR' => 'Republic of Korea',
		'KW' => 'Kuwait',
		'KY' => 'Cayman Islands',
		'KZ' => 'Kazakhstan',
		'LA' => 'Lao People’s Democratic Republic',
		'LB' => 'Lebanon',
		'LC' => 'Saint Lucia',
		'LI' => 'Liechtenstein',
		'LK' => 'Sri Lanka',
		'LR' => 'Liberia',
		'LS' => 'Lesotho',
		'LT' => 'Lithuania',
		'LU' => 'Luxembourg',
		'LV' => 'Latvia',
		'LY' => 'Libyan Arab Jamahiriya',
		'MA' => 'Morocco',
		'MC' => 'Monaco',
		'MD' => 'Republic of Moldova',
		'ME' => 'Montenegro',
		'MG' => 'Madagascar',
		'MK' => 'The former Yugoslav Republic of Macedonia',
		'ML' => 'Mali',
		'MM' => 'Myanmar',
		'MN' => 'Mongolia',
		'MO' => 'Macao',
		'MP' => 'Northern Mariana Islands',
		'MR' => 'Mauritania',
		'MS' => 'Montserrat',
		'MT' => 'Malta',
		'MU' => 'Mauritius',
		'MV' => 'Maldives',
		'MW' => 'Malawi',
		'MX' => 'Mexico',
		'MY' => 'Malaysia',
		'MZ' => 'Mozambique',
		'NA' => 'Namibia',
		'NE' => 'Niger',
		'NG' => 'Nigeria',
		'NI' => 'Nicaragua',
		'NL' => 'Netherlands',
		'NO' => 'Norway',
		'NP' => 'Nepal',
		'NR' => 'Nauru',
		'NZ' => 'New Zealand',
		'OA' => 'African Intellectual Property Organization',
		'OM' => 'Oman',
		'PA' => 'Panama',
		'PE' => 'Peru',
		'PG' => 'Papua New Guinea',
		'PH' => 'Philippines',
		'PK' => 'Pakistan',
		'PL' => 'Poland',
		'PT' => 'Portugal',
		'PW' => 'Palau',
		'PY' => 'Paraguay',
		'QA' => 'Qatar',
		'QZ' => 'Community Plant Variety Office (European Community) (CPVO)',
		'RO' => 'Romania',
		'RS' => 'Serbia',
		'RU' => 'Russian Federation',
		'RW' => 'Rwanda',
		'SA' => 'Saudi Arabia',
		'SB' => 'Solomon Islands',
		'SC' => 'Seychelles',
		'SD' => 'Sudan',
		'SE' => 'Sweden',
		'SG' => 'Singapore',
		'SH' => 'Saint Helena',
		'SI' => 'Slovenia',
		'SK' => 'Slovakia',
		'SL' => 'Sierra Leone',
		'SM' => 'San Marino',
		'SN' => 'Senegal',
		'SO' => 'Somalia',
		'SR' => 'Suriname',
		'ST' => 'Sao Tome and Principe',
		'SU' => 'Soviet Union',
		'SV' => 'El Salvador',
		'SY' => 'Syrian Arab Republic',
		'SZ' => 'Swaziland',
		'TC' => 'Turks and Caicos Islands',
		'TD' => 'Chad',
		'TG' => 'Togo',
		'TH' => 'Thailand',
		'TJ' => 'Tajikistan',
		'TL' => 'Timor–Leste',
		'TM' => 'Turkmenistan',
		'TN' => 'Tunisia',
		'TO' => 'Tonga',
		'TR' => 'Turkey',
		'TT' => 'Trinidad and Tobago',
		'TV' => 'Tuvalu',
		'TW' => 'Taiwan, Province of China',
		'TZ' => 'United Republic of Tanzania',
		'UA' => 'Ukraine',
		'UG' => 'Uganda',
		'US' => 'United States of America',
		'UY' => 'Uruguay',
		'UZ' => 'Uzbekistan',
		'VA' => 'Holy See',
		'VC' => 'Saint Vincent and the Grenadines',
		'VE' => 'Venezuela',
		'VG' => 'Virgin Islands (British)',
		'VN' => 'Viet Nam',
		'VU' => 'Vanuatu',
		'WO' => 'World Intellectual Property Organization',
		'WS' => 'Samoa',
		'YD' => 'Yemen (Democratic)',
		'YE' => 'Yemen',
		'ZA' => 'South Africa',
		'ZM' => 'Zambia',
		'ZW' => 'Zimbabwe',
	);

	# alphabetical by country
	# Afghanistan  _  AF
	# African Intellectual Property Organization  _  OA
	# African Regional Intellectual Property Organization  _  AP
	# Albania  _  AL
	# Algeria  _  DZ
	# Angola  _  AO
	# Anguilla  _  AI
	# Antigua and Barbuda  _  AG
	# Argentina  _  AR
	# Armenia  _  AM
	# Aruba  _  AW
	# Australia  _  AU
	# Austria  _  AT
	# Azerbaijan  _  AZ
	# Bahamas  _  BS
	# Bahrain  _  BH
	# Bangladesh  _  BD
	# Barbados  _  BB
	# Belarus  _  BY
	# Belgium  _  BE
	# Belize  _  BZ
	# Benelux Trademark Office  _  BX
	# Benin  _  BJ
	# Bermuda  _  BM
	# Bhutan  _  BT
	# Bolivia  _  BO
	# Bosnia and Herzegovina  _  BA
	# Botswana  _  BW
	# Bouvet Island  _  BV
	# Brazil  _  BR
	# Brunei Darussalam  _  BN
	# Bulgaria  _  BG
	# Burkina Faso  _  BF
	# Burundi  _  BI
	# Cambodia  _  KH
	# Cameroon  _  CM
	# Canada  _  CA
	# Cape Verde  _  CV
	# Cayman Islands  _  KY
	# Central African Republic  _  CF
	# Chad  _  TD
	# Chile  _  CL
	# China  _  CN
	# Colombia  _  CO
	# Community Plant Variety Office (European Community) (CPVO)  _  QZ
	# Comoros  _  KM
	# Congo  _  CG
	# Cook Islands  _  CK
	# Costa Rica  _  CR
	# Croatia  _  HR
	# Cuba  _  CU
	# Cyprus  _  CY
	# Czech Republic  _  CZ
	# Czechoslovakia  _  CS
	# Côte d’Ivoire  _  CI
	# Democratic People’s Republic of Korea  _  KP
	# Democratic Republic of the Congo  _  CD
	# Denmark  _  DK
	# Djibouti  _  DJ
	# Dominica  _  DM
	# Dominican Republic  _  DO
	# Ecuador  _  EC
	# Egypt  _  EG
	# El Salvador  _  SV
	# Equatorial Guinea  _  GQ
	# Eritrea  _  ER
	# Estonia  _  EE
	# Ethiopia  _  ET
	# Eurasian Patent Organization  _  EA
	# European Patent Office  _  EP
	# Falkland Islands (Malvinas)  _  FK
	# Faroe Islands  _  FO
	# Fiji  _  FJ
	# Finland  _  FI
	# France  _  FR
	# Gabon  _  GA
	# Gambia  _  GM
	# Georgia  _  GE
	# Germany  _  DE
	# Germany (Democratic Republic)  _  DD
	# Germany (Democratic Republic)  _  DL
	# Ghana  _  GH
	# Gibraltar  _  GI
	# Greece  _  GR
	# Greenland  _  GL
	# Grenada  _  GD
	# Guatemala  _  GT
	# Guernsey  _  GG
	# Guinea  _  GN
	# Guinea-Bissau  _  GW
	# Guyana  _  GY
	# Haiti  _  HT
	# Holy See  _  VA
	# Honduras  _  HN
	# Hungary  _  HU
	# Iceland  _  IS
	# India  _  IN
	# Indonesia  _  ID
	# International Bureau of the World Intellectual Property Organization  _  IB
	# Iran (Islamic Republic of)  _  IR
	# Iraq  _  IQ
	# Ireland  _  IE
	# Isle of Man  _  IM
	# Israel  _  IL
	# Italy  _  IT
	# Jamaica  _  JM
	# Japan  _  JP
	# Jersey  _  JE
	# Jordan  _  JO
	# Kazakhstan  _  KZ
	# Kenya  _  KE
	# Kiribati  _  KI
	# Kuwait  _  KW
	# Kyrgyzstan  _  KG
	# Lao People’s Democratic Republic  _  LA
	# Latvia  _  LV
	# Lebanon  _  LB
	# Lesotho  _  LS
	# Liberia  _  LR
	# Libyan Arab Jamahiriya  _  LY
	# Liechtenstein  _  LI
	# Lithuania  _  LT
	# Luxembourg  _  LU
	# Macao  _  MO
	# Madagascar  _  MG
	# Malawi  _  MW
	# Malaysia  _  MY
	# Maldives  _  MV
	# Mali  _  ML
	# Malta  _  MT
	# Mauritania  _  MR
	# Mauritius  _  MU
	# Mexico  _  MX
	# Monaco  _  MC
	# Mongolia  _  MN
	# Montenegro  _  ME
	# Montserrat  _  MS
	# Morocco  _  MA
	# Mozambique  _  MZ
	# Myanmar  _  MM
	# Namibia  _  NA
	# Nauru  _  NR
	# Nepal  _  NP
	# Netherlands  _  NL
	# Netherlands Antilles  _  AN
	# New Zealand  _  NZ
	# Nicaragua  _  NI
	# Niger  _  NE
	# Nigeria  _  NG
	# Northern Mariana Islands  _  MP
	# Norway  _  NO
	# Office for Harmonization in the Internal Market  _  EM
	# Oman  _  OM
	# Pakistan  _  PK
	# Palau  _  PW
	# Panama  _  PA
	# Papua New Guinea  _  PG
	# Paraguay  _  PY
	# Patent Office of the Cooperation Council for the Arab States of the Gulf  _  GC
	# Peru  _  PE
	# Philippines  _  PH
	# Poland  _  PL
	# Portugal  _  PT
	# Qatar  _  QA
	# Republic of Korea  _  KR
	# Republic of Moldova  _  MD
	# Romania  _  RO
	# Russian Federation  _  RU
	# Rwanda  _  RW
	# Saint Helena  _  SH
	# Saint Kitts and Nevis  _  KN
	# Saint Lucia  _  LC
	# Saint Vincent and the Grenadines  _  VC
	# Samoa  _  WS
	# San Marino  _  SM
	# Sao Tome and Principe  _  ST
	# Saudi Arabia  _  SA
	# Senegal  _  SN
	# Serbia  _  RS
	# Seychelles  _  SC
	# Sierra Leone  _  SL
	# Singapore  _  SG
	# Slovakia  _  SK
	# Slovenia  _  SI
	# Solomon Islands  _  SB
	# Somalia  _  SO
	# South Africa  _  ZA
	# South Georgia and the South Sandwich Islands  _  GS
	# Soviet Union  _  SU
	# Spain  _  ES
	# Sri Lanka  _  LK
	# Sudan  _  SD
	# Suriname  _  SR
	# Swaziland  _  SZ
	# Sweden  _  SE
	# Switzerland  _  CH
	# Syrian Arab Republic  _  SY
	# Taiwan, Province of China  _  TW
	# Tajikistan  _  TJ
	# Thailand  _  TH
	# The Hong Kong Special Administrative Region of the People’s Republic of China  _  HK
	# The former Yugoslav Republic of Macedonia  _  MK
	# Timor–Leste  _  TL
	# Togo  _  TG
	# Tonga  _  TO
	# Trinidad and Tobago  _  TT
	# Tunisia  _  TN
	# Turkey  _  TR
	# Turkmenistan  _  TM
	# Turks and Caicos Islands  _  TC
	# Tuvalu  _  TV
	# Uganda  _  UG
	# Ukraine  _  UA
	# United Arab Emirates  _  AE
	# United Kingdom  _  GB
	# United Republic of Tanzania  _  TZ
	# United States of America  _  US
	# Uruguay  _  UY
	# Uzbekistan  _  UZ
	# Vanuatu  _  VU
	# Venezuela  _  VE
	# Viet Nam  _  VN
	# Virgin Islands (British)  _  VG
	# Western Sahara  _  EH
	# World Intellectual Property Organization  _  WO
	# Yemen  _  YE
	# Yemen (Democratic)  _  YD
	# Zambia  _  ZM
	# Zimbabwe  _  ZW

}

1;    #this line is important and will help the module return a true value
__END__

=head1 NAME

WWW::Patent::Page - get patent documents
from WWW source (e.g. 
( not available: JP->Eng translations in HTML from JPO,) 
complete US applications and grants from 
(USPTO), and place into a WWW::Patent::Page::Response object)
(note: ESPACE_EP not provided due to captcha use..)

=head1 VERSION

This document describes WWW::Patent::Page version 0.100.0 of February, 2007.

=head1 SYNOPSIS

Please see the test suite for working examples in t/ .  The following is not guaranteed to be working or up-to-date.

THE ONLY OFFICE CURRENTLY WORKING IS THE USPTO.

  $ perl -I. -MWWW::Patent::Page -e 'print $WWW::Patent::Page::VERSION,"\n"'
  0.02

  $ perl get_patent.pl US6123456 > US6123456.pdf &

  $ perl -wT get_JPO_patent_translation_to_english.pl "JPH09-123456A" > JPH09-123456A.zip & 
  
  ( see examples/JPH09-123456A.zip for an html formatted, machine translated, Japanese patent document. ) 

  (command line interfaces are included in examples/ )

  http://www.yourdomain.com/www_get_patent_pdf.pl
  http://www.yourdomain.com/www_get_JPO_patent_translation_to_english.pl

  (web fetchers are included in examples/ )

Typical usage in perl code:

  use WWW::Patent::Page;

  print $WWW::Patent::Page::VERSION,"\n";

  my $patent_browser = WWW::Patent::Page->new(); # new object

  my $document1 = $patent_document->get_page('6,123,456');
  	# defaults:
	# 	    country => 'US',
	#	    format 	=> 'pdf',
	#		page   	=> undef ,
	# and usual defaults of LWP::UserAgent (subclassed)

  my $document2 = $patent_document->get_page('US6123456',
			format 	=> 'pdf',
			page   	=> 2 ,  #get only the second page
			);

  my $pages_known = $document2->get_parameter('pages');  #how many total pages known?

=head1 DESCRIPTION

  Intent:  Use public sources to retrieve patent documents such as
  TIFF images of patent pages, html of patents, pdf, etc.
  Expandable for your office of interest by writing new submodules..
  Alpha release by newbie to find if there is any interest

=head1 USAGE

  See also SYNOPSIS above

     Standard process for building & installing modules:

          perl Build.PL
          ./Build
          ./Build test verbose=1
          ./Build install

          or

          perl Makefile.PL
          make
          make test TEST_VERBOSE=1
          make install
  
          or on ActiveState or otherwise using nmake
          
          perl Makefile.PL
          nmake
          nmake test TEST_VERBOSE=1
          nmake install

Examples of use:

  $patent_browser = WWW::Patent::Page->new(
  			doc_id	=> 'US6,654,321',
			format 	=> 'pdf',
			page   	=> undef ,  # returns all pages in one pdf
			agent   => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
			);

	$patent_response = $patent_browser->get_patent('US6,654,321(B2)issued_2_Okada');

=head1 INTERFACE

Object oriented, and modelled on LWP.

=head1 SUBROUTINES/METHODS

=head2 new

NEW instance of the Page class, subclassing LWP::UserAgent

=cut

=head2 login

login to a server to use its services; obtain a token or session id or the like

=cut

=head2 country_known

country_known maps the known two letter acronyms to patenting entities, usually countries; country_known returns undef if the two letter acronym is not recognized.

=cut

=head2 parse_doc_id

Takes a human readable patent/publication identifier and parses it into country/entity, kind, number, doc_type, ...

     CC[TY]##,###,###(K#)_Comments

     US_6,123,456_A1_-comments

     CC : Two letter country/entity code; e.g. US, EP, WO
     TY  : Type of document; one or two letters only of these choices:
		e.g. in US, Kind = Utility is default and no "Kind" is used, e.g. US6123456
		D : Design, e.g. USD339,456
		PP: Plant, e.g. USPP8,901
		RE: Reissue, e.g. USRE35,312
		T : Defensive Publication, e.g. UST109,201
		SIR: Statutory Invention Registration, e.g. USH1,523
      ##,###,### Document number (e.g. patent number or application number- only digits and optionally separators, no letters)
      K# : the kind or version number, e.g. A1, B2, etc.; placed in parenthesis- at least one letter and at most one number.  Not always used in document fetching.
      Comments:  retained but not used- single string of word characters \w = A-z0-9_ (no spaces, "-", commas, etc.)

      Separators (comma, space, dash, underscore) may occur between entries, and at least one MUST occur before a comment (due to difficulty of parsing the kind code which might be one letter).
      Separators (the comma is handy) may occur within the number

As of version 0.1, the parsed result used at the office of choice is placed in
$self->patent->doc_id_standardized

A convenience value of
$self->patent->doc_id_commified
is provided.

In recognizing the values such as CC country, the priority is:

 $self->patent->doc_id as supplied; if absent:
 $self->patent->country; if absent:
 $WWW::Patent::Page::default_country

=cut

=head2 get_page

method to use the modules specific to Offices like USPTO, with methods for each document/page format, etc., and
LWP::Agent to grab the appropriate URLs and if necessary build the response content or produce error values

=cut

=head2 request

Method to override the LWP::UserAgent::request that gets a URL.
This calls LWP::UserAgent::request itself, but around it adds things like a retry (and possibly debugging, like throwing pages to a browser for display). 

=cut


=head2 terms

method to provide a summary or pointers to the terms and conditions of use of the publicly available databases

=head2 _load_modules

internal private method to access helper modules in WWW::Patent::Page

=cut

=head2 _agent

private method to assign default agent

=cut

=head2 _load_country_known

private method to load a big hash and allow it to be folded during code development.

=cut


=head1 DIAGNOSTICS

The accepted tactic is to set $self->{'is_success'} or $self->{'patent'}->{'is_success'} to false and add a message to $self->{'message'} or $self->{'patent'}->{'message'}

=head1 CONFIGURATION AND ENVIRONMENT

WWW::Patent::Page requires no configuration files or environment variables.

WWW::Patent::Page makes use of LWP environmental variables such as HTTP_PROXY.

=head1 DEPENDENCIES

LWP::UserAgent
HTTP::Response

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Code contributions, suggestions, and critiques are welcome.

Error handling is undeveloped.

By definition, a non-trivial program contains bugs.

For United States Patents (US) via the USPTO (USPTO), the 'kind' is ignored in method provide_doc


=head1 AUTHOR

	Wanda B. Anon
	Wanda.B.Anon@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Wanda B. Anon wanda.b.anon@GMAIL.com . 
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the Artistic License version 2.0 
or above ( http://www.perlfoundation.org/artistic_license_2_0 ) .

=head1 ACKNOWLEDGEMENTS

Hermann Schier, Lokkju, Andy Lester,
the authors of Finance::Quote, Erik Oliver for patentmailer, Howard P. Katseff of AT&T Laboratories for wsp.pl, version 2,
a proxy that speaks LWP and understands proxies, and of course Larry and Randal and the gang.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

