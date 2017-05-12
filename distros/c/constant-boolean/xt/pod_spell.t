#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Cwd;

BEGIN {
    chdir dirname(__FILE__) or die "$!";
    chdir '..' or die "$!";
};

use Test::More;
use Test::Spelling;

open my $fh, File::Spec->catfile(dirname(__FILE__), 'pod_spellrc') or die $!;
add_stopwords( <$fh> );
$ENV{LANG} = 'C';

all_pod_files_spelling_ok('lib');
