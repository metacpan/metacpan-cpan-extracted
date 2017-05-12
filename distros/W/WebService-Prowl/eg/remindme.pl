#!/usr/bin/env perl
use strict;
use warnings;

use WebService::Prowl;
use Getopt::Long;
use File::HomeDir;
use File::Spec;
use File::Temp qw/tempfile/;
use File::Path qw/mkpath rmtree/;
use YAML();

my $input = shift @ARGV;
my ($msg, $time) = split(/\s+:\s+/, $input, 2);

unless ($msg and $time) {
die <<EOF;
Usage:
\t$0 'go to the bank : 2pm tomorrow'
(see 'time' format on at(1))
EOF
}

my $cfg_file = File::Spec->catfile(File::HomeDir->my_home, '.prowl.yml');
unless (-e $cfg_file) {
    die "create .prowl.yml file and set apikey in it";
}

my $now = time();
my $r_dir = File::Spec->catfile(File::HomeDir->my_home, '.remindme', $now);
unless (-d $r_dir) {
    mkpath($r_dir) or die $!;
}

## remove old dirs
opendir(DH, File::Spec->catfile(File::HomeDir->my_home, '.remindme')) or die $!;
my @done =  map {File::Spec->catfile($r_dir, $_) } 
            grep { /^(\d+)$/ && $1 < ($now - 60 * 50) } readdir(DH);
close DH;
rmtree $_ for @done;

my $config = YAML::LoadFile($cfg_file);
my $apikey = $config->{apikey};
my $ws = WebService::Prowl->new(apikey => $apikey);
$ws->verify() || die $ws->error();
my $perl_code = sprintf(do { undef $/; <DATA> }, $msg);

## put the perl script into the directory
my ($pl, $pl_exefile) = tempfile('perl-XXXXXXXX', DIR => $r_dir, UNLINK => 0); 
print $pl $perl_code;
close $pl;
chmod 0755, $pl_exefile;

open AT, "|at $time" or die "can't open pipe";
print AT "perl $pl_exefile\n";
close AT;

__DATA__
#!/usr/bin/env perl
use strict;
use warnings;

use File::HomeDir;
use File::Spec;
use YAML();
use WebService::Prowl;

my $cfg_file = File::Spec->catfile(File::HomeDir->my_home, '.prowl.yml');
my $config = YAML::LoadFile($cfg_file);
my $apikey = $config->{apikey};

my $ws = WebService::Prowl->new(apikey => $apikey);
$ws->verify() || die $ws->error();
$ws->add('application' => 'remindme', event => 'reminder', description => '%s');

