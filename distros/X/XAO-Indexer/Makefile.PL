#!/usr/bin/env perl
use warnings;
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Manifest;

eval 'use Compress::LZO';
if($@) {
    warn "** Missing Compress::LZO, won't be able to compress data\n";
}

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
    'ABSTRACT'      => 'Full text search indexer for XAO::FS',
    'NAME'          => 'XAO::Indexer',
    'VERSION_FROM'	=> 'Indexer.pm',
    'PREREQ_PM'     => {
        'Error'         => '0.14',
        'Pod::Usage'    => '1.12',
        'Test::Unit'    => '0.14',
        'XAO::Base'     => '1.04',
        'XAO::FS'       => '1.05',
    },
    'EXE_FILES'     => [
        'scripts/xao-indexer',
    ],
    'MAN3PODS'      => \%man3pods,
    'META_MERGE'    => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type    => 'git',
                url     => 'git://github.com/amaltsev/XAO-Indexer.git',
                web     => 'https://github.com/amaltsev/XAO-Indexer',
            },
        },
    },

);

sub MY::postamble
{ <<EOT;
config::    README

README:     Indexer.pm
	\@COLUMNS=80 pod2text Indexer.pm > README
EOT
}
