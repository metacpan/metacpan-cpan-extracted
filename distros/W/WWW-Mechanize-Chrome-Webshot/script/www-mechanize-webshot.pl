#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.04';

use Getopt::Long;
use Encode;
use WWW::Mechanize::Chrome::DOMops qw/
	domops_read_dom_element_selectors_from_JSON_string
	domops_read_dom_element_selectors_from_JSON_file
/;
use WWW::Mechanize::Chrome::Webshot;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

my $DEFAULT_CONFIGSTRING = <<'EOCH';
</* $VERSION = '0.04'; */>
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
EOCH

my $constructor_params = {
	'settle-time' => 2,
	'resolution' => '1600x1200',
	'verbosity' => 0,
	'WWW::Mechanize::Chrome-params' => {},
	'stop-on-error' => 0,
	'remove-dom-elements' => undef,
};
my $webshot_params = {
	'url' => undef,
	'output-filename' => undef,
	'output-format' => undef,
	'exif' => undef,
};

my $waiting_for_second_arg = undef;
if( ! Getopt::Long::GetOptions(
	'url=s' => sub { $webshot_params->{$_[0]} = $_[1] },
	'output-filename=s' => sub { $webshot_params->{$_[0]} = $_[1]; },
	'output-format=s' => sub { $webshot_params->{$_[0]} = $_[1]; },
	'exif=s{2}' => sub {
		# when we have an option with 2+ args, it comes here twice
		# once with 1st arg, second time with 2nd arg, etc.
		my ($k, $v);
		if( defined $waiting_for_second_arg ){ $k = $waiting_for_second_arg; $v = Encode::decode_utf8($_[1]); }
		else { $k = $_[1]; $v = undef }
		if( ! defined $webshot_params->{$_[0]} ){
			$webshot_params->{$_[0]} = { $k => $v }
		} else {
			$webshot_params->{$_[0]}->{$k} = $v
		}
		$waiting_for_second_arg = defined($waiting_for_second_arg) ? undef : $k;
	},
	'settle-time=i' => sub { $constructor_params->{$_[0]} = $_[1] },
	'resolution=s' => sub {
		if( $_[1] !~ /^\d+x\d+$/ ){ print STDERR "$0 : --".$_[0]." parameter must be of the form WidthxHeight, and not '".$_[1]."'.\n"; exit(1); }
		$constructor_params->{$_[0]} = $_[1];
	},
	'no-headless' => sub { $constructor_params->{'headless'} = 0 },
	'stop-on-error' => sub { $constructor_params->{$_[0]} = 1 },
	'remove-dom-elements=s' => sub {
		my $jsonstr = $_[1];
		$constructor_params->{$_[0]} = WWW::Mechanize::Chrome::DOMops::domops_read_dom_element_selectors_from_JSON_string($jsonstr);
		die "$jsonstr\n\n$0 : error, failed to parse above input JSON via --".$_[0] unless defined $constructor_params->{$_[0]};
	},
	'remove-dom-elements-file=s' => sub {
		my $jsonfile = $_[1];
		$constructor_params->{'remove-dom-elements'} = WWW::Mechanize::Chrome::DOMops::domops_read_dom_element_selectors_from_JSON_file($jsonfile);
		die "$0 : error, failed to parse input JSON read from file '$jsonfile' via --".$_[0] unless defined $constructor_params->{'remove-dom-elements'}
	},
	'configfile=s' => sub { $constructor_params->{$_[0]} = $_[1] },
	'verbosity=i' => sub { $constructor_params->{$_[0]} = $_[1] },
	'help|h|?' => sub { print STDOUT usage($0)."\n"; exit(0) },
) ){ print STDERR usage($0) . "\n\n$0 : error, something wrong with command line parameters.\n"; exit(1) }

my $verbos = $constructor_params->{'verbosity'};

if( ! exists($constructor_params->{'configfile'}) || ! defined($constructor_params->{'configfile'}) ){
	# default config
	$constructor_params->{'configstring'} = $DEFAULT_CONFIGSTRING;
}

if( $verbos > 0 ){ print STDOUT perl2dump($constructor_params)."$0 : instantiating with above parameters ...\n" }
my $shooter = WWW::Mechanize::Chrome::Webshot->new($constructor_params);
if( ! defined $shooter ){ print STDERR perl2dump($constructor_params)."\n$0 : error, failed to instantiate the shooter (".'WWW::Mechanize::Chrome::Webshot'.") with above parameters.\n"; exit(1) }
if( $verbos > 0 ){ print STDOUT perl2dump($webshot_params)."$0 : taking a screenshot with above parameters ...\n" }

