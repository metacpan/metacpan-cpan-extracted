package WWW::Mechanize::Chrome::Webshot;

#### warning, size is 100,100 and not 100x100!!!

use 5.006;
use strict;
use warnings;

#use Exporter qw(import);
#our @EXPORT = qw(
#	_check_if_exif_tags_exist_in_image
#);

our $VERSION = '0.05';

use Log::Log4perl qw(:easy);
# >= v5.31 which supports EXIF for png files
use Image::ExifTool qw/ :Public /;
use WWW::Mechanize::Chrome;
use Encode qw/encode_utf8 decode_utf8/;
use Mojo::Log;
use FindBin;
use Config::JSON::Enhanced;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
use WWW::Mechanize::Chrome::DOMops qw/
	domops_zap
	$domops_VERBOSITY
	$domops_LOGGER
/;

# a basic default configuration file in enhanced JSON (see L<Config::JSON::Enhanced>)
my $DEFAULT_CONFIGSTRING = <<'EOCS';
</* $VERSION = '0.05'; */>
</* comments are allowed */>
</* and <% vars %> and <% verbatim sections %> */>
{
	"debug" : {
		"verbosity" : 1,
		</* cleanup temp files on exit */>
		"cleanup" : 1
	},
	"logger" : {
		</* log to file if you uncomment this */>
		</* "filename" : "..." */>
	},
	"constructor" : {
		</* for slow connections */>
	        "settle-time" : "3",
       		"resolution" : "1600x1200",
       		"stop-on-error" : "0",
       		"remove-dom-elements" : []
	},
	"WWW::Mechanize::Chrome" : {
		"headless" : "1",
		"launch_arg" : [
			</* this will change as per the 'resolution' setting above */>
			"--window-size=600x800",
			"--password-store=basic", </* do not ask me for stupid chrome account password */>
		</*	"--remote-debugging-port=9223", */>
		</*	"--enable-logging", */>
			"--disable-gpu",
		</*	"--no-sandbox", NO LONGER VALID */>
			"--ignore-certificate-errors",
			"--disable-background-networking",
			"--disable-client-side-phishing-detection",
			"--disable-component-update",
			"--disable-hang-monitor",
			"--disable-save-password-bubble",
			"--disable-default-apps",
			"--disable-infobars",
			"--disable-popup-blocking"
		]
	}
}
EOCS

