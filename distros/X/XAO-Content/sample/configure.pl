#!/usr/bin/env perl
use warnings;
use strict;

my $project='content';

my @files=qw(
    objects/Config.pm
    bin/build-structure
);

my %c;
if(open(CACHE,".config-cache")) {
    while(my $str=<CACHE>) {
        chomp $str;
        next unless $str =~ /^\s*(project|odb_dsn|odb_user|odb_password)\s+(.*?)\s*$/;
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

    print "\n";

    print <<EOT;
Here are your values:
 PROJECT='$project'
 ODB_DSN='$dsn'
 ODB_USER='$user'
 ODB_PASSWORD='$password'

EOT
    print "Are you sure? [Y/n] ";
    exit 1 if <STDIN> =~ /n/;
    print "\n";

    open(CACHE,">.config-cache") || die "Can't open .config-cache: $!\n";
    print CACHE <<EOT;
project         $project
odb_dsn         $dsn
odb_user        $user
odb_password    $password
EOT
    close(CACHE);
    $c{project}=$project;
    $c{odb_dsn}=$dsn;
    $c{odb_user}=$user;
    $c{odb_password}=$password;
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
        $str=~s/<%PROJECT%>/$c{project}/ge;
        $str=~s/<%ODB_DSN%>/$c{odb_dsn}/ge;
        $str=~s/<%ODB_USER%>/$c{odb_user}/ge;
        $str=~s/<%ODB_PASSWORD%>/$c{odb_password}/ge;
        print FILE $str;
    }
    close(FILE);
    close(PROTO);

    chmod 0755, $file if $file =~ /bin\//;
}

exit 0;
