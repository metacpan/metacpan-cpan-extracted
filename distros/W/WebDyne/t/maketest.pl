#!/bin/perl
#
#  Create data files in test directory from PSP sources
#
use strict qw(vars);
use warnings;
use vars   qw($VERSION);


#  External Modules
#
use WebDyne::Request::Fake;
use WebDyne::Compile;
use WebDyne;
use File::Find qw(find);
use File::Spec;
use IO::File;
use HTML::TreeBuilder;
use Storable qw(lock_store);
use FindBin qw($RealBin $Script);
use Cwd qw(abs_path);
use Carp qw(confess);
$Storable::canonical=1;
use Data::Dumper;


#  WebDyne Modules
#
use WebDyne::Request::Fake;
use WebDyne::Compile;
use WebDyne::Err;
use WebDyne;
use WebDyne::Util;

#  Error handler
#
#*err=\&WebDyne::Err::err;
#*err=\&WebDyne::Err::errdump;

#  Default prefix
#
$ENV{'WEBDYNE_TEST_FILE_PREFIX'} ||= '02';


#  Run
#
exit(${&main(\@ARGV) || die err()} || 0);    # || 0 stops warnings

#==================================================================================================

sub main {


    #  Get list of files either from command line or from *.psp if no
    #  command line given
    #
    my @test_fn=@{shift()};
    @test_fn=map { glob $_ } @test_fn;
    my $wanted_cr=sub { push (@test_fn, $File::Find::name) if /\.psp$/ };
    find($wanted_cr, $RealBin) unless @test_fn;
    
    
    #  Dest dir
    #
    my $data_dn='data';


    #  Create a new compile instance
    #
    my $compile_or=WebDyne::Compile->new() ||
        return err();


    #  Iterate over files
    #
    foreach my $test_fn (sort {$a cmp $b } @test_fn) {


        #  Create WebDyne render of PSP file and capture to file
        #
        debug("test_fn $test_fn");
        diag("processing: $test_fn");
        my $test_cn=abs_path($test_fn);
        (-f $test_cn) ||
            return err("unable to find file: $test_fn");
        

        #  Start stepping through compile stages
        #
        foreach my $stage ((0..5), 'final') {


            #  Debug
            #
            diag("processing: $test_fn stage: $stage");
            debug("processing: $test_fn stage: $stage");
            

            #  Compile to desired stage
            #
            my $stage_name=($stage eq 'final') ? $stage : "stage${stage}";


            #  Options.
            #
            my %opt=(

                srce        	=> $test_cn,
                nofilter	=> 1,
                noperl		=> 1,
                notimestamp	=> 1,
                nomanifest	=> 1,
                $stage_name	=> 1
                
            );
            
            
            #  Compile
            #
            debug("compile opt: %s", Dumper(\%opt));
            my $data_ar=$compile_or->compile(\%opt) ||
                return err (&WebDyne::Err::errdump);
            debug("compile OK: $data_ar");
            

            #  Create dest file name
            #
            my ($dest_dn, $dest_fn)=(File::Spec->splitpath($test_cn))[1,2];
            
            
            #  Enables variations on a single source file
            #
            $dest_fn=join('-', grep {$_} $ENV{'WEBDYNE_TEST_FILE_PREFIX'},  $dest_fn);
            

            #  Create data dir if not exist
            #
            my $data_pn=File::Spec->catdir($dest_dn, $data_dn);
            ((-d $data_pn) || mkdir($data_pn)) ||
                return err("unable to create $data_pn");
                
            
            #  Now the dest files
            #
            my $dest_cn=File::Spec->catfile($dest_dn, $data_dn, $dest_fn);
            $dest_cn=~s/\.psp$/\.dat\.${stage}/;
            

            #  Save result
            #
            debug("writing output to $dest_cn");
            lock_store($data_ar, $dest_cn);

        }
        
        
        #  Now HTML. Create dest file name and eender
        #
        diag("processing: $test_fn stage: HTML render");
        my ($dest_dn, $dest_fn)=(File::Spec->splitpath($test_cn))[1,2];


        #  Enables variations on a single source file
        #
        $dest_fn=join('-', grep {$_} $ENV{'WEBDYNE_TEST_FILE_PREFIX'},  $dest_fn);
            

        my $dest_cn=File::Spec->catfile($dest_dn, $data_dn, $dest_fn);
        $dest_cn=~s/\.psp$/\.html/;
        debug("render to $dest_cn");
        &render($test_fn, $dest_cn) ||
            return err();
        
        
        #  And tree
        #
        diag("processing: $test_fn stage: treebuild");
        $dest_cn=~s/\.html$/\.tree/;
        debug("treebuild to $dest_cn");
        &treebuild($test_fn, $dest_cn) ||
            return err();

        
    }
    
    #   Done
    #
    return \undef;
    
}


sub treebuild {


    #  Convert HTML file to tree dump
    #
    my ($srce_fn, $dest_fn)=@_;


    #  Create TreeBuilder dump of rendered text in temp file
    #
    my $dest_fh=IO::File->new($dest_fn, O_WRONLY|O_CREAT|O_TRUNC) ||
      return err("unable to create dump file $dest_fn, $!");
    my $html_fh=IO::File->new($srce_fn, O_RDONLY);
    my $tree_or=HTML::TreeBuilder->new();
    while (my $html=<$html_fh>) {
	#  Do this way to get rid of extraneous CR's older version of CGI insert, spaces
	#  after tags which also differ from ver to ver, confusing test
	$html=~s/\n+$//;
	$html=~s/>\s+/>/g;
	$tree_or->parse($html);
    }
    $tree_or->eof();
    $html_fh->close();
    $tree_or->dump($dest_fh);
    $tree_or->delete();
    $dest_fh->close();
    diag('treebuild: ok');
    return \undef;


}


sub render {


    #  Where is our source and dest
    #
    my ($srce_fn, $dest_fn)=@_;


    #  Open dest file handle
    #
    my $dest_fh=IO::File->new($dest_fn, O_CREAT | O_TRUNC | O_WRONLY) ||
        return err ("unable to open file $dest_fn for output, $!");


    #  Render to dest file
    #
    my $r=WebDyne::Request::Fake->new( 
        filename	=> $srce_fn, 
        select		=> $dest_fh, 
        noheader	=> 1 
    );
    defined(WebDyne->handler($r)) ||
        return err('render error');
    $r->DESTROY();
    $dest_fh->close();


    #  Manual cleanup
    #
    $r->DESTROY();
    diag('render: ok');


    #  Done, return success
    #
    return \undef;

}


sub diag {

    print ((my $diag=sprintf(shift() || 'unknown error', @_)), $/);
    return $diag;
    
}


sub err {

    $Carp::CarpLevel=1;
    $Carp::RefArgFormatter = sub {
        require Data::Dumper;                                                                                                                                                
        $Data::Dumper::Indent=1;
        Data::Dumper->Dump(\@_); # not necessarily safe                                                                                                                    
    };
    confess &diag(@_);
    
}