sub	new {
	my $class = $_[0];
	my $params = $_[1]; # a hash of params, see below

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $self = {
		'_private' => {
			'confighash' => undef,
			'configfile' => '', # this should never be undef
			'debug' => {
				'verbosity' => 0,
				'cleanup' => 1,
			},
			'log' => {
				'logger-object' => undef,
				'logfile' => undef
			},
			'settle-time' => 5,
			'resolution' => '1000,1002', # not x but , !!!
			'stop-on-error' => 0,
			'remove-dom-elements' => [],
			# this is a global exif metadata to be set
			# each time we shoot() UNLESSS shoot()'s
			# params have their own, in which case this is not used:
			'exif' => undef,
			# this may be instantiated lazily,
			# when needed as mech is expensive to load
			# or it can be passed on to us via the constructor
			'WWW::Mechanize::Chrome-object' => undef,
			# these are the final mech params,
			# from confighash and user-specified $params
			'WWW::Mechanize::Chrome-params' => undef,
		}
	};
	bless $self => $class;

	# this will read configuration and create confighash,
	# make logger, verbosity,
	# instantiate any objects we need here etc.
	if( $self->init($params) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, call to init() has failed.\n"; return undef }

	# Now we have a logger
	my $log = $self->log();

	# do module-specific init like instantiating the mech, unless params has 'launch-mech-on-demand'=>1
	if( $self->init_module_specific($params) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to init_module_specific() has failed."); return undef }

	my $verbosity = $self->verbosity;
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : done, success (verbosity is set to ".$self->verbosity." and cleanup to ".$self->cleanup.").") }

	return $self;
}

# blank the browser
sub	blank_browser { $_[0]->mech_obj->get('about:blank'); $_[0]->mech_obj->sleep(1); }

# hits the page, waits for some settle-time, removes some elements from the DOM,
# if asked, that obstruct the shot, e.g. banners and dumps the browser's window
# to a PNG or PDF file (whose filename must be supplied as input param).
# NOTE: PDF output does not seem to contain the whole browser content!
# it has a preset size.
# optional 'remove-dom-elements' overwrites the self if any
# optional 'exif' parameter (as hash) specifies tag/value pairs to be inserted as
# metadata into the final output image
# { k => v, ... }
# exif tagnames have restrictions: no unicode, no spaces, not ':'
# returns 0 on failure
# returns 1 on success
sub	shoot {
	my $self = $_[0];
	my $params = $_[1]; # a hashref of 'output-filename', 'url' etc.
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $verbos = $self->verbosity;
	my $log = $self->log;

	# this is required
	my $outfile = exists($params->{'output-filename'}) ? $params->{'output-filename'} : undef;
	if( ! defined $outfile ){ $log->error("$whoami (via $parent), line ".__LINE__." : error, 'output-filename' parameter was not specified."); return 0 }

	my $outformat;
	if( exists($params->{'output-format'}) && defined($params->{'output-format'}) ){
		if( $params->{'output-format'} =~ /^(png|pdf)$/ ){ $outformat = $1 }
		else { $log->error("$whoami (via $parent), line ".__LINE__." : error, parameter 'output-format' was specified as '".$params->{'output-format'}."' but one of 'png' or 'pdf' was expected."); return 0 }
	} else {
		# try and deduce the format from the file extension
		if( $outfile =~ /\.(pdf|png)$/i ){ $outformat = $1 }
		else { $log->error("$whoami (via $parent), line ".__LINE__." : error, parameter 'output-format' was not specified and failed to deduce the output format from the specified output filename ($outfile). Either specify 'output-format' as one of 'png' or 'pdf' or make the 'output-filename' clearer."); return 0 }
	}

	# this is optional, because mech already may be in current page
	# if you will use URI for local file (file://...) then
	# USE ABSOLUTE FILEPATH
	my $URL = exists($params->{'url'}) ? $params->{'url'} : undef;

	# optional or default
	my $stoperr = (exists($params->{'stop-on-error'}) && defined($params->{'stop-on-error'}))
		? $params->{'stop-on-error'}
		: $self->stop_on_error()
	;

	# optional
	my $remove_dom_elements = (exists($params->{'remove-dom-elements'}) && defined($params->{'remove-dom-elements'}))
		? $params->{'remove-dom-elements'}
		: (exists($self->{'_private'}->{'remove-dom-elements'}) && defined($self->{'_private'}->{'remove-dom-elements'}))
			? $self->{'_private'}->{'remove-dom-elements'}
			: undef
	;

	# optional
	my $exif;
	if( exists($params->{'exif'}) && defined($params->{'exif'}) ){
		$exif = $params->{'exif'};
	} elsif( exists($self->{'_private'}->{'exif'}) && defined($self->{'_private'}->{'exif'}) && (scalar(keys %{ $self->{'_private'}->{'exif'} })>0) ){
		$exif = $self->{'_private'}->{'exif'};
	}
	if( defined $exif ){
		# check that the exif data format is valid : { k => v, ... }
		if( ref($exif)ne'HASH' ){ $log->error("$whoami (via $parent), line ".__LINE__." : error, 'exif' parameter expects a HASH of tagname => tagvalue pairs, not ".ref($exif)."."); return 0; }
	}

	# here we can check if we have a mech instantiated or not
	# if there is no mech, we WARN if no URL was specified!
	# where is it going to go? to the homepage of the browser, that's all
	# we are instantiating the mech, if no url was specified then what to print? perhaps homepage?
	if( ! defined($self->{'_private'}->{'WWW::Mechanize::Chrome-object'})
	 && ! defined($URL)
	){ $log->info("$whoami (via $parent), line ".__LINE__." : warning, mech is being instantiated now but there was no 'url' parameter specified, are you sure?") }

	my $mech = $self->mech_obj;

	# if 2 consecutive urls have the same path (except the params) then we get stuck
	# with error  Page.navigatedWithinDocument
	# see https://perlmonks.org/?node_id=1219646
	# let's see if this bug appears again, we need to operate even without URL
	# perhaps mech page is already in a satate and don't want to move out and in again!
	#$self->blank_browser();

	# and then get the page
	if( defined($URL) && ! $mech->get($URL) ){ $log->error("$whoami (via $parent), line ".__LINE__." : call to ".'get()'." has failed for url: $URL"); return 0 }

	# move by nothing in order to load images
	$self->scroll(0,0);

	# sleep a second or two till it gets settled
	if( $verbos > 0 ){ $log->info("$whoami (via $parent), line ".__LINE__." : allowing settle time of ".$self->{'settle-time'}." seconds."); }
	sleep($self->settle_time());
	if( $verbos > 0 ){ $log->info("$whoami (via $parent), line ".__LINE__." : woke up after settle time of ".$self->{'settle-time'}." seconds."); }

	# move by nothing in order to load images
	$self->scroll(0,0);

	# do we have any elements to remove?
	if( defined $remove_dom_elements ){
		foreach my $anentry (@$remove_dom_elements){
			if( ! defined $anentry ){
				if( $verbos > 0 ){ $log->info("$whoami (via $parent), line ".__LINE__." : found undef in array of 'remove-dom-elements' which signifies that I should skip the rest (if any)."); }
				# any undef in the array is a signal to skip the rest
				last
			}
			if( $verbos > 0 ){ $log->info("$whoami (via $parent), line ".__LINE__." : removing DOM element(s):\n".perl2dump($anentry)); }
			my %delparms = (
				%$anentry,
				'mech-obj' => $mech,
			);
			my $zapret = WWW::Mechanize::Chrome::DOMops::domops_zap(\%delparms);
			if( $zapret->{'status'} < 0 ){ 
				$log->error(perl2dump($zapret)."$whoami (via $parent), line ".__LINE__." : call to ".'WWW::Mechanize::Chrome::DOMOps::domops_zap()'." has failed, with above error, for these parameters:\n".perl2dump($anentry)."\n---end of parameters.");
				if( $stoperr > 0 ){
					$log->error("$whoami (via $parent), line ".__LINE__." : stopping now because 'stop-on-error' was set.");
					return 0 # do not continue if error!
				} else { next }
			}
			if( $verbos > 1 ){ $log->info("$whoami (via $parent), line ".__LINE__." : done zapped DOM element :\n".perl2dump($anentry)) }
		}
	}

	# settle for a bit before taking the screenshot
	sleep($self->settle_time());

	if( $verbos > 0 ){ $log->info("$whoami (via $parent), line ".__LINE__." : taking a screenshot and dumping it to file '$outfile' ...") }

	# smile!!! (or say cheese)
	my $fh;
	if( ! open $fh, '>:raw', $outfile ){ $log->error("$whoami (via $parent), line ".__LINE__." : error, failed to open file '$outfile' for writing, $!"); return 0 }
	print $fh ($outformat eq 'pdf' ? $mech->content_as_pdf(format=>'A4') : $mech->content_as_png());
	close $fh;

	if( $exif ){
		# WARNING: exif keys do not like unicode,
		# neither special chars (space, '::' etc.)
		# exif values can have anything, including unicode

		# if caller supplied exif as an ARRAY, then here we go
		# { k => v, ... }

		my $exifTool = Image::ExifTool->new();
		if( ! defined $exifTool ){
			$log->error("$whoami (via $parent), line ".__LINE__." : error, failed to instantiate an ".'Image::ExifTool'." object. Continuing with the rest - output is saved but exif data will be missing ...");
			goto FINISH; # mummy look! they are using gotos!!!
		}
		# Add custom user-defined tags:
		# Gosh! https://exiftool.org/forum/index.php?topic=7377.0
		my %tagnames = map { $_ => { Name => $_, Writable => 'string' } } keys %$exif;
		%Image::ExifTool::UserDefined = ( 'Image::ExifTool::XMP::xmp' => { %tagnames } );

		for my $tn (keys %$exif){
			my $tv = $exif->{$tn};
			my @rs = $exifTool->SetNewValue($tn, $tv);
			if( $rs[0] == 0 ){ $log->error("$whoami (via $parent), line ".__LINE__." : error, failed to add tag '${tn}' => '${tv}', ignoring this error and continuing with the rest - output is saved but exif data may be missing. Error: ".$rs[1]."") }
		}
		my $ws = $exifTool->WriteInfo($outfile);
		if( $ws == 0 ){ $log->error(perl2dump($exif)."$whoami (via $parent), line ".__LINE__." : error, failed to write above EXIF data to output file '$outfile'. Ignoring this and continuing with the rest - output is saved but exif data will be missing ...") }
		elsif( $ws == 2 ){ $log->error(perl2dump($exif)."$whoami (via $parent), line ".__LINE__." : warning, there were no EXIF data changes to be written to the output file '$outfile' (see the data above). None of the user-specified exif data seems to have been written because there was probably none.") }

		# do a check? if not paranoid, comment this out:
		my $have_errors = 0;
		my $retc = WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image($outfile, $exif, $log);
		if( ! defined($retc) ){ $log->error("$whoami (via $parent), line ".__LINE__." : warning, call to ".'_check_if_exif_tags_exist_in_image()'." has failed. Ignoring this error and continuing with the rest - output is saved but exif data may be missing ...") }
		else {
			for my $tn (keys %$exif){
				if( ! exists($retc->{$tn}) ){ $log->error("$whoami (via $parent), line ".__LINE__." : warning, tagname '${tn}' is not contained in the output image as it should."); $have_errors = 1 }
				if( $retc->{$tn} == 0 ){ $log->error("$whoami (via $parent), line ".__LINE__." : warning, tagname '${tn}' is not contained in the output image. Ignoring this and continuing with the rest - output is saved but exif data may be missing ..."); $have_errors = 1 }
				if( $retc->{$tn} == 2 ){ $log->error("$whoami (via $parent), line ".__LINE__." : warning, tagname '${tn}' is contained in the output image but its value is not correct (expected: ".$exif->{$tn}."'). Ignoring this and continuing with the rest - output is saved but exif data may be missing ..."); $have_errors = 1 }
			}
		}
		if( ($have_errors==0) && ($verbos > 0) ){ $log->info(perl2dump($exif)."$whoami (via $parent), line ".__LINE__." : above exif data was inserted into the screenshot image '$outfile' ...") }
	}

	FINISH:
	return 1 # success
}

# launches a mech obj given optional parameters which
# may overwrite some defaults we have
# On success, it sets mech obj in $self and also returns that same object
# On failure, it returns undef
sub	launch_mech_obj {
	my $self = $_[0];
	my $params = $_[1] // {};
	my $verbos = $self->verbosity;
	my $log = $self->log;
	# the above params have the same structure as the default below
	# we overwrite defaults with params (if any)

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# note ! this will be modified by the W:M:C constructor!!!
	my %my_mech_params = (
		# some defaults which can be overriden by $params
		headless => $self->headless(),
		no_sandbox => 0,
#		log => $mylogger,
		launch_arg => [
			# a string e.g. 800x600 WxH specified in construction
			'--window-size='.$self->resolution(),
			'--password-store=basic', # do not ask me for stupid chrome account password
#			'--remote-debugging-port=9223',
#			'--enable-logging', # see also log above
			'--disable-gpu',
#			'--no-sandbox', # obsolete now
			'--ignore-certificate-errors',
			'--disable-background-networking',
			'--disable-client-side-phishing-detection',
			'--disable-component-update',
			'--disable-hang-monitor',
			'--disable-save-password-bubble',
			'--disable-default-apps',
			'--disable-infobars',
			'--disable-popup-blocking',
		],
	);

	# input param 'WWW::Mechanize::Chrome-params' : specify params to launching chrome as a hashref
	# 'launch_arg' is a hashref though (unlike its counterpart in defaults above)
	# if it has a value like '--window-size' => '1600x1200' it will be converted to '--window-size=1600x1200'
	# and overwrite previous setting if any in the defaults.
	# if it starts with a /^no\s*/i then the defaults will have this option removed from it.
	my $m;
	foreach my $k (keys %$params){
		my $v = $params->{$k};
		if( ref($v) eq '' ){
			# overwrite all the scalars of the default params
			$my_mech_params{$k} = $params->{$k};
		}
	}
	if( exists $params->{'launch_arg'} && ref($m=$params->{'launch_arg'}) eq 'ARRAY' ){
		my %la = map { /=/ ? split/=/,$_ : ($_=>undef) } @$m;
		my %dla = map { /=/ ? split/=/,$_ : ($_=>undef) } @{$my_mech_params{'launch_arg'}};

		foreach my $k (keys %la){
			# it was an option starting with 'no', e.g. 'no --disable-infobars'
			if( $k =~ s/^no\s*//i ){ delete $dla{$k} }
			else { $dla{$k} = $la{$k} } # else set the option or option with value
		}
		$my_mech_params{'launch_arg'} = [ map { defined($dla{$_}) ? $_.'='.$dla{$_} : $_ } keys %dla ];
	}

	# from https://perlmaven.com/logging-in-modules-with-log4perl-the-easy-way
	if(not Log::Log4perl->initialized()){
		# Set priority of root logger to ERROR
        	Log::Log4perl->easy_init(Log::Log4perl::Level::to_priority('ERROR'));
	}

	if( $verbos > 2 ){ $log->info(perl2dump(\%my_mech_params)."$whoami (via $parent), line ".__LINE__." : instantiating a WWW::Mechanize::Chrome object with above parameters ...") }
	$self->{'_private'}->{'WWW::Mechanize::Chrome-object'} = WWW::Mechanize::Chrome->new(%my_mech_params);
	if( ! defined $self->{'_private'}->{'WWW::Mechanize::Chrome-object'} ){ $log->error("_create_mech_obj() : call to ".'WWW::Mechanize::Chrome->new()'." with params:\n".perl2dump(%my_mech_params)."\n---end mech launch params\n    has failed, parameters to this sub (launch_mech_obj) are:\n".perl2dump($params)."\n---- end of sub parameters."); return undef }
	# at this stage the my_mech_params are different, appended by W::M::C !!!
	# --no-sandbox exists there too!

	# now that we have a mech we need to re-do the verbosity thing
	# to fix the mech obj too, after we created it above:
	$verbos = $self->verbosity($self->verbosity);

	if( $verbos > 0 ){ $log->info("$whoami (via $parent), line ".__LINE__." : launched ".'WWW::Mechanize::Chrome'." with the following parameters:\n".perl2dump(\%my_mech_params)."\n--- end mech launch parameters."); }

	return  $self->{'_private'}->{'WWW::Mechanize::Chrome-object'};
}

# scroll by x pixels and y pixels.
sub	scroll { $_[0]->mech_obj->eval('window.scrollBy('.$_[1].', '.$_[2].');') }
sub	scroll_to_bottom { $_[0]->mech_obj->eval('window.scrollTo(0,document.body.scrollHeight);') }
sub	verbosity {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'_private'}->{'debug'}->{'verbosity'} unless defined $m;
	$self->{'_private'}->{'debug'}->{'verbosity'} = $m;

	$WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY = $m;
	# make a mech console for showing js output (and other things)
	# this will show the warning about not to paste things on the console
	# because of XSS attacks etc. nothing to freak out.
	$self->{'_private'}->{'debug'}->{'mech-console'} =
		# WARNING: do not use mech_obj, because it will instantiate it
		( ($m > 0) && _is_mech_obj_instantiated() )
		?	$self->mech_obj->add_listener('Runtime.consoleAPICalled', sub {
			  warn join ", ",
			      map { $_->{value} // $_->{description} }
			      @{ $_[0]->{params}->{args} };
			})
		:	undef # console goes away, all gone
	;
	return $m
}

# check if we have a mech obj but don't instantiate one
# do not use defined($self->mech_obj()) to check if we have a mech object!
sub	_is_mech_obj_instantiated { return defined $_[0]->{'_private'}->{'WWW::Mechanize::Chrome-object'} }

# it will return the mech obj or if not defined, it will
# instantiate it assuming it is needed.
# NOTE: use _is_mech_obj_instantiated() to just
# check if we have a mech obj (and it will not be instantiated)
sub	mech_obj {
	my $self = $_[0];
	my $m = $_[1];

	if( defined $m ){
		$self->{'_private'}->{'WWW::Mechanize::Chrome-object'} = $m;
		return $m
	}
	if( ! defined $self->{'_private'}->{'WWW::Mechanize::Chrome-object'} ){
		# launch a chrome on demand
		$self->{'_private'}->{'WWW::Mechanize::Chrome-object'} = $self->launch_mech_obj(
			$self->mech_params()
		);
		if( ! defined $self->{'_private'}->{'WWW::Mechanize::Chrome-object'} ){
			my $parent = ( caller(1) )[3] || "N/A";
			my $whoami = ( caller(0) )[3];
			my $log = $self->log();
			$log->error("$whoami (via $parent), line ".__LINE__." : call to ".'launch_mech_obj()'." with parameters:\n".perl2dump($self->mech_params())."\n--- end mech launch parameters\n     has failed.");
			return undef
		}
	}
	return $self->{'_private'}->{'WWW::Mechanize::Chrome-object'};
}
sub	mech_params {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'_private'}->{'WWW::Mechanize::Chrome-params'} unless defined $m;
	$self->{'_private'}->{'WWW::Mechanize::Chrome-params'} = $m;
	return $m
}
sub	stop_on_error {
	my ($self, $m) = @_;
	return $self->{'stop-on-error'} unless defined $m;
	$self->{'stop-on-error'} = $m;
	return $m;
}
sub	settle_time {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'settle-time'} unless defined $m;
	$self->{'settle-time'} = $m;
	return $m
}
# has no meaning to change once the mech is instantiated, so ro:
sub	resolution { return $_[0]->{'_private'}->{'resolution'} }
# has no meaning to change once the mech is instantiated, so ro:
sub	headless { return $_[0]->{'_private'}->{'headless'} }
sub	shutdown {
	my $self = $_[0];
	return unless defined $self->mech_obj;
	$self->mech_obj->close;
	sleep(0.5);
	$self->{'_private'}->{'WWW::Mechanize::Chrome-object'} = undef
}
sub log { return $_[0]->{'_private'}->{'log'}->{'logger-object'} }
sub cleanup {
	my ($self, $m) = @_;
	#my $log = $self->log();
	if( defined $m ){
		$self->{'_private'}->{'debug'}->{'cleanup'} = $m;
		return $m;
	}
	return $self->{'_private'}->{'debug'}->{'cleanup'}
}

# return configfile or read+check+set a configfile,
# returns undef on failure or the configfile on success
sub configfile {
	my ($self, $infile) = @_;

	return $self->{'_private'}->{'configfile'} unless defined $infile;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# this can be called before the logger is created, so create a temp logger for this
	my $log = $self->log() // Mojo::Log->new();

	my $ch = parse_configfile($infile, $log);
	if( ! defined $ch ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'parse_configfile()'." has failed for configuration file '$infile'."); return undef }

	# set it in self, it will also do checks on required keys
	if( ! defined $self->confighash($ch) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to load specified confighash, , there must be errors in the configuration."); return undef }

	$self->{'_private'}->{'configfile'} = $infile;

	return $infile #success
}

# parse a config string (the exact contents of a config file)
# returns undef on failure or the confighash on success
sub parse_configstring {
	my ($instring, $log) = @_;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# this can be called before the logger is created, so create a temp logger for this
	$log //= Mojo::Log->new();
	my $xp = {
		'string' => $instring,
		'commentstyle' => 'custom(</*)(*/>)',
		'tags' => ['<%','%>'],
		'variable-substitutions' => {
			'SCRIPTDIR' => Cwd::abs_path($FindBin::Bin),
		},
	};
	my $ch = Config::JSON::Enhanced::config2perl($xp);
	if( ! defined $ch ){ $log->error("Configuration parameters:\n".perl2dump($xp)."\nConfiguration string to parse:\n${instring}\n\n${whoami} (via $parent), line ".__LINE__." : error, call to ".'Config::JSON::Enhanced::config2perl()'." has failed for above configuration string with above parameters."); return undef }
	return $ch; #success
}

# parses the configuration file specified and returns a confighash
# returns undef on failure or the confighash on success
sub parse_configfile {
	my ($infile, $log) = @_;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# this can be called before the logger is created, so create a temp logger for this
	$log //= Mojo::Log->new();

	my $FH;
	if( ! open($FH, '<', $infile) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to open input file '$infile' for reading, $!"); return undef }
	my $instring;
	{ local $/ = undef; $instring = <$FH> } close $FH;

	my $ch = parse_configstring($instring, $log);
	if( ! defined $ch ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'parse_configstring()'." has failed."); return undef }

	return $ch; #success
}

# returns the confighash stored or if one is supplied
# it checks it and sets it and returns it
# or it returns undef on failure
# NOTE, if param is specified then we assume we do not have any configuration,
#       we do not have a logger yet, we have no configuration, no verbosity, etc.
sub confighash {
	my ($self, $m) = @_;

	return $self->{'_private'}->{'confighash'} unless defined $m;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	#print STDOUT "${whoami} (via $parent), line ".__LINE__." : called ...\n";

	# we are storing specified confighash but first check it for some fields:
	# required fields:
	for ('debug', 'logger', 'WWW::Mechanize::Chrome'){
		if( ! exists($m->{$_}) || ! defined($m->{$_}) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, configuration does not have key '$_'.\n"; return undef }
	}

	my $x = $m->{'WWW::Mechanize::Chrome'};
	for ('launch_arg'){
		if( ! exists($x->{$_}) || ! defined($x->{$_}) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, configuration does not have key 'WWW::Mechanize::Chrome'->'$_'.\n"; return undef }
	}

	# ok!
	$self->{'_private'}->{'confighash'} = $m;
	return $m
}

# returns 1 on failure, 0 on success
sub init {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# Confighash
	# first see if either user specified a config file or the default is present and read it,
	# then we will overwrite with user-specified params if any
	my ($configfile, $confighash);
	if( exists($params->{'configfile'}) && defined($configfile=$params->{'configfile'}) ){
		if( ! -f $configfile ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, specified configfile '$configfile' does not exist or it is not a file.\n"; return 1 }
		# this reads, creates confighash and calls confighash() which will do all the tests
		if( ! defined $self->configfile($configfile) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, call to ".'configfile()'." has failed for configfile '$configfile'.\n"; return 1 }
		$confighash = $self->confighash();
	} elsif( exists($params->{'configstring'}) && defined($params->{'configstring'}) ){
		$confighash = parse_configstring($params->{'configstring'}, undef);
		if( ! defined $confighash ){ print STDERR $params->{'configstring'}."\n"."${whoami} (via $parent), line ".__LINE__." : error, call to ".'parse_configstring()'." has failed for the above configuration string provided.\n"; return 1 }
		# this sets the confighash and checks it too
		if( ! defined $self->confighash($confighash) ){ print STDERR $params->{'configstring'}."\n"."${whoami} (via $parent), line ".__LINE__." : error, call to ".'confighash()'." has failed for above configuration string provided.\n"; return 1 }
	} elsif( exists($params->{'confighash'}) && defined($params->{'confighash'}) ){
		$confighash = $params->{'confighash'};
		# this sets the confighash and checks it too
		if( ! defined $self->confighash($confighash) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, call to ".'confighash()'." has failed.\n"; return 1 }
	} else {
		# no config specified, load default
		$confighash = parse_configstring($DEFAULT_CONFIGSTRING, undef);
		if( ! defined $confighash ){ print STDERR $params->{'configstring'}."\n"."${whoami} (via $parent), line ".__LINE__." : error, call to ".'parse_configstring()'." has failed for the above configuration string provided.\n"; return 1 }
		# this sets the confighash and checks it too
		if( ! defined $self->confighash($confighash) ){ print STDERR $params->{'configstring'}."\n"."${whoami} (via $parent), line ".__LINE__." : error, call to ".'confighash()'." has failed for above configuration string provided.\n"; return 1 }
		print STDOUT "${whoami} (via $parent), line ".__LINE__." : warning, loading default configuration because none was specified ...\n";
	}
	# by now we have a confighash in self or died

	# for creating the logger: check
	#  1. params if they have logger or logfile
	#  2. our own confighash if it contains logfile
	#  3. if all else fails, create a vanilla logger
	if( exists($params->{'logger-object'}) && defined($params->{'logger-object'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = $params->{'logger-object'};
		#$log->info("${whoami} (via $parent), line ".__LINE__." : using user-supplied logger object.");
	} elsif( exists($params->{'logfile'}) && defined($params->{'logfile'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = Mojo::Log->new(path => $params->{'logfile'});
		#$log->info("${whoami} (via $parent), line ".__LINE__." : logging to file '".$params->{'logfile'}."'.");
	} elsif( ! defined($self->{'_private'}->{'log'}->{'logger-object'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = Mojo::Log->new();
		#$log->info("${whoami} (via $parent), line ".__LINE__." : a vanilla logger has been created to log to the console.");
	}

        # Now we have a logger
        my $log = $self->log();
        $log->short(1);

	# deprecated 'logger' has now become 'logger-object', we die if this is used
	if( exists($params->{'logger'}) && defined($params->{'logger'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, constructor parameter 'logger' has been replaced by 'logger-object'. This parameter specifies a logger object to be passed on this object."); return 1 }

	# our logger becomes DOMops logger:
	$WWW::Mechanize::Chrome::DOMops::domops_LOGGER = $log;

	# Set verbosity and cleanup as follows:
	#  1. check if exists in params
	#  2. check if exists in confighash
	#  3. set default value
	my $v;
	if( exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ){
		$v = $params->{'verbosity'};
	} elsif( exists($confighash->{'debug'}) && exists($confighash->{'debug'}->{'verbosity'}) && defined($confighash->{'debug'}->{'verbosity'}) ){
		$v = $confighash->{'debug'}->{'verbosity'};
	} else {
		$v = 0; # default verbosity
	}
	# NOTE: sometimes verbosity(x) will also set verbosity to other objects
	# which are instantiated later, e.g. mech, lwp,
	# so, you set verbosity know for public use
	# AND ALSO YOU MUST CALL verbosity(x) AGAIN at the end when
	# all are instantiated, or whenever you (re-)instantiating one of these objects.
	# like $self->verbosity( $self->verbosity );
	# THIS also sets DOMops verbosity:
	if( $self->verbosity($v) < 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to 'verbosity()' has failed for value '$v'."); return 1 }

	my $verbosity = $self->verbosity; # we have verbosity

	if( exists($params->{'cleanup'}) && defined($params->{'cleanup'}) ){
		$v = $params->{'cleanup'};
	} elsif( exists($confighash->{'debug'}) && exists($confighash->{'debug'}->{'cleanup'}) && defined($confighash->{'debug'}->{'cleanup'}) ){
		$v = $confighash->{'debug'}->{'cleanup'};
	} else {
		$v = 0; # default
	}
	if( $self->cleanup($v) < 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to 'cleanup()' has failed for value '$v'."); return 1 }

	# stop on error? default is no
	if( exists($params->{'stop-on-error'}) && defined($params->{'stop-on-error'}) ){
		$v = $params->{'stop-on-error'};
	} elsif( exists($confighash->{'constructor'}) && exists($confighash->{'constructor'}->{'stop-on-error'}) && defined($confighash->{'constructor'}->{'stop-on-error'}) ){
		$v = $confighash->{'constructor'}->{'stop-on-error'};
	} else {
		$v = 0; # default
	}
	$self->stop_on_error($v);

	# input param 'settle-time' (>=0 seconds)
	if( exists($params->{'settle-time'}) && defined($params->{'settle-time'}) ){
		$v = $params->{'settle-time'};
	} elsif( exists($confighash->{'constructor'}) && exists($confighash->{'constructor'}->{'settle-time'}) && defined($confighash->{'constructor'}->{'settle-time'}) ){
		$v = $confighash->{'constructor'}->{'settle-time'};
	} else {
		$v = 0; # default
	}
	$self->settle_time($v);

	# browser size = resolution size
	if( exists($params->{'resolution'}) && defined($params->{'resolution'}) ){
		$v = $params->{'resolution'};
	} elsif( exists($confighash->{'constructor'}) && exists($confighash->{'constructor'}->{'resolution'}) && defined($confighash->{'constructor'}->{'resolution'}) ){
		$v = $confighash->{'constructor'}->{'resolution'};
	} else {
		$v = '1600x1200'; # default
	}
	$v =~ s/x/,/; # !!!!!!
	$_[0]->{'_private'}->{'resolution'} = $v; # it has no setter, because no point to change res midstream

	#headless mode? default is yes, but for debugging can be set to 1
	if( exists($params->{'headless'}) && defined($params->{'headless'}) ){
		$v = $params->{'headless'};
	} elsif( exists($confighash->{'constructor'}) && exists($confighash->{'constructor'}->{'headless'}) && defined($confighash->{'constructor'}->{'headless'}) ){
		$v = $confighash->{'constructor'}->{'headless'};
	} else {
		$v = 1; # default, yes headless!
	}
	$_[0]->{'_private'}->{'headless'} = $v; # it has no setter, because no point to change res midstream

	# input param 'remove-dom-elements' as an array of hashrefs to be passed as params
	# to WWW::Mechanize::Chrome::DOMOps::domops_zap (see that for what keys to use)
	# usually, for each element to zap create a hashref with e.g. 'element-class' => [...]
	# Or just specify 1 item in the array if you can find them with a single selector
	# see https://metacpan.org/pod/WWW::Mechanize::Chrome::DOMops#ELEMENT-SELECTORS
	# for more information
	# NOTE: place an undef anywhere in this array in order to skip the rest of the elements
	if( exists($params->{'remove-dom-elements'}) && defined($params->{'remove-dom-elements'}) ){
		if( ref($params->{'remove-dom-elements'}) ne 'ARRAY' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input param 'remove-dom-elements' must be an ARRAYref and not '".ref($params->{'remove-dom-elements'})."'."); return undef }
		$v = $params->{'remove-dom-elements'};
	} elsif( exists($confighash->{'constructor'}) && exists($confighash->{'constructor'}->{'remove-dom-elements'}) && defined($confighash->{'constructor'}->{'remove-dom-elements'}) ){
		$v = $confighash->{'constructor'}->{'remove-dom-elements'};
	} else {
		$v = 0; # default
	}
	$self->{'_private'}->{'remove-dom-elements'} = $v;

	# do we have exif data? This will be overwritten by any
	# 'exif' specified in the shoot()
	if( exists($params->{'exif'}) && defined($params->{'exif'}) ){
		# check that the exif data format is valid : { k => v, ... }
		if( ref($params->{'exif'})ne'HASH' ){ $log->error("$whoami (via $parent), line ".__LINE__." : error, 'exif' parameter expects a HASH of tagname => tagvalue pairs, not ".ref($params->{'exif'})."."); return 1; }
		$self->{'_private'}->{'exif'} = $params->{'exif'};
	}

	# do we have a recycled mech object passed on to us?
	# in this case we will reuse it and not instantiate a fresh one:
	if( exists($params->{'WWW::Mechanize::Chrome-object'}) && defined($params->{'WWW::Mechanize::Chrome-object'}) ){
		if( ref($params->{'WWW::Mechanize::Chrome-object'}) ne 'WWW::Mechanize::Chrome' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input param 'WWW::Mechanize::Chrome-object' must be a WWW::Mechanize::Chrome object and not '".ref($params->{'WWW::Mechanize::Chrome-object'})."'."); return undef }
		$self->{'_private'}->{'WWW::Mechanize::Chrome-object'} = $params->{'WWW::Mechanize::Chrome-object'};
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : re-using already existing mech object ".$params->{'WWW::Mechanize::Chrome-object'}." ...") }
	}

	# save the WWW::Mechanize::Chrome-params for later, we may need them if crash
	# here, first read the confighash and then override any entries with $params
	# this works only for 1st level keys
	if( exists($params->{'WWW::Mechanize::Chrome'}) && defined($params->{'WWW::Mechanize::Chrome'}) ){
		if( ref($params->{'WWW::Mechanize::Chrome'}) ne 'ARRAY' ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input param 'WWW::Mechanize::Chrome' must be an ARRAYref and not '".ref($params->{'WWW::Mechanize::Chrome'})."'."); return undef }
		$v = (exists($confighash->{'WWW::Mechanize::Chrome'}) && defined($confighash->{'WWW::Mechanize::Chrome'}))
		  ? {
				%{ $confighash->{'WWW::Mechanize::Chrome'} },
				%{ $params->{'WWW::Mechanize::Chrome'} },
		    }
		  : $params->{'WWW::Mechanize::Chrome'}
		;
	} elsif( exists($confighash->{'WWW::Mechanize::Chrome'}) && defined($confighash->{'WWW::Mechanize::Chrome'}) ){
		$v = $confighash->{'WWW::Mechanize::Chrome'};
	} else {
		$v = 0; # default
	}

	# and modify some mech params:
	for (@{$v->{'launch_arg'}}){ next unless $_ =~ /window\-size\s*=/; my $res = $self->resolution; $_ =~ s/=.+?$/=${res}/; last }
	$v->{'headless'} = $self->headless;

	# save them
	$self->mech_params($v);

# resize:
# google-chrome -app="data:text/html,<html><body><script>window.moveTo(580,240);window.resizeTo(1800,1600);</script></body></html>"

	return 0 # success
}

# initialises module-specific things, no need to copy this to other modules
# returns 1 on failure, 0 on success
sub init_module_specific {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();
	my $confighash = $self->confighash();
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called ...") }

	# TODO we can instantiate the shooter (PLUS chrome which is expensive to do !!!) lazily
	# set or create the WWW::Mechanize::Chrome::Webshot object
	if( exists($params->{'WWW::Mechanize::Chrome-object'}) && defined($params->{'WWW::Mechanize::Chrome-object'}) ){
		# caller supplied an existing WWW::Mechanize::Chrome::Webshot object
		$self->{'_private'}->{'WWW::Mechanize::Chrome-object'} = $params->{'WWW::Mechanize::Chrome-object'}
	} else {
		# instantiate only if not lazily
		if( (! defined $self->{'_private'}->{'WWW::Mechanize::Chrome-object'} )
		 && ( (! exists $params->{'launch-mech-on-demand'})
		   || ($params->{'launch-mech-on-demand'} == 0)
		    )
		){
			if( ! defined $self->launch_mech_obj(
				$self->mech_params()
			) ){ $log->error(perl2dump($self->mech_params())."${whoami} (via $parent), line ".__LINE__." : error, call to ".'WWW::Mechanize::Chrome->new()'." has failed for above parameters."); return 1; }
		}
	}

	# done
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : "." has been initialised ...") }
	return 0 # success
}

# It checks if specified tagname/tagvalue pairs (as a HASHref)
# are containd in the metadata of the input image
# returns a hash with tags as keys and each key having a value:
# 0 : missing
# 1 : exists and has correct value
# 2 : exists but has incorrect value
# exists or not respectively
sub	_check_if_exif_tags_exist_in_image {
	my ($imagefile, $exif, $log) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	# the problem is that tagnames (not values) can take their own mysterious case
	# so we UC everything just for comparisons of the keys
	my $info1 = ImageInfo($imagefile);
	my $info = { map { uc $_ => $info1->{$_} } keys %$info1 };
	my %ret;
	for my $tn (keys %$exif){
		my $tv = $exif->{$tn};
		my $tnuc = uc $tn;
		if( ! exists($info->{$tnuc}) ){
			# missing, output is 0
			$log->error("$whoami (via $parent), line ".__LINE__." : error, tag name '${tn}' does not exist in output image '$imagefile'.");
			$ret{$tn} = 0;
			next;
		}
		my $gv = Encode::decode_utf8($info->{$tnuc});
		if( $gv ne $tv ){
			# incorrect value, output is 2
			$log->error("$whoami (via $parent), line ".__LINE__." : error, tag name '${tn}' in output image '$imagefile' does not have the correct value (expected: '".${tv}."', got: '".${gv}."').");
			#$log->error("$whoami (via $parent), line ".__LINE__." : error, tag name '${tn}' in output image '$imagefile' does not have the correct value (expected: '".${tv}."', got: '".Encode::decode_utf8(${gv})."').");
			$ret{$tn} = 2;
			next;
		}
		$ret{$tn} = 1; # exists and has correct value
	}
	return \%ret
}

## POD starts here

=pod

=encoding utf8

=head1 NAME

WWW::Mechanize::Chrome::Webshot - cheap and cheerful html2pdf converter, take a screenshot of rendered HTML, complete with CSS and Javascript

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

This module provides L</shoot($params)> which loads
a specified URL or local file into a spawned, possibly headless, browser
(thank you Corion for L<WWW::Mechanize::Chrome>),
waits for some settle time, optionally removes
specified DOM elements (e.g. advertisements and consents),
takes a screenshot of the rendered content and saves into
the output file, as PDF or PNG, optionally adding any specified EXIF tags.

At the same time, this functionality can be seen as a
round-about way for converting HTML,
complete with CSS and JS, to PDF or PNG. And that is no mean feat.

Actually it's a mean hack.

Did I say that it supports as much HTML, CSS and JS
as the modern browser does?

Here are some examples:

    use WWW::Mechanize::Chrome::Webshot;

    my $shooter = WWW::Mechanize::Chrome::Webshot->new({
      'settle-time' => 10,
      # optionally specify a Mojo::Log logger,
      # useful if you have a global logger you want to use:
      'logger-object' => Mojo::Log->new(path=>'webshot.log'),
      # or just specify a file to log output to:
      #'logfile' => 'webshot.log',
    });
    $shooter->shoot({
      'output-filename' => 'abc.png',
      # optional unless it can not be deduced from filename
      'output-format' => 'png', # or pdf

      # URL or local file, e.g. 'file:///A/B/C.html'
      # !!! BUT USE ABSOLUTE FILEPATH in uri
      'url' => 'https://www.902.gr',

      # remove irritating DOM elements cluttering our view...
      'remove-DOM-elements' => [
        {'element-xpathselector' => '//div[id="advertisments"]'},
        {...}
      ],

      # optionally add exif metadata to the output image
      'exif' => {'created' => 'by the shooter', 'tag2' => 'hehe', ...},
    }) or die;
    ...

=head1 CONSTRUCTOR

=head2 C<new($params)>

Creates a new C<WWW::Mechanize::Chrome::Webshot> object. C<$params>
is a hash reference used to pass initialization options which may
or should include the following:

=over 4

=item * B<C<confighash>> or B<C<configfile>> or B<C<configstring>>

Optional, default will be used. The configuration file/hash/string holds
configuration parameters and its format is "enhanced" JSON
(see L<use Config::JSON::Enhanced>) which is basically JSON
which allows comments between C< E<lt>/* > and C< */E<gt> >.

Here is an example configuration file to get you started,
this configuration is used as default when none is provided:

    </* $VERSION = '0.01'; */>
    </* comments are allowed */>
    </* and <% vars %> and <% verbatim sections %> */>
    {
        "debug" : {
        	"verbosity" : 1,
        	</* cleanup temp files on exit */>
        	"cleanup" : 1
        },
        "logger" : {
        	</* log to file if you uncomment this */>
        	</* "filename" : "..." */>
        },
        "constructor" : {
        	</* for slow connections */>
                "settle-time" : "3",
       		"resolution" : "1600x1200",
       		"stop-on-error" : "0",
       		"remove-dom-elements" : []
        },
        "WWW::Mechanize::Chrome" : {
        	"headless" : "1",
        	"launch_arg" : [
        		</* this will change as per the 'resolution' setting above */>
        		"--window-size=600x800",
        		"--password-store=basic", </* do not ask me for stupid chrome account password */>
        	</*	"--remote-debugging-port=9223", */>
        	</*	"--enable-logging", */>
        		"--disable-gpu",
        	</*	"--no-sandbox", NO LONGER VALID */>
        		"--ignore-certificate-errors",
        		"--disable-background-networking",
        		"--disable-client-side-phishing-detection",
        		"--disable-component-update",
        		"--disable-hang-monitor",
        		"--disable-save-password-bubble",
        		"--disable-default-apps",
        		"--disable-infobars",
        		"--disable-popup-blocking"
        	]
        }
    }


All sections in the configuration are mandatory.

C<confighash> is a hash of configuration options with
structure as above and can be supplied to the constructor
instead of the configuration file.

If no configuration is specified, then a default
configuration will be used. This is hardcoded in the source code.

=item * B<C<logger>> or B<C<logfile>>

Optional. Specify a logger object which adheres
to L<Mojo::Log>'s API or a logfile to write
log info into. It must implement methods C<info()>, C<error()>, C<warn()>.

=item * B<C<verbosity>>

Optional. Verbosity level as an integer, default is 0, silent.


=item * B<C<cleanup>>

Optional. Cleanup all temporary files after exit. Default is 1 (yes). It is useful when debugging.

=item * B<C<settle-time>>

Optional. Seconds to wait between loading the specified URL and taking the screenshot.
This is very important if target URL has lots to do or on a slow connection. Default is 2 seconds.

=item * B<C<resolution>>

Optional. Specify the size of the
mechanized browser in the form C<WxH>. Ideally,
this should set the size of the output image. Default
value is C<1600x1200>.

=item * B<C<headless>>

Optional. When debugging you may find it useful to display the browser while
it loads the URL. Set this to C<0> if you want this.
Default is 1 (yes, headless, the browser window does not show).
I am not sure if the browser dies soon after the mechanized browser object
goes out of scope. You may want to place a C<sleep($long_time);>
before that in order to inspect its contents at your leisure.

=item * B<C<remove-dom-elements>>

Optional. After the URL is loaded and settle time has passed, DOM elements can
be removed. Annoyances like advertisements, consents, warnings can be
zapped by specifying their XPath selectors. This is an ARRAY_REF of HASH_REF.
Each HASH_REF is a selector for DOM elements to be zapped. See L<https://metacpan.org/pod/WWW::Mechanize::Chrome::DOMops#ELEMENT-SELECTORS>
on the exact spec of the DOM selectors.

=item * B<C<exif>>

Optional. Specify one or more EXIF tags to be
inserted into the output image as a HASH_REF of tag/value pairs
each time L</shoot($params)> is called. This value will be overwritten
if C<$params> (of L</shoot($params)>) contains its own C<exif> parameter.

=item * B<C<WWW::Mechanize::Chrome>>

Optional. Specify any parameters to be passed on to the
constructor of L<WWW::Mechanize::Chrome> as a HASH_REF of parameters.

=back

=head1 METHODS

=head2 B<C<shoot($params)>>

It takes a screenshot of the specified URL as
rendered by L<WWW::Mechanize::Chrome> (usually headless)
and saves it as an image to the specified file.

It returns C<0> on failure, C<1> on success.

Input parameters C<$params>:

=over 4

=item * B<C<url>>: specifies the target URL or even a URI pointing
to a local file (e.g. C<file:///A/B/C.html>, use absolute filepath).

=item * B<C<remove-dom-elements>>: specifies DOM elements to
be removed after the URL has been loaded and settle time has passed.
Annoyances like advertisements, consents, warnings can be
zapped by specifying their XPath selectors. This is an ARRAY_REF of HASH_REF.
Each HASH_REF is a selector for DOM elements to be zapped. See L<https://metacpan.org/pod/WWW::Mechanize::Chrome::DOMops#ELEMENT-SELECTORS>
on the exact spec of the DOM selectors. Note that a parameter with the same
name can be specified in the constructor. If one is specified here,
then the one specified in the constructor will be ignored, else, it will
be used.

=item * B<C<exif>>: optionally specify one or more EXIF tags to be
inserted into the output image as a HASH_REF of tag/value pairs.
If B<C<exif>> data is specified here, then
any exif data specified in the constructor will be ignored. This works
well for both PNG and PDF output images.

=back

=head2 B<C<shutdown()>>

It shutdowns the current L<WWW::Mechanize::Chrome> object, if any.


=head2 B<C<scroll_to_bottom()>>

It scrolls the browser's contents to the very bottom without
changing its horizontal position.

=head2 B<C<scroll($w, $h)>>

It scrolls the browser's screen by C<$w> pixels in the horizontal
direction and by C<$h> pixels in the vertical direction.

=head2 B<C<mech_obj()>>

It returns the currently used L<WWW::Mechanize::Chrome> object.

=head1 SCRIPTS

For convenience, the following scripts are provided:

=over 2

=item * B<C<script/www-mechanize-webshot.pl>>

It will take a URL, load it, render it, optionally zap any
specified DOM elements and save the rendered content into
an output image:

This will save the screenshot and also adds the specified exif data:

C<< script/www-mechanize-webshot.pl --url 'https://www.902.gr' --resolution 2000x2000 --exif 'created' 'bliako' --output-filename '902.png' --settle-time 10 >>

Debug why the output is not what you expect, show the browser and let it live for huge settle time, also log output to a file:

C<< script/www-mechanize-webshot.pl --no-headless --url 'https://www.902.gr' --resolution 2000x2000 --output-filename '902.png' --settle-time 100000 --verbosity 10 --logfile debug.log >>

This will also remove specified DOM elements by tag name and XPath selector. Note that
the output format will be deduced as PDF because of the filename:

C<< script/www-mechanize-webshot.pl --remove-dom-elements '[{\"element-tag\":\"div\",\"element-id\":\"sickle-and-hammer\",\"&&\":\"1\"},{\"element-xpathselector\":\"//div[id=ads]\"}]' --url 'https://www.902.gr' --resolution 2000x2000 --exif 'created' 'bliako' --output-filename '902.pdf' --settle-time 10 >>

Explicitly save the output as PDF:

C<< script/www-mechanize-webshot.pl --url 'https://www.902.gr' --resolution 2000x2000 --exif 'created' 'bliako' --output-filename 'tmpimg' --output-format 'PDF' --settle-time 10 >>

=back

=head1 CREATING THE MECH OBJECT

The mech (L<WWW::Mechanize::Chrome>) object must be supplied
to the functions in this module. It must be created by the caller.
This is how I do it:

    use WWW::Mechanize::Chrome;
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($ERROR);

    my %default_mech_params = (
    	headless => 1,
    #	log => $mylogger,
    	launch_arg => [
    		'--window-size=600x800',
    		'--password-store=basic', # do not ask me for stupid chrome account password
    #		'--remote-debugging-port=9223',
    #		'--enable-logging', # see also log above
    		'--disable-gpu',
    		'--no-sandbox',
    		'--ignore-certificate-errors',
    		'--disable-background-networking',
    		'--disable-client-side-phishing-detection',
    		'--disable-component-update',
    		'--disable-hang-monitor',
    		'--disable-save-password-bubble',
    		'--disable-default-apps',
    		'--disable-infobars',
    		'--disable-popup-blocking',
    	],
    );

    my $mech_obj = eval {
    	WWW::Mechanize::Chrome->new(%default_mech_params)
    };
    die $@ if $@;

    # This transfers all javascript code's console.log(...)
    # messages to perl's warn()
    # we need to keep $console var in scope!
    my $console = $mech_obj->add_listener('Runtime.consoleAPICalled', sub {
    	  warn
    	      "js console: "
    	    . join ", ",
    	      map { $_->{value} // $_->{description} }
    	      @{ $_[0]->{params}->{args} };
    	})
    ;

    # and now fetch a page
    my $URL = '...';
    my $retmech = $mech_obj->get($URL);
    die "failed to fetch $URL" unless defined $retmech;
    $mech_obj->sleep(1); # let it settle
    # now the mech object has loaded the URL and has a DOM hopefully.
    # You can pass it on to domops_find() or domops_zap() to operate on the DOM.


=head1 SECURITY WARNING

L<WWW::Mechanize::Chrome> invokes the C<google-chrome>
executable
on behalf of the current user. Headless or not, C<google-chrome>
is invoked. Depending on the launch parameters, either
a fresh, new browser session will be created or the
session of the current user with their profile, data, cookies,
passwords, history, etc. will be used. The latter case is very
dangerous.

This behaviour is controlled by L<WWW::Mechanize::Chrome>'s
L<constructor|WWW::Mechanize::Chrome#WWW::Mechanize::Chrome-%3Enew(-%options-)>
parameters which, in turn, are used for launching
the C<google-chrome> executable. Specifically,
see L<WWW::Mechanize::Chrome#separate_session>,
L<<WWW::Mechanize::Chrome#data_directory>
and L<WWW::Mechanize::Chrome#incognito>.

B<Unless you really need to mechsurf with your current session, aim
to launching the browser with a fresh new session.
This is the safest option.>

B<Do not rely on default behaviour as this may change over
time. Be explicit.>

Also, be warned that L<WWW::Mechanize::Chrome::DOMops> executes
javascript code on that C<google-chrome> instance.
This is done nternally with javascript code hardcoded
into the L<WWW::Mechanize::Chrome::DOMops>'s package files.

On top of that L<WWW::Mechanize::Chrome::DOMops> allows
for B<user-specified javascript code> to be executed on
that C<google-chrome> instance. For example the callbacks
on each element found, etc.

This is an example of what can go wrong if
you are not using a fresh C<google-chrome>
session:

You have just used C<google-chrome> to access your
yahoo webmail and you did not logout.
So, there will be an
access cookie in the C<google-chrome> when you later
invoke it via L<WWW::Mechanize::Chrome> (remember
you have not told it to use a fresh session).

If you allow
unchecked user-specified (or copy-pasted from ChatGPT)
javascript code in
L<WWW::Mechanize::Chrome::DOMops>'s
C<domops_find()>, C<domops_zap()>, etc. then it is, theoretically,
possible that this javascript code
initiates an XHR to yahoo and fetch your emails and
pass them on to your perl code.

But there is another problem,
L<WWW::Mechanize::Chrome::DOMops>'s
integrity of the embedded javascript code may have
been compromised to exploit your current session.

This is very likely with a Windows installation which,
being the security swiss cheese it is, it
is possible for anyone to compromise your module's code.
It is less likely in Linux, if your modules are
installed by root and are read-only for normal users.
But, still, it is possible to be compromised (by root).

Another issue is with the saved passwords and
the browser's auto-fill when landing on a login form.

Therefore, for all these reasons, B<it is advised not to invoke (via L<WWW::Mechanize::Chrome>)
C<google-chrome> with your
current/usual/everyday/email-access/bank-access
identity so that it does not have access to
your cookies, passwords, history etc.>

It is better to create a fresh
C<google-chrome>
identity/profile and use that for your
C<WWW::Mechanize::Chrome::DOMops> needs.

No matter what identity you use, you may want
to erase the cookies and history of C<google-chrome>
upon its exit. That's a good practice.

It is also advised to review the
javascript code you provide
via L<WWW::Mechanize::Chrome::DOMops> callbacks if
it is taken from 3rd-party, human or not, e.g. ChatGPT.

Additionally, make sure that the current
installation of L<WWW::Mechanize::Chrome::DOMops>
in your system is not compromised with malicious javascript
code injected into it. For this you can check its MD5 hash

=head2 REQUIREMENTS

=head1 DEPENDENCIES

This module depends on L<WWW::Mechanize::Chrome> which, in turn,
depends on the C<google-chrome> executable be installed on the
host computer. See L<WWW::Mechanize::Chrome::Install> on
how to install the executable.

Test scripts (which create there own mech object) will detect the absence
of C<google-chrome> binary and exit gracefully, meaning the test passes.
But with a STDERR message to the user. Who will hopefully notice it and
proceed to C<google-chrome> installation. In any event, this module
will be installed with or without C<google-chrome>.

The browser will be run, usually headless -- so a headless host system is fine,
the first time you take a screenshot. It will only be re-spawned if
you have shutdown the browser in the meantime. Exiting your script
will shutdown the browser. And so, running a script again will
re-spawn the browser (AFAICU/sic/).


=head2 CAVEATS

In exporting to PDF, the size of the output image does not
seem to be the same as the browser size. This does not happen
with exporting to PNG.


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-mechanize-chrome-webshot at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Chrome-Webshot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Mechanize::Chrome::Webshot

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Chrome-Webshot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Mechanize-Chrome-Webshot>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WWW-Mechanize-Chrome-Webshot>

=item * Search CPAN

L<https://metacpan.org/release/WWW-Mechanize-Chrome-Webshot>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WWW::Mechanize::Chrome::Webshot
