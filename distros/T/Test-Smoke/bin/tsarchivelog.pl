#!/usr/bin/env perl
use strict;

use File::Spec::Functions;
use FindBin;
use lib catdir($FindBin::Bin, 'lib');
use lib catdir($FindBin::Bin, updir(), 'lib');

use Test::Smoke::App::Options;
use Test::Smoke::App::SmokePerl;
use File::Copy;
use File::Spec;
use JSON;
use Path::Tiny ();
use POSIX ();


my $app = Test::Smoke::App::SmokePerl->new(
    Test::Smoke::App::Options->smokeperl_config()
);

if (my $error = $app->configfile_error) {
    die "$error\n";
}

my $lfile = $app->option('lfile');
die "Could not locate smokecurrent.log" unless -f $lfile;

my $adir = $app->option('adir');
die "Could not locate logs/smokecurrent directory" unless -d $adir;

my $jsnfile = File::Spec->catfile($app->option('ddir'), $app->option('jsnfile'));
die "Could not locate mktest.json" unless -f $jsnfile;
my $log_file = compose_log_file_name($adir, $jsnfile);

my $localtime = POSIX::strftime("[%Y-%m-%d %H:%M:%S%z] ", localtime);

my $success = copy($lfile => $log_file);
if (! $success) {
    warn($localtime, "Failed to cp($lfile,$log_file): $!");
}
else {
    open my $OVERALL_LOG, '>>', $log_file or die "Could not open $log_file for appending: $!";
    print $OVERALL_LOG $localtime, "Copy($lfile, $log_file): ok\n";
    close $OVERALL_LOG or die "Could not close $log_file after writing: $!";
}


sub compose_log_file_name {
    my ($adir, $jsnfile) = @_;
    my $utf8_encoded_json_text = Path::Tiny::path($jsnfile)->slurp_utf8;
    my $config = decode_json($utf8_encoded_json_text);
    my $SHA = $config->{sysinfo}->{git_id};
    return File::Spec->catfile($adir, "log${SHA}.log");
}
