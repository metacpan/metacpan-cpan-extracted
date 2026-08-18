#!/bin/perl
# 
#  Compare generated files with frozen reference files
#
use strict qw(vars);
use warnings;
use vars   qw($VERSION);

#  Don't let local WEBDYNE_CONF be loaded
#
BEGIN {
    $ENV{'WEBDYNE_CONF'}='.' unless (($ENV{'WEBDYNE_TEST_FILE_PREFIX'} ||= '') eq '03');
    $ENV{'WEBDYNE_HEAD_INSERT'}=0 unless (($ENV{'WEBDYNE_TEST_FILE_PREFIX'} ||= '') eq '03');
}

#  Load
#
use Test::More qw(no_plan);
use FindBin qw($RealBin $Script);
use lib $RealBin;
use test_diff_helper qw(eq_or_diff_text_test);
use File::Temp qw(tempfile);
use File::Find qw(find);
use Data::Dumper;
use IO::File;
use IO::String;
use Cwd qw(abs_path);
$Data::Dumper::Indent=1;
$Data::Dumper::Sortkeys=1;
use Storable qw(lock_retrieve);
$Storable::canonical=1;


#  Load WebDyne
#
require_ok('WebDyne::Compile');
require_ok('WebDyne::Request::Fake');
use WebDyne::Util;


#  Setup environment for this test if not already present
#
$ENV{'WEBDYNE_TEST_FILE_PREFIX'} ||= '02';


#  Run
#
exit(${&main(\@ARGV) || die err ()} || 0);    # || 0 stops warnings

#==================================================================================================



sub err_carp {

    require Carp;
    $Carp::CarpLevel=0;
    $Carp::RefArgFormatter = sub {
        require Data::Dumper;                                                                                                                                                
        $Data::Dumper::Indent=1;
        Data::Dumper->Dump(\@_); # not necessarily safe                                                                                                                    
    } || $Carp::RefArgFormatter; # use || $Carp::RefArgFormatter to stop warning on older version of Carp
    &Carp::confess &diag(@_);
    
}



sub main {

    #  Get list of files either from command line or from *.psp if no
    #  command line given
    #
    my @test_fn=@{shift()};
    if (my $test_fn=$ENV{'WEBDYNE_TEST_FILE'}) {
        @test_fn=map { glob $_ } split(/[;,]/, $test_fn);
    }
    my $wanted_cr=sub { push (@test_fn, $File::Find::name) if /\.psp$/ };
    find($wanted_cr, $RealBin) unless @test_fn;
    #diag(sprintf('files: %s'), Dumper(\@test_fn));


    #  Data dir
    #
    my $data_freeze_dn='data';


    #  Iterate over files
    #
    note('');
    
    
    #  Repeat as required
    #
    for (1 .. ($ENV{'WEBDYNE_TEST_REPEAT'} || 1)) {
        FILE: foreach my $test_fn (sort {$a cmp $b } @test_fn) {
        
        
            #  Skip files with numer prefix, specific to a single tes
            #
            next if ($test_fn=~/\/\d+\-.*\.psp/);
            next if ($test_fn=~/\/error_handler_.*\.psp$/);
            next if ($test_fn=~/\/error_format_.*\.psp$/);


            #  Create WebDyne render of PSP file and capture to file
            #
            debug("processing $test_fn");
            my $test_cn=abs_path($test_fn) ||
                return err("unable to determine full path of $test_fn");
            (-f $test_cn) ||
                return err("unable to find file: $test_fn");
            note("processing: $test_fn");
            

            #  Create a new compile instance
            #
            my $compile_or=WebDyne::Compile->new( filename=> $test_fn ) ||
                return err();
                

            #  Iterate twice to make sure no change over multiple iterations
            #
            foreach my $count (1..2) {
            
            
                #  Go through all stages of compile
                #
                foreach my $stage ((0..5), 'final') {


                    #  Get data file
                    #
                    my ($data_dn, $data_fn)=(File::Spec->splitpath($test_cn))[1,2];


                    #  Enables variations on a single source file
                    #
                    $data_fn=join('-', grep {$_} $ENV{'WEBDYNE_TEST_FILE_PREFIX'},  $data_fn);
                    my $data_cn=File::Spec->catfile($data_dn, $data_freeze_dn, $data_fn);
                    $data_cn=~s/\.psp$/\.dat\.${stage}/;


                    #  Compile to desired stage
                    #
                    my $stage_name=($stage eq 'final') ? $stage : "stage${stage}";
                    #diag("count: $count, stage_name: $stage_name");


                    #  Options. Use test_fn rather than test_fp so manifest only has file name
                    #
                    my %opt=(

                        srce        	=> $test_cn,
                        no_filter	=> 1,
                        no_perl		=> 1,
                        no_timestamp	=> 1,
                        no_manifest	=> 1,
                        $stage_name     => 1
                        
                    );
                    

                    #  Get it
                    #
                    my $data_live_ar=$compile_or->compile(\%opt) ||
                        return err ();
                    debug("data_live_ar %s", Dumper($data_live_ar));
                    
                    
                    #  Get previous version
                    #
                    (-f $data_cn) || do {
                        diag("skipping $test_fn, no data file - run maketest.pl");
                        return err();
                        #next FILE;
                    };
                    my $data_thaw_ar=lock_retrieve($data_cn) ||
                        return err();


                    #  New comparison - Storable format not reliable across different perl versions
                    #
                    my $string_actual=Data::Dumper->Dump([$data_live_ar],['$VAR1']);
                    my $string_expect=Data::Dumper->Dump([$data_thaw_ar],['$VAR1']);
                    eq_or_diff_text_test($string_actual, $string_expect, "$test_fn pass on stage: $stage");

                } #foreach stage
                
                
                #  Now HTML
                #
                #diag("processing: $test_fn stage: HTML render");
                my ($data_dn, $data_fn)=(File::Spec->splitpath($test_cn))[1,2];
                $data_fn=join('-', grep {$_} $ENV{'WEBDYNE_TEST_FILE_PREFIX'},  $data_fn);

                my $data_cn=File::Spec->catfile($data_dn, $data_freeze_dn, $data_fn);
                $data_cn=~s/\.psp$/\.html/;


                my $html_live_sr=&render($test_cn) ||
                    return err();
                #diag("render: *${$html_live_sr}*");

                (-f $data_cn) || do {
                    diag("skipping $test_fn, no data file - run maketest.pl");
                    next;
                };
                my $html_thaw_fh=IO::File->new($data_cn, O_RDONLY) ||
                    return err("unable to open $data_cn, $!");
                local $/;
                my $html_thaw=<$html_thaw_fh>;
                $html_thaw_fh->close();

                eq_or_diff_text_test(${$html_live_sr}, $html_thaw, "$test_fn pass on stage: HTML render");

            }

            #ok(${$html_sr} eq $html, "$test_fn pass on stage: render");
            ##die ${$html_sr};

        }
    }


    #  Done
    #
    return \undef
    
}


sub render {


    #  Where is our source and dest
    #
    my $srce_fn=shift();


    #  Get scalar we can select to
    #
    my $html;
    my $html_fh=IO::String->new($html);


    #  Render to dest file
    #
    my $r=WebDyne::Request::Fake->new( 
        filename	=> $srce_fn, 
        select		=> $html_fh,
        noheader	=> 1 
    );
    defined(WebDyne->handler($r)) ||
        return err('render error');
    $r->DESTROY();
    $html_fh->close();


    #  Manual cleanup
    #
    #diag('render: ok');


    #  Done, return success
    #
    return \$html;

}
