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

while(!$d{'test_dsn'}) {
    print <<EOT;

XAO::Web will need access to a XAO::FS database in order to run tests.
That database will be COMPLETELY DESTROYED AND OVERRIDEN every time you
run 'make test'.

The database has to be created, but it does not matter what tables it
contains - they will all be dropped.

EOT

    my $yn=prompt('Would you like to run database tests?','n');

    if($yn !~ /^y/i) {
        $d{'test_dsn'}='none';
        $d{'test_user'}='';
        $d{'test_password'}='';
    }
    else {
        print <<EOT;

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

use XAO::Base qw($homedir);

WriteMakefile(
    'ABSTRACT'          => 'XAO Web Framework',
    'AUTHOR'            => 'Andrew Maltsev, https://ejelta.com/xao/',
    'NAME'              => 'XAO::Web',
    'VERSION_FROM'      => 'Web.pm',
    'MIN_PERL_VERSION'  => '5.10.1',
    'LICENSE'           => 'artistic',
    'CONFIGURE_REQUIRES'=> {
        'XAO::Base'                 => 1.23,
        'ExtUtils::MakeMaker'       => 6.64,
    },
    'TEST_REQUIRES'     => {
        'XAO::Base'                 => 1.23,
    },
    'PREREQ_PM'     => {
        'Authen::SASL::SASLprep'    => 1.1,
        'CGI'                       => 4.14,
        'CGI::Cookie'               => 4.14,
        'CGI::PSGI'                 => 0.15,
        'Crypt::Rijndael'           => 1.13,
        'Data::Entropy::Algorithms' => 0.007,
        'Digest::Bcrypt'            => 1.203,
        'Digest::MD5'               => 2.13,
        'Digest::SHA'               => 5.63,
        ### 'Email::MIME'               => 1.946,
        ### 'Email::Sender'             => 1.300031,
        'Encode'                    => 2.93,
        'Error'                     => 0.15,
        'HTML::Entities'            => 3.69,
        'HTTP::Response'            => 6.04,
        'JSON'                      => 2.26,
        'MIME::Base64'              => 3.14,
        'MIME::Lite'                => 2.117,
        'POSIX'                     => 1.16,
        'Text::FormatTable'         => 0.01,
        'Time::HiRes'               => 1.9719,
        'Unicode::Normalize'        => 1.18,
        'XAO::Base'                 => 1.23,
        'XAO::FS'                   => 1.21,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type    => 'git',
                url     => 'git://github.com/amaltsev/XAO-Web.git',
                web     => 'https://github.com/amaltsev/XAO-Web',
            },
        },
    },
);

sub MY::postamble
{ <<EOT;

all::
\t\@if [ -d .git ]; then (\\
\t\techo "https://github.com/amaltsev/XAO-Web";\\
\t\techo "-----------------------------------";\\
\t\techo "";\\
\t\tgit log -n 10 --no-color 2>/dev/null;\\
\t\techo "") > CHANGES; fi

config::	README

README:	lib/XAO/Web/Intro.pod
\tpod2text -w76 lib/XAO/Web/Intro.pod > README

install:: install_templates install_handlers

clean::
\trm -f t/*.pl t/*.xt

install_templates:
\t\@[ -d "$homedir" ] || \$(PERL) -e 'mkdir("$homedir",0755)'
\t\@\$(PERL) -Mblib \\
\t           -MXAO::PluginUtils=install_templates \\
\t           -e'install_templates("MANIFEST")'

install_handlers:
\t\@[ -d "$homedir" ] || \$(PERL) -e 'mkdir("$homedir",0755)'
\t\@\$(PERL) -MExtUtils::Install \\
\t           -e'install({"handlers" => "$homedir/handlers"})'
\t\@chmod 755 "$homedir/handlers/xao-apache.pl"
\t\@[ -f "\$(INSTALLSITEBIN)/xao-apache.pl" ] && ( \\
\t        echo "!!!"; \\
\t        echo "!!! You have \$(INSTALLSITEBIN)/xao-apache.pl"; \\
\t        echo "!!! The new location is $homedir/handlers/xao-apache.pl"; \\
\t        echo "!!! Update your references and delete the old file!"; \\
\t        echo "!!!"; \\
\t        ln -sf "$homedir/handlers/xao-apache.pl" "\$(INSTALLSITEBIN)/xao-apache.pl"; \\
\t    ) || exit 0

docker-image:
\tdocker build --build-arg "XAO_WEB_VERSION=\$(VERSION)" -t xao-web .
\t\@echo ""
\t\@docker image ls xao-web
\t\@echo ""
\t\@echo "=== Docker image built. Tag and push it with 'make docker-push'"

docker-image-master:
\tdocker build -t xao-web .
\t\@echo ""
\t\@docker image ls xao-web

docker-push:
\t\@docker tag xao-web:latest amaltsev/xao-web:\$(VERSION)
\t\@docker push amaltsev/xao-web:\$(VERSION)
\t\@docker tag xao-web:latest amaltsev/xao-web:latest
\t\@docker push amaltsev/xao-web:latest
EOT
}
