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
}

#  Load
#
use Test::More qw(no_plan);
use File::Temp qw(tempfile);
use Cwd qw(abs_path);
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Sortkeys=1;


#  Load WebDyne
#
use WebDyne qw(html);
use WebDyne::Util;


#  Setup environment for this test if not already present
#
$ENV{'WEBDYNE_TEST_FILE_PREFIX'} ||= '09';


#  Test files
#
my @test_fn=qw(
    t/cache_start_html_attr.psp 
    t/cache_start_html_meta.psp 
    t/cache_start_html_module.psp
    t/cache_meta.psp
);


#  Run
#
exit(${&main(@ARGV ? \@ARGV : \@test_fn) || die err ()} || 0);    # || 0 stops warnings

#==================================================================================================


sub main {


    #  HTML output should be the same (i.e. 1) no matter what count param is as 
    #  page is rendered static
    #
    foreach my $test_fn (@{shift()}) {
        #diag("test_fn: $test_fn");
        my @html;
        foreach my $count (1..10) {
            my $test_cn=abs_path($test_fn) ||
                return err("unable to determine full path of $test_fn");
            (-f $test_cn) ||
                return err("unable to find file: $test_fn");
            my $html=html($test_fn, param => { count=>$count });
            #diag $html;
            push @html,$html;
        }
        if (@html != grep { $_ eq $html[0] } @html) {
            ok('outputs not identical'); 
        }
        for (my $i=0; $i<10; $i++) {
            if ($html[$i] eq $html[++$i]) {
                ok('cache code pairs')
            }
            else {
                diag('html renders not identical:', Dumper([$html[$i-1], $html[$i]]));
                fail('cache code pairs');
            }
        }
    }
    return \0;

}
