#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__);

use Test::Spec;
use OPMFileTest;
use OTRS::OPM::Parser;

my $valid_opm = dirname(__FILE__) . '/QuickMerge-3.3.2.opm';
my $invalid   = dirname(__FILE__) . '/version.t';

describe 'OPMFile' => sub {
    it 'should accept a OTRS::OPM::Parser object' => sub {
        my $p = OTRS::OPM::Parser->new( opm_file => $valid_opm );
        $p->parse;
        is $p->name, 'QuickMerge';

        my $t = OPMFileTest->new( file => $p );

        isa_ok $t, 'OPMFileTest';
        isa_ok $t->file, 'OTRS::OPM::Parser';
        is $t->file->name, 'QuickMerge';
    };

    it 'should accept a simple string' => sub {
        my $t = OPMFileTest->new( file => $valid_opm );

        isa_ok $t, 'OPMFileTest';
        isa_ok $t->file, 'OTRS::OPM::Parser';
        is $t->file->name, 'QuickMerge';
    };
};

runtests() if !caller();
