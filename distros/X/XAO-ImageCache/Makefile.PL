#!/usr/bin/env perl
use warnings;
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Manifest;

# Reading configuration
#
my %d;
if(open(F,'.config')) {
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
}
while(!$d{test_dsn}) {
    print <<EOT;

XAO Content will need access to a XAO::FS database in order to run tests.
That database will be COMPLETELY DESTROYED AND OVERRIDEN every time you
run 'make test'.

The database have to be created, but it does not matter what it contains.

Please enter access information (brackets contain default values), entering
'none' will disable tests:

EOT
    my $dsn=prompt('DSN:','none');

    $dsn eq 'none' || $dsn =~ /^\s*(OS:(\w+):(\w+)(;.*?)?)\s*$/ ||
        die "Incorrect DSN entered!\n";

    my $user='';
    my $pass='';
    my $confirm='n';

    if($dsn eq 'none') {
        $confirm='y';
        print <<EOT;

Ok, tests will be skipped per your request.

EOT
    }
    else {
        chomp(my $default_user=`whoami`);
        $user=prompt('User name:',$default_user);
        $pass=prompt('Password:','');

        print <<EOT;

Here is what will be used to connect to the test database
(and DESTROY it):
   DSN:      $dsn
   User:     $user
   Password: $pass

EOT

        $confirm=prompt('Does it make sense ?','y');
    }

    if(!$confirm || lc($confirm)=~/y/) {
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

# This rather stupid workaround is here because for some reason
# MakeMaker excludes /Config/ files from MAN3PODS
#
my %man3pods;
foreach my $n (keys %{ExtUtils::Manifest::maniread()}) {
    next unless $n =~ '^doc/(.*)\.(pm|pod)$' ||
		$n =~ '^(ImageCache).pm$';
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
    'AUTHOR'        => 'Konstantin Safronov',
    'ABSTRACT'      => 'Images caching module for XAO::Commerce',
    'NAME'          => 'XAO::ImageCache',
    'VERSION_FROM'	=> 'ImageCache.pm',
    'PREREQ_PM'     => {
        'Date::Manip'   => '6.22',
	    'XAO::FS'	    => '1.01',
        'Test::Unit'    => '0.14',
	    'Image::Magick' => '6.3.0',
	    'LWP'		    => '5.63',
    },
    'MAN3PODS'      => \%man3pods,
);

sub MY::postamble {

    <<EOT;
config::	README

README:	ImageCache.pm
	\@COLUMNS=80 pod2text ImageCache.pm > README
EOT
}
