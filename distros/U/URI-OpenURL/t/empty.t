use Test;
use strict;

BEGIN { plan tests => 5 }

use URI::OpenURL;
use POSIX qw/strftime/;

# Construct an OpenURL
my $uri = URI::OpenURL->new('http://openurl.ac.uk/');
ok($uri,'http://openurl.ac.uk/?url_ver=Z39.88-2004');

my $ttime = strftime("%Y-%m-%dT%H:%M:%STZD",gmtime(1107434304));
ok(!defined($uri->init_timestamps($ttime)));
$uri->init_ctxobj_version;
my %query = $uri->query_form;
ok(
	$query{'ctx_ver'} eq 'Z39.88-2004' &&
	$query{'ctx_tim'} eq $ttime && $query{'url_tim'} eq $ttime
);
ok($uri->init_timestamps,$ttime);
ok($uri->init_timestamps ne $ttime);
