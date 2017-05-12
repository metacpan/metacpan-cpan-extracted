#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my  $PACKAGE      =  'Tie::FlipFlop';

my  $LIB_FILE     =  "lib/$PACKAGE.pm";
    $LIB_FILE     =~  s!::!/!g;
my  $LOCAL_ADDR   =  'cpan';
my  $DOMAIN       =  'abigail.be';
my  $REPO         =   $PACKAGE;
    $REPO         =~  s!::!--!g;
my  $REPO_HOST    =  'github.com';
my  $ME           =  'Abigail';
my  $REPOSITORY   =  "git://$REPO_HOST/$ME/\L$REPO.git";

my %args = (
    NAME                 => $PACKAGE,
    VERSION_FROM         => $LIB_FILE,
    ABSTRACT_FROM        => $LIB_FILE,
    PREREQ_PM            => {
        'warnings'              => 0,
        'strict'                => 0,
    },
    MIN_PERL_VERSION     =>  5.006,
    AUTHOR               => "$ME <$LOCAL_ADDR\@$DOMAIN>",
    LICENSE              => 'mit',
    META_MERGE           => {
        test_requires    => {
            'warnings'   => 0,
            'strict'     => 0,
        },
        resources        => {
            repository   => $REPOSITORY,
        },
        keywords         => [],
    },
);

my %filter = (
    MIN_PERL_VERSION     => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
    LICENSE              => '6.07',
);

delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
