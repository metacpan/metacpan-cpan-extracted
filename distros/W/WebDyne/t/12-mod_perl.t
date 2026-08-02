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
    use lib 't';
    require apache_harness_helper;
    my @missing=apache_harness_helper::apache_prereq_missing();
    if (@missing) {
        plan skip_all => 'mod_perl tests - missing ' . join(', ', @missing);
    }
    if ($> == 0) {
        plan skip_all => 'mod_perl tests - cannot run tests as root user ';
    }
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
use Cwd qw(abs_path);
use Apache::TestRequest qw(GET_BODY);
use File::Temp qw(tempdir);


#  Load WebDyne module for debug
#
use WebDyne::Util;


#  Module config
#
$Data::Dumper::Indent=1;
$Data::Dumper::Sortkeys=1;


#  Setup environment for this test.
#
$ENV{'WEBDYNE_TEST_FILE_PREFIX'} ||= '02';


#  Startup the web server and run tests
#
push @INC, dirname(__FILE__);
require apache_harness_helper;
my $runner;
diag('');
my $ok=eval {
    $runner=&apache_harness_helper::startup();
    ok(${&main(\@ARGV) || die err ()} || 0);    # || 0 stops warnings
    1;
};
my $err=$@;
diag('');
&apache_harness_helper::shutdown($runner) if $runner;
plan skip_all => 'mod_perl tests - Apache test server unavailable'
    if !$ok && apache_harness_helper::apache_startup_unavailable($err);
die $err unless $ok;


#  Testing finished
#
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


            #  Create WebDyne render of PSP file and capture to file
            #
            debug("processing $test_fn");
            my $test_cn=abs_path($test_fn) ||
                return err("unable to determine full path of $test_fn");
            (-f $test_cn) ||
                return err("unable to find file: $test_fn");
            note("processing: $test_fn");
            
            #next if $test_cn=~/substitution\.psp$/;
            next if $test_cn=~/api_bare\.psp$/;
            next if $test_cn=~/api_perl_inline\.psp$/;
            next if $test_cn=~/\/\d+-.*\.psp$/;
            next if $test_cn=~/\/error_handler_.*\.psp$/;
            next if $test_cn=~/\/error_format_.*\.psp$/;


            #  Iterate twice to make sure no change over multiple iterations
            #
            foreach my $count (1..2) {
                
                
                #  Test nunber
                #
                #my $test_no=Test::More->builder->current_test;
                #diag("test: $test_no");
            
                
                #  Now HTML
                #
                my ($data_dn, $data_fn)=(File::Spec->splitpath($test_cn))[1,2];
                $data_fn=join('-', grep {$_} $ENV{'WEBDYNE_TEST_FILE_PREFIX'},  $data_fn);
                my $data_cn=File::Spec->catfile($data_dn, $data_freeze_dn, $data_fn);
                $data_cn=~s/\.psp$/\.html/;
                #diag($test_cn);

                
                #  Get from Apache
                #
                my $html_live=GET_BODY(basename($test_cn));
                
                
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
                
                eq_or_diff_text_test($html_live, $html_thaw, "$test_fn pass on stage: HTML render");

            }

        }
    }


    #  Done
    #
    return \1
    
}

__END__
