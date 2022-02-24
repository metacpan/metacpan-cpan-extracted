#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp ();    # not loaded under strict mode...

use Test::MockFile qw< strict >;    # yeap it's strict

{
    ###
    ### Without mock
    ###
    my ( $tmp_fh, $tmp ) = File::Temp::tempfile;

    like dies { open( my $fh, ">", "$tmp" ) }, qr{Use of open to access unmocked file or directory},
      "Cannot open an unmocked file in strict mode";

    my $tempdir = File::Temp::tempdir( CLEANUP => 1 );
    like dies { opendir( my $dh, "$tempdir" ) }, qr{Use of opendir to access unmocked}, "Cannot open directory from tempdir";

}

{

    ##
    ## After mock
    ##

    ok _setup_strict_rules_for_file_temp(), "_setup_strict_rules_for_file_temp";

    my ( $tmp_fh, $tmp ) = File::Temp::tempfile;

    ok lives { open( my $fh, ">", "$tmp" ) }, "we can open a tempfile";

    my $tempdir = File::Temp::tempdir( CLEANUP => 1 );
    ok lives { opendir( my $dh, "$tempdir" ) }, "Can open directory from tempdir";

}

done_testing;

sub _setup_strict_rules_for_file_temp {

    no warnings qw{redefine once};

    {
        my $sub_tempfile = File::Temp->can('tempfile');
        *File::Temp::tempfile = sub {
            my (@in) = @_;

            my @out = $sub_tempfile->(@in);

            Test::MockFile::add_strict_rule_for_filename( $out[1] => 1 );

            return @out;
        };
    }

    {
        my $sub_tempdir = File::Temp->can('tempdir');
        *File::Temp::tempdir = sub {
            my (@in) = @_;

            my $out = $sub_tempdir->(@in);
            my $dir = "$out";

            Test::MockFile::add_strict_rule_for_filename( [ $dir, qr{^${dir}/} ] => 1 );

            return $out;
        };
    }

    return 1;
}
