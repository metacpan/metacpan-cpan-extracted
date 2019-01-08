#!/usr/bin/env perl
use warnings;
use strict;
use ExtUtils::MakeMaker 6.64;
use ExtUtils::Manifest;

my %d;
if(open(F,'.config')) {
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
}

if(!$d{'test_dsn'}) {
    print <<EOT;

XAO::FS will need access to a MySQL database in order to run tests.
That database will be COMPLETELY DESTROYED AND OVERRIDEN every time you
run `make test'.

The database has to be created, but it does not matter what tables it
contains - they all will be dropped.

EOT

    my $yn=prompt('Would you like to run database tests?','n');

    if($yn !~ /^y/i) {
        $d{'test_dsn'}='none';
        $d{'test_user'}='';
        $d{'test_password'}='';
    }
    else {
        print <<EOT;

Both DBD::MariaDB and DBD::mysql are supported by MySQL_DBI driver. The
default is DBD::mysql. To use DBD::MariaDB add dbi_driver=mariadb option
to DSN (e.g. OS:MySQL_DBI:test_fs;dbi_driver=MariaDB;table_type=InnoDB).

The DBI driver needs to be installed separately, it is not pulled in by
XAO::FS.

Enter database connection parameters.

EOT

        my $dsn=prompt('DSN','OS:MySQL_DBI:test_fs;table_type=innodb');

        $dsn=~ /^\s*(OS:(\w+):(\w+)(;.*?)?)\s*$/ ||
            die "Incorrect DSN entered!\n";

        $dsn=$1;

        chomp(my $default_user=`whoami`);
        my $user=prompt('User name',$default_user);
        my $pass=prompt('Password','');

        print <<EOT;

Here is what will be used to connect to TEST database.

   DSN:      $dsn
   User:     $user
   Password: $pass

The database WILL BE COMPLETELY ERASED!

EOT

        $yn=prompt('Does it make sense ?','y');

        die "Ok, please re-configure.\n" unless $yn=~/^y/i;

        $d{'test_dsn'}=$dsn;
        $d{'test_user'}=$user;
        $d{'test_password'}=$pass;
    }

    open(F,">.config") || die "Can't open .config: $!\n";
    print F <<EOT;
## Feel free to remove or edit that file. It will be re-created on `perl
## Makefile.PL' if removed.
\$d{'test_dsn'}='$d{'test_dsn'}';
\$d{'test_user'}='$d{'test_user'}';
\$d{'test_password'}='$d{'test_password'}';
EOT
}

WriteMakefile(
    'AUTHOR'            => 'Andrew Maltsev, https://ejelta.com/xao/',
    'ABSTRACT'          => 'XAO Database Layer',
    'NAME'              => 'XAO::FS',
    'VERSION_FROM'      => 'FS.pm',
    'MIN_PERL_VERSION'  => '5.10.1',
    'PREREQ_PM'         => {
        'DBI'                   => '1.13',
        'Error'                 => '0.15',
        'XAO::Base'             => '1.20',
    },
    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker'   => '6.64',
    },
    'BUILD_REQUIRES' => {
        'Pod::Usage'            => '1.12',
    },
    'TEST_REQUIRES' => {
        'XAO::Base'             => '1.20',
    },
    'EXE_FILES'     => [
        'scripts/xao-fs',
    ],
);

sub MY::postamble
{ <<EOT;
all::   all-doc
\t\@if [ -d .git ]; then (\\
\t\techo "https://github.com/amaltsev/XAO-FS";\\
\t\techo "----------------------------------";\\
\t\techo "";\\
\t\tgit log -n 10 --no-color 2>/dev/null;\\
\t\techo "") > CHANGES; fi

clean::
\trm -f t/*.pl t/*.xt

all-doc:   doc/design.txt doc/x-list.txt doc/x-hash.txt \\
\tdoc/x-collection.txt doc/x-glue.txt \\
\tdoc/x-mysql-dbi.txt

doc/design.txt:    FS.pm
\t\@COLUMNS=80 pod2text FS.pm > doc/design.txt

doc/x-list.txt:    lib/XAO/DO/FS/List.pm
\t\@COLUMNS=80 pod2text lib/XAO/DO/FS/List.pm > doc/x-list.txt

doc/x-collection.txt:    lib/XAO/DO/FS/Collection.pm
\t\@COLUMNS=80 pod2text lib/XAO/DO/FS/Collection.pm > doc/x-collection.txt

doc/x-hash.txt:    lib/XAO/DO/FS/Hash.pm
\t\@COLUMNS=80 pod2text lib/XAO/DO/FS/Hash.pm > doc/x-hash.txt

doc/x-glue.txt:    lib/XAO/DO/FS/Glue.pm
\t\@COLUMNS=80 pod2text lib/XAO/DO/FS/Glue.pm > doc/x-glue.txt

doc/x-mysql-dbi.txt:    lib/XAO/DO/FS/Glue/MySQL_DBI.pm
\t\@COLUMNS=80 pod2text lib/XAO/DO/FS/Glue/MySQL_DBI.pm > doc/x-mysql-dbi.txt
EOT
}
