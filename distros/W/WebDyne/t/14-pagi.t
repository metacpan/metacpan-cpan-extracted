#  Pragma
#
use strict;
use warnings;


#  Test Harness
#
use Test::More;


#  Skip test if missing any modules or no mod_perl
#
BEGIN {
    my @missing;
    for my $m (qw(PAGI::Test::Client PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait)) {
        eval "require $m; 1" or push @missing, $m;
    }
    if (@missing) {
        plan skip_all => "Skipping PAGI tests: missing " . join(", ", @missing);
    }
    #plan skip_all => "AUTHOR_TEST not set, omitting PAGI test" unless $ENV{'AUTHOR_TEST'};
    
}


#  Skip any local config
#
BEGIN { 
    $ENV{'WEBDYNE_CONF'}='.'; 
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
    $ENV{'WEBDYNE_HEAD_INSERT'}=0;
}


#  Modules we need
#
use FindBin qw($RealBin $Script);
use lib $RealBin;
use test_diff_helper qw(eq_or_diff_text_test);
use File::Find qw(find);
use File::Basename;
use Data::Dumper;
use IO::File;
use Cwd qw(abs_path fastcwd);
use HTTP::Request::Common qw(GET);


#  Load WebDyne modules we need
#
use WebDyne::PAGI;
use WebDyne::Util;


#  Module config
#
$Data::Dumper::Indent=1;
$Data::Dumper::Sortkeys=1;


#  Setup environment for this test.
#
$ENV{'WEBDYNE_TEST_FILE_PREFIX'} ||= '02';


#  Run tests
#
ok(${&main(\@ARGV) || die err ()} || 0);    # || 0 stops warnings
done_testing();


#======================================================================================================================


#  Main comparison routine
#
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


    #  Data dir
    #
    my $data_freeze_dn='data';
    
    
    #  Get app code
    #
    note(fastcwd());
    ok(my $app_cr=WebDyne::PAGI->new(root=>File::Spec->catdir(fastcwd(), 't'))->to_app());
    ok(my $test_or=PAGI::Test::Client->new(app => $app_cr, raise_app_exceptions => 1));

    
    #  Repeat as required
    #
    for (1 .. ($ENV{'WEBDYNE_TEST_REPEAT'} || 1)) {
        FILE: foreach my $test_fn (sort {$a cmp $b } @test_fn) {


            #  Create WebDyne render of PSP file and capture to file
            #
            debug("processing $test_fn");
            my $test_cn=abs_path($test_fn) ||
                return err("unable to determine full path of $test_fn");
            (-f $test_cn) ||
                return err("unable to find file: $test_fn");
            note("processing: $test_fn");
            

            #  Skip api tests and a few others
            #
            next if $test_fn=~/htmx_compact/;
            next if $test_cn=~/api_bare\.psp$/;
            next if $test_cn=~/api_perl_inline\.psp$/;
            next if $test_cn=~/\/\d+-.*\.psp$/;
            next if $test_cn=~/\/error_handler_.*\.psp$/;
            next if $test_cn=~/\/error_format_.*\.psp$/;
            

            #  Iterate twice to make sure no change over multiple iterations
            #
            foreach my $count (1..2) {
            
                
                #  Now HTML
                #
                my ($data_dn, $data_fn)=(File::Spec->splitpath($test_cn))[1,2];
                $data_fn=join('-', grep {$_} $ENV{'WEBDYNE_TEST_FILE_PREFIX'},  $data_fn);
                my $data_cn=File::Spec->catfile($data_dn, $data_freeze_dn, $data_fn);
                $data_cn=~s/\.psp$/\.html/;

                
                #  Get results
                #
                my $request_path=basename($test_cn) || $test_cn;
                my $res=eval { $test_or->get($request_path) };
                my $err=$@;
                ok($res, "PAGI renders $request_path without throwing");
                if ($err) {
                    diag("PAGI exception while rendering $test_cn: $err");
                    next;
                }
                my $html_live=$res->content();
                #diag("live: $html_live");
                

                #  Check match
                #
                (-f $data_cn) || do {
                    diag("skipping $test_fn, no data file - run maketest.pl");
                    next;
                };
                my $html_thaw_fh=IO::File->new($data_cn, O_RDONLY) ||
                    return err("unable to open $data_cn, $!");
                local $/;
                my $html_thaw=<$html_thaw_fh>;
                $html_thaw_fh->close();
                #diag("thaw: $html_thaw");
                
                eq_or_diff_text_test($html_live, $html_thaw, "$test_fn pass on stage: HTML render");

            }

        }
    }


    #  Done
    #
    return \1;
    
}
