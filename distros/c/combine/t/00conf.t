#Testing that conf-files exists and create copy of conf in blib
use strict;
local $^W = 1;

our $jobname;
require './t/defs.pm';
print "1..6\n";

print "not " unless -d './conf';
print "ok 1\n";

my @files = ('default.cfg', 'job_default.cfg', 'tidy.cfg', 'Topic_carnivor.txt');
my $i=2;
foreach my $f (@files) {
	print "not " unless -s "./conf/$f";
	print "ok $i\n";
	$i++;
}

mkdir('./blib/conf')  unless -d './blib/conf';
system('cp ./conf/* ./blib/conf/ > /dev/null 2> /dev/null');
system("rm -rf ./blib/conf/$jobname > /dev/null 2> /dev/null");
print "not " unless mkdir("./blib/conf/$jobname");

open(CONF,">./blib/conf/$jobname/combine.cfg");
print CONF "MySQLdatabase   = \"combine\@localhost:$jobname\"\n";
print CONF "doCheckRecord = 0\n";
close(CONF);
system("cat ./conf/job_default.cfg >> ./blib/conf/$jobname/combine.cfg");
system("touch ./blib/conf/$jobname/stopwords.txt");
system("touch ./blib/conf/$jobname/config_serveralias");
system("touch ./blib/conf/$jobname/config_exclude");

print "ok $i\n";
$i++;
