#!/usr/bin/perl -w

use strict;
use Unamerican::Truth;

my @CONNECT   = (
    "dbi:mysql:database=truth",     # connect string
    "beppu",                        # user
    "",                             # passwd
    undef                           # options hash
);

my $TMPL_PATH = ".";                # path to template files

my $truth = Unamerican::Truth->new (
    TMPL_PATH => $TMPL_PATH,
    PARAMS    => { 

	# database handle
        dbh               => DBI->connect(@CONNECT),

	# number of truths to display per page
        proverbs_per_page => 14,

	# 0 for bullet points | 1 for numbers
        is_numbered       =>  1,    

    },
);

$truth->run;
