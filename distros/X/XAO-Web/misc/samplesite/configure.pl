#!/usr/bin/perl -w
use strict;
use XAO::Base;

require 'requires.pl';

##
# Normally project name gets taken from PROJECT in Makefile, but you can
# override it here.
#
my $project=undef;

##
# List of files that your project needs built using standard replacements
#
my @files=qw(
    bin/build-structure
    objects/Config.pm
);

########### In most cases there is no need to change anything below ###########

if(!$project && open(F,'Makefile')) {
    while(<F>) {
        next unless /^PROJECT=(\w+)[\r\n\s]*$/;
        $project=$1;
        last;
    }
    close(F);
}
$project ||
    die "No project name in both Makefile and configure.pl\n";

my %c;
if(open(CACHE,".config-cache")) {
    while(my $str=<CACHE>) {
        chomp $str;
        next unless $str =~ /^\s*(project|base_url|odb_dsn|odb_user|odb_password|test_site)\s+(.*?)\s*$/;
        $c{$1}=$2;
    }
    close(CACHE);
}

if(!$c{project} || (stat(".config-cache"))[9] < (stat("configure.pl"))[9]) {
    print "Configuring project defaults\n\n";

    $project=$c{project} if $c{project};
    printf '%-40s : ',"Enter project name [$project]";
    chomp(my $n_project=<STDIN>);
    $project=$n_project if $n_project;

    my $base_url=$c{base_url} || "http://$project.com";
    printf '%-40s : ',"Enter base URL [$base_url]";
    chomp(my $n_base_url=<STDIN>);
    $base_url=$n_base_url if $n_base_url;

    my $dsn=$c{odb_dsn} || "OS:MySQL_DBI:$project";
    printf '%-40s : ',"Enter ODB_DSN [$dsn]";
    chomp(my $n_dsn=<STDIN>);
    $dsn=$n_dsn if $n_dsn;

    my $user=$c{odb_user} || '';
    printf '%-40s : ',"Enter ODB_USER [$user]";
    chomp(my $n_user=<STDIN>);
    $user=$n_user if $n_user;

    my $password=$c{odb_password} || '';
    printf '%-40s : ',"Enter ODB_PASSWORD [$password]";
    chomp(my $n_password=<STDIN>);
    $password=$n_password if $n_password;

    my $test_site=$c{test_site};
    printf '%-40s : ',"Is it a test site [".($test_site ? 'Y' : 'N')."] (y/n)";
    chomp(my $n_test_site=<STDIN>);
    if($n_test_site) {
        $test_site=lc($n_test_site) eq 'y' ? 1 : 0;
    }

    print "\n";

    print <<EOT;
Here are your values:
 PROJECT='$project'
 BASE_URL='$base_url'
 ODB_DSN='$dsn'
 ODB_USER='$user'
 ODB_PASSWORD='$password'
 TEST_SITE='$test_site'

EOT
    print "Are you sure? [Y/n] ";
    exit 1 if <STDIN> =~ /n/;
    print "\n";

    open(CACHE,">.config-cache") || die "Can't open .config-cache: $!\n";
    print CACHE <<EOT;
project         $project
base_url        $base_url
odb_dsn         $dsn
odb_user        $user
odb_password    $password
test_site       $test_site
EOT
    close(CACHE);
    $c{project}=$project;
    $c{base_url}=$base_url;
    $c{odb_dsn}=$dsn;
    $c{odb_user}=$user;
    $c{odb_password}=$password;
    $c{test_site}=$test_site;
}

for my $file (@files) {
    next if -r $file &&
            -r "$file.proto" &&
            (stat($file))[9] >= (stat("$file.proto"))[9] &&
            (stat($file))[9] >= (stat(".config-cache"))[9];

    print "$file.proto --> $file\n";

#    rename $file,"$file.old" if -f $file;

    open(PROTO,"$file.proto") || die "Can't open $file.proto: $!\n";
    open(FILE,"> $file") || die "Can't open $file: $!\n";
    while(my $str=<PROTO>) {
        $str=~s/<[%\$]PROJECT[%\$]>/$c{project}/ge;
        $str=~s/<[%\$]PROJECTSDIR[%\$]>/$XAO::Base::projectsdir/ge;
        $str=~s/<[%\$]BASE_URL[%\$]>/$c{base_url}/ge;
        $str=~s/<[%\$]ODB_DSN[%\$]>/$c{odb_dsn}/ge;
        $str=~s/<[%\$]ODB_USER[%\$]>/$c{odb_user}/ge;
        $str=~s/<[%\$]ODB_PASSWORD[%\$]>/$c{odb_password}/ge;
        $str=~s/<[%\$]TEST_SITE[%\$]>/$c{test_site}/ge;
        print FILE $str;
    }
    close(FILE);
    close(PROTO);

    chmod 0755, $file if $file =~ /bin\//;
}

exit 0;
