# Copyright (c) 1997-2001 XAO Inc.
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

XAO::FS will need access to a MySQL database in order to run tests.
That database will be COMPLETELY DESTROYED AND OVERRIDEN every time you
run `make test'.

The database have to be created, but it does not matter what tables it
contains - they all will be dropped.

Please enter access information (brackets contain default values):

EOT
    my $dsn='OS:MySQL_DBI:test_fs';
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

##
# This rather stupid workaround is here because for some reason
# MakeMaker excludes /Config/ files from MAN3PODS
#
my %man3pods;
foreach my $n (keys %{ExtUtils::Manifest::maniread()}) {
    next unless $n =~ '^(FS).pm$' ||
                $n =~ '^lib/XAO/(.*)\.(pm|pod)$';
    next if $n =~/\/testcases\//;
    my $man=$1;
    $man=~s/\/+/::/g;
    $man='XAO::' . $man;

    open(F,$n) || die "Can't read $n: $!";
    my $pod=0;
    while(<F>) {
        if(/^=(\w+)/) {
            $pod=1;
            last;
        }
    }
    $pod || die "$n ($man) does not have documentation";

    $man3pods{$n}='$(INST_MAN3DIR)/' . $man . '.3';
}

WriteMakefile(
    'AUTHOR'        => 'Andrew Maltsev, http://ejelta.com/xao/',
    'ABSTRACT'      => 'XAO Foundation Server (OO database layer)',
    'NAME'          => 'XAO::FS',
    'VERSION_FROM'  => 'FS.pm',
    'PREREQ_PM'     => { 
        'DBD::mysql'    => '2.0414',
        'DBI'           => '1.13',
        'Error'         => '0.15',
        'Pod::Usage'    => '1.12',
        'Test::Unit'    => '0.15',
        'XAO::Base'     => '1.06',
    },
    'EXE_FILES'     => [
        'scripts/xao-fs',
    ],
    'MAN3PODS'      => \%man3pods,
);

sub MY::postamble
{ <<EOT;
all::   all-doc

all-doc:   doc/design.txt doc/x-list.txt doc/x-hash.txt \\
	doc/x-collection.txt doc/x-glue.txt \\
	doc/x-mysql-dbi.txt

doc/design.txt:    FS.pm
	\@COLUMNS=80 pod2text FS.pm > doc/design.txt

doc/x-list.txt:    lib/XAO/DO/FS/List.pm
	\@COLUMNS=80 pod2text lib/XAO/DO/FS/List.pm > doc/x-list.txt

doc/x-collection.txt:    lib/XAO/DO/FS/Collection.pm
	\@COLUMNS=80 pod2text lib/XAO/DO/FS/Collection.pm > doc/x-collection.txt

doc/x-hash.txt:    lib/XAO/DO/FS/Hash.pm
	\@COLUMNS=80 pod2text lib/XAO/DO/FS/Hash.pm > doc/x-hash.txt

doc/x-glue.txt:    lib/XAO/DO/FS/Glue.pm
	\@COLUMNS=80 pod2text lib/XAO/DO/FS/Glue.pm > doc/x-glue.txt

doc/x-mysql-dbi.txt:    lib/XAO/DO/FS/Glue/MySQL_DBI.pm
	\@COLUMNS=80 pod2text lib/XAO/DO/FS/Glue/MySQL_DBI.pm > doc/x-mysql-dbi.txt
EOT
}
