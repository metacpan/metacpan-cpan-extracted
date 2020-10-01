use strict;
use warnings;
use utf8;

use Test::More;
use lib 'lib';
use File::Temp;
use File::Slurper qw(read_text);
use FindBin qw($Bin $RealBin);
use lib "$Bin/../../Gtk3-WebKit2/lib";
use URI;

#Running tests as root will sometimes spawn an X11 that cannot be closed automatically and leave the test hanging
plan skip_all => 'Tests run as root may hang due to X11 server not closing.' unless $>;

use_ok 'WWW::WebKit2';

my $dir = File::Temp->newdir();

# logging should be off by default
my $webkit = WWW::WebKit2->new(
    xvfb     => 1,
    log_path => "$dir/logs"
);

$webkit->init;

my $file = $webkit->write_log('test');
ok((not -d "$dir/logs"), 'no logging, no log folder created');
ok((not $file), 'no logging, no file written');

$webkit->enable_logging;
$file = $webkit->write_log('test');
ok(-d "$dir/logs", 'log folder created');
is(read_text($file), 'test', 'log file written');

$webkit->disable_logging;
$file = $webkit->write_log('test');
ok((not $file), 'no logging, no file written');

# try initializing with logging => 1
$dir = File::Temp->newdir();
$webkit = WWW::WebKit2->new(
    xvfb     => 0,
    log_path => "$dir/logs",
    logging  => 1,
);

$file = $webkit->write_log('another test');
ok(-d "$dir/logs", 'log folder creted');
is(read_text($file), 'another test', 'log file written');

$webkit->open("$Bin/test/load.html");
$file = $webkit->log_html_source;
is(read_text($file), read_text("$Bin/test/load.html"), 'logged html source');

done_testing;
