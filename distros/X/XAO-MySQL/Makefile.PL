# Copyright (c) 2002 XAO Inc.
###############################################################################
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Manifest;

my %d;
if(open(F,'.config')) {
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
}
while(!$d{test_dsn}) {
    print <<EOT;

XAO::DO::FS::Glue::MySQL will need access to a MySQL database in order
to run tests.  That database will be COMPLETELY DESTROYED AND OVERRIDEN
every time you run 'make test'.

The database have to be created, but it does not matter what tables it
contains - they all will be dropped.

Please enter access information (brackets contain default values):

EOT
    my $dsn='OS:MySQL:test_fs';
    print "DSN: [$dsn] ";
    chomp(my $str=<STDIN>);
    if($str) {
        if($str =~ /^\s*(OS:(\w+):(\w+)(;.*?)?)\s*$/) {
            $dsn=$1;
        }
        else {
            die "Incorrect DSN entered!\n";
        }
    }
    chomp(my $user=`whoami`);
    print "User name: [$user] ";
    chomp($str=<STDIN>);
    if($str && $str=~/^\s*(.*?)\s*$/) {
        $user=$1;
    }
    my $pass='';
    print "Password: [$pass] ";
    chomp($str=<STDIN>);
    if($str && $str=~/^\s*(.*?)\s*$/) {
        $pass=$1;
    }

    print <<EOT;

Here is what will be used to connect to TEST database
(and DESTROY it):
   DSN:      $dsn
   User:     $user
   Password: $pass

EOT
    $|=1;
    print "Does it make sense ? [Y/n] y\b";
    chomp($str=<STDIN>);
    if(!$str || lc($str)=~/y/) {
        open(F,">.config") || die "Can't open .config: $!\n";
        print F <<EOT;
## Feel free to remove or edit that file. It will be re-created on `perl
## Makefile.PL' if removed.
\$d{test_dsn}='$dsn';
\$d{test_user}='$user';
\$d{test_password}='$pass';
EOT
        last;
    }
}

my $mysql_libs=`mysql_config --libs`;
chomp $mysql_libs;
$mysql_libs=~s/'//g;
my $mysql_cflags=`mysql_config --cflags`;
chomp $mysql_cflags;
$mysql_cflags=~s/'//g;

WriteMakefile(
    'AUTHOR'        => 'XAO Inc. http://xao.com/',
    'ABSTRACT'      => 'Fast MySQL driver for the XAO::FS',
    'NAME'          => 'XAO::DO::FS::Glue::MySQL',
    'DISTNAME'      => 'XAO-MySQL',
    'VERSION_FROM'	=> 'MySQL.pm',
    'PREREQ_PM'     => { 
        'Error'         => '0.14',
        'Test::Unit'    => '0.14',
        'XAO::Base'     => '1.04',
        'XAO::FS'       => '1.04',
    },
    INC             => $mysql_cflags,
    LIBS            => $mysql_libs,
);

###  'LIBS'		=> [''], # e.g., '-lm'
###  'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
###  # Insert -I. if you add *.h files later:
###  'INC'		=> '', # e.g., '-I/usr/include/other'
###  # Un-comment this if you add C files to link with later:
###  # 'OBJECT'		=> '$(O_FILES)', # link all the C files too

sub MY::postamble
{ <<EOT;
config::   README

README: MySQL.pm
	pod2text MySQL.pm > README
EOT
}