my $ret = $shooter->shoot($webshot_params);
if( $ret != 1 ){ print STDERR perl2dump($webshot_params)."$0 : error, failed to take the screenshot with above parameters.\n"; exit(1) }

$shooter->shutdown;

print STDOUT "$0 : done, success url '".$webshot_params->{'url'}."' has been screenshot'ed into file '".$webshot_params->{'output-filename'}."'.\n";

sub usage {
	return "Usage: ".$_[0]." : <options>\n".
	"Options:\n".
	"[--url U : specify the url to get a screenshot of. A local HTML file can be loaded as well by using the 'file://<ABSOLUTE-FILEPATH>' URI scheme. NOTE that an ABSOLUTE FILE PATH is best.]\n".
	"[--output-filename O : specify the output file to save the screenshot image into.]\n".
	"[--output-format F : specify the format of the output file. It is only needed if the format can not be deduced from the specified output filename. At the moment, the output file format can be one of PDF or PNG.]\n".
	"[--settle-time secs : wait for some many seconds after loading the URL giving it a chance to settle. Default is ".$constructor_params->{'settle-time'}." seconds.]\n".
	"[--exif K V [--exif K V ...] : specify one or more EXIF metadata key-value pairs to be inserted into the output screenshot image. WARNING: tagnames (keys) can not be unicode and have restrictions with characters like spaces or ':' etc.]\n".
	"[--resolution WxH : specify the output image size as WxH pixels. Default is ".$constructor_params->{'resolution'}."]\n".
	"[--no-headless : show the browser and see what it loads and what DOM elements it zaps. Default is to run in headless mode. It is useful for debugging purposes. Make sure that you specify a huge '--settle-time' because the browser will shutdown as soon as the screenshot is taken.]\n".
	"[--remove-dom-elements JSONSPEC : specify DOM element selectors to delete selected DOM elements before taking the screenshot (e.g. deleting advertisments, UI panels, etc.). The spec is in the form of a JSON string which must specify an ARRAY of HASHes or a single HASH. Each hash contains the spec for selecting one or more DOM elements. See https://metacpan.org/pod/WWW::Mechanize::Chrome::DOMops#ELEMENT-SELECTORS on the complete spec. The only difference is that here a JSON string of the spec is needed.]\n".
	"[--remove-dom-elements-file F [--remove-dom-elements-file F ...] : same as --remove-dom-elements but the selector spec is in a file as a JSON string. This is vastly more convenient than specifying JSON strings on the command line - especially for poor windowers out there!]\n".
	"[--stop-on-error : all errors are fatal, this is particularly specific to deleting DOM elements and what happens if not found. Default is to ignore these errors.]\n".
	"[--configfile F : a file with configuration in Enhanced JSON format. There is default configuration if this is not provided.]\n".
	"[--verbosity N : specify verbosity. Zero being the mute. Default is ".$constructor_params->{'verbosity'}.".]\n".
	"\nThis script will load the specified url or a local HTML file in a headless browser sized at the specified resolution (thanks to Corion/WWW::Mechanize::Chrome), allow some settle time, optionally remove any specified DOM elements and take a screenshot of the rendered result as displayed in the browser. The screenshot image will then be added with exif tags if any are specified and then saved to the output file.\n".
	"\nExamples:\n".
	"\n1. This will add the specified exif data to the output image of the rendered URL:\n".
	"  $0 --url 'https://www.902.gr' --resolution 2000x2000 --exif 'created' 'bliako' --output-filename '902.png' --settle-time 10\n".
	"\n2. Debug why the output is not what you expected by showing the browser (and let it live for huge settle time lest it shutdowns):\n".
	"  $0 --no-headless --url 'https://www.902.gr' --resolution 2000x2000 --output-filename '902.png' --settle-time 100000\n".
	"\n3. This will remove the specified DOM elements by tag name and XPath selector:\n".
	"  $0 --remove-dom-elements '[{\"element-tag\":\"div\",\"element-id\":\"sickle-and-hammer\",\"&&\":\"1\"},{\"element-xpathselector\":\"//div[id=ads]\"}]' --url 'https://www.902.gr' --resolution 2000x2000 --exif 'created' 'bliako' --output-filename '902.pdf' --settle-time 10\n".
	"\n\nProgram by Andreas Hadjiprocopis (c) 2025 / bliako at cpan.org / andreashad2 at gmail.com\n\n"
}
