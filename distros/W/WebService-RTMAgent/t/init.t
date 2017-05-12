#!perl

# Robustness tests on init

use strict;
use warnings;
use Test::More tests => 5;
use WebService::RTMAgent;
use English;

use File::Copy;
use File::Spec;
use File::Temp qw(tempdir);

my $dir = tempdir( CLEANUP => 1 );

my $config_file = File::Spec->catfile($dir, "config");
copy("t/config",$config_file) or die "Could not copy config file to $dir\n";
$WebService::RTMAgent::config_file = $config_file;

# check that destroying an un-initialised RTMAgent doesn't
# clobber the config file
my $ua = new WebService::RTMAgent;
undef $ua;   # Call DESTROY
# config_file should not have changed
{
    local $/; undef $/;
    my $fh;
    open $fh, $config_file;
    my $start = <$fh>;
    open $fh, "t/config";
    my $end = <$fh>;
    ok($start eq $end, "Config file not clobbered on uninitialised DESTROY");
}


# We can only do the file access tests if we're not root
SKIP: {
    skip "File access tests can't be run under root", 2 unless $UID;
    # check we don't start if config file not writable
    copy "t/config", $config_file or die "copy config to $config_file: $!\n";
    chmod 0444, $config_file or die "chmod $config_file: $!\n";
    eval {
        $ua = new WebService::RTMAgent;
        $ua->init;
    };
    ok($@ =~ /$config_file/, "Don't start if config file isn't writable");

    # Same with not readable
    chmod 0000, $config_file;
    eval {
        $ua = new WebService::RTMAgent;
        $ua->init;
    };
    ok($@ =~ /$config_file/, "Don't start if config file isn't readable");
}

# and... don't start if it's not XML
chmod 0644, $config_file;
my $fh;
open $fh, ">$config_file";
print $fh "hello word\n";
my $ok = eval {
    $ua = new WebService::RTMAgent;
    $ua->init;
    1;
};

my $error = $@;
ok( ! $ok, "Don't start if config file isn't XML");
like($error, qr/Invalid XML file/, "error message is as expected");

unlink $config_file;
