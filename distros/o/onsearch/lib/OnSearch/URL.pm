package OnSearch::URL; 

#$Id: URL.pm,v 1.2 2005/07/11 19:19:51 kiesling Exp $

my ($VERSION)= ('$Revision: 1.2 $' =~ /:\s+(.*)\s+\$/);

use OnSearch;
use OnSearch::AppConfig;

require Exporter;
require DynaLoader;
our (@ISA, @EXPORT);
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(map_url);

###
### Map the path to either a file, a cached URL, or a site URL.
###

sub map_url {
    my $path = $_[0];

    my $url;
    my $onsearchdir = OnSearch::AppConfig->str ('OnSearchDir');

    if ($path =~ m"$onsearchdir/websites") {
	return $url if ($url = remote_url ($path));
    } else {
	return $url if ($url = local_url ($path));
    }

    return undef;
}

sub remote_url {
    my $path = $_[0];

    my $server_domain = $ENV{DOCUMENT_ROOT};
    my $onsearchdir = OnSearch::AppConfig->str ('OnSearchDir');
    my $symlinks_ok = OnSearch::AppConfig->str ('HasSymLinks');

    my ($actual_server_dir, $server_cache_dir, $urlpath);

    if ($symlinks_ok && -l $server_domain) { 
	if ($path !~ m"$server_domain"i) {
	    $actual_server_dir = readlink ($server_domain);
	} else {
	    $actual_server_dir = $server_domain;
	}
    } else {
	$actual_server_dir = $server_domain;
    }

    $server_cachedir = "$actual_server_dir/$onsearchdir/websites/";

    if ($path =~ m"^$server_cachedir") {
	($urlpath) = ($path =~ m"^$server_cachedir(.*)");
	$urlpath = 'http://' . $urlpath;
	return $urlpath;
    }
    return undef;
}


sub local_url {
    my $path = $_[0];

    my $server_domain = $ENV{DOCUMENT_ROOT};
    my $server_name = $ENV{SERVER_NAME};
    my $server_port = $ENV{SERVER_PORT};
    my $symlinks_ok = OnSearch::AppConfig->str ('HasSymLinks');
    my ($sitepath, $url, $actual_dir);

    if ($symlinks_ok && -l $server_domain) { 
	if ($path !~ m"$server_domain"i) {
	    $actual_dir = readlink ($server_domain);
	} else {
	    $actual_dir = $server_domain;
	}
    } else {
	$actual_dir = $server_domain;
    }

    if ($path =~ m"^$actual_dir"i) {
	($path) = ($path =~ m"^$actual_dir(.*)");

	if ($path !~ /^\//) { $path = '/' . $path; }
	
	my $server_url = "http://$server_name" . 
	    (($server_port ne '80') ? ":$server_port" : '');
	return "$server_url$path";
    }

    return undef;
}

